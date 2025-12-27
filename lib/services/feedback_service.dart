import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/services/storage_service.dart';

class FeedbackItem {
  final String id;
  final String? userId;
  final String category; // bug | idea | other
  final String message;
  final String? contact;
  final DateTime createdAt;
  final bool syncedToSupabase;

  FeedbackItem({
    required this.id,
    this.userId,
    required this.category,
    required this.message,
    this.contact,
    DateTime? createdAt,
    this.syncedToSupabase = false,
  }) : createdAt = createdAt ?? DateTime.now();

  FeedbackItem copyWith({bool? syncedToSupabase}) => FeedbackItem(
        id: id,
        userId: userId,
        category: category,
        message: message,
        contact: contact,
        createdAt: createdAt,
        syncedToSupabase: syncedToSupabase ?? this.syncedToSupabase,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'message': message,
        'contact': contact,
        'createdAt': createdAt.toIso8601String(),
        'syncedToSupabase': syncedToSupabase,
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        category: json['category'] as String? ?? 'other',
        message: json['message'] as String? ?? '',
        contact: json['contact'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncedToSupabase: json['syncedToSupabase'] as bool? ?? false,
      );

  /// Create from Supabase JSON (snake_case keys)
  factory FeedbackItem.fromSupabaseJson(Map<String, dynamic> json) =>
      FeedbackItem(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        category: json['category'] as String? ?? 'other',
        message: json['message'] as String? ?? '',
        contact: json['contact'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        syncedToSupabase: true, // If it came from Supabase, it's synced
      );

  /// Convert to Supabase JSON (snake_case keys)
  Map<String, dynamic> toSupabaseJson(String userId) => {
        'user_id': userId,
        'category': category,
        'message': message,
        'contact': contact,
      };
}

/// FeedbackService submits feedback to Supabase with local persistence backup.
/// Items are always stored locally first, then synced to Supabase.
class FeedbackService extends ChangeNotifier {
  List<FeedbackItem> _items = [];
  bool _isLoading = false;
  String? _error;
  StorageService? _storage;

  FeedbackService();

  bool get isLoading => _isLoading;
  List<FeedbackItem> get items => List.unmodifiable(_items);
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  /// Get count of items not yet synced to Supabase
  int get unsyncedCount => _items.where((i) => !i.syncedToSupabase).length;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize local storage
      _storage = await StorageService.getInstance();

      // Load from local storage first (this is our backup)
      final localItems = _loadFromLocal();

      final userId = _currentUserId;
      if (userId != null) {
        // Try to load user's feedback from Supabase
        try {
          final feedbackData = await SupabaseConfig.client
              .from('feedback')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);

          final supabaseItems = (feedbackData as List)
              .map((json) => FeedbackItem.fromSupabaseJson(json))
              .toList();

          // Merge: Supabase items + local unsynced items
          final supabaseIds = supabaseItems.map((i) => i.id).toSet();
          final unsyncedLocal = localItems.where((i) => !supabaseIds.contains(i.id)).toList();

          _items = [...supabaseItems, ...unsyncedLocal];

          // Try to sync any unsynced local items to Supabase
          await _syncUnsyncedItems(userId);
        } catch (e) {
          debugPrint('FeedbackService: Could not load from Supabase: $e');
          // Fall back to local items only
          _items = localItems;
        }
      } else {
        // Not authenticated - use local items
        _items = localItems;
      }

      // Sort by date descending
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save merged state to local storage
      await _saveToLocal();
    } catch (e) {
      debugPrint('FeedbackService.initialize error: $e');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submit feedback - saves locally first, then tries Supabase
  /// Throws an exception if Supabase sync fails (so UI can show error)
  Future<FeedbackItem> submit({
    required String category,
    required String message,
    String? contact,
  }) async {
    final userId = _currentUserId;
    var item = FeedbackItem(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      message: message.trim(),
      contact: (contact?.trim().isEmpty ?? true) ? null : contact!.trim(),
      syncedToSupabase: false,
    );

    // Add to local list and persist immediately
    _items.insert(0, item);
    await _saveToLocal();
    notifyListeners();

    // Try to save to Supabase if authenticated
    if (userId != null) {
      try {
        await SupabaseService.insert('feedback', item.toSupabaseJson(userId));
        // Mark as synced
        item = item.copyWith(syncedToSupabase: true);
        _items[0] = item;
        await _saveToLocal();
        _error = null;
        notifyListeners();
        debugPrint('FeedbackService: Successfully saved feedback to Supabase');
      } catch (e) {
        // Set error but don't throw - feedback is saved locally
        _error = 'Feedback saved locally but failed to sync: $e';
        debugPrint('FeedbackService: Could not save to Supabase: $e');
        // Re-throw so UI can show a warning (but feedback is safe locally)
        rethrow;
      }
    } else {
      _error = 'Not authenticated - feedback saved locally only';
      debugPrint('FeedbackService: User not authenticated, saved locally only');
    }

    return item;
  }

  /// Try to sync any unsynced items to Supabase
  Future<void> _syncUnsyncedItems(String userId) async {
    final unsynced = _items.where((i) => !i.syncedToSupabase).toList();
    if (unsynced.isEmpty) return;

    debugPrint('FeedbackService: Attempting to sync ${unsynced.length} unsynced items');

    for (var item in unsynced) {
      try {
        await SupabaseService.insert('feedback', item.toSupabaseJson(userId));
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(syncedToSupabase: true);
        }
        debugPrint('FeedbackService: Synced item ${item.id}');
      } catch (e) {
        debugPrint('FeedbackService: Failed to sync item ${item.id}: $e');
        // Continue trying other items
      }
    }

    await _saveToLocal();
    notifyListeners();
  }

  /// Manually retry syncing unsynced items
  Future<int> retrySyncUnsynced() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final unsyncedBefore = unsyncedCount;
    await _syncUnsyncedItems(userId);
    return unsyncedBefore - unsyncedCount;
  }

  /// Load feedback items from local storage
  List<FeedbackItem> _loadFromLocal() {
    try {
      final jsonList = _storage?.getJsonList(StorageKeys.feedbackItems);
      if (jsonList == null || jsonList.isEmpty) return [];
      return jsonList.map((json) => FeedbackItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('FeedbackService: Error loading from local storage: $e');
      return [];
    }
  }

  /// Save feedback items to local storage
  Future<void> _saveToLocal() async {
    try {
      final jsonList = _items.map((i) => i.toJson()).toList();
      await _storage?.setJsonList(StorageKeys.feedbackItems, jsonList);
    } catch (e) {
      debugPrint('FeedbackService: Error saving to local storage: $e');
    }
  }

  /// Clear local state (called on logout)
  void clearFeedback() {
    _items = [];
    _error = null;
    _storage?.remove(StorageKeys.feedbackItems);
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
