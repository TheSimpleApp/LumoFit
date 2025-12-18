import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/supabase/supabase_config.dart';

class FeedbackItem {
  final String id;
  final String? userId;
  final String category; // bug | idea | other
  final String message;
  final String? contact;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    this.userId,
    required this.category,
    required this.message,
    this.contact,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'message': message,
        'contact': contact,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        category: json['category'] as String? ?? 'other',
        message: json['message'] as String? ?? '',
        contact: json['contact'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
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
      );

  /// Convert to Supabase JSON (snake_case keys)
  Map<String, dynamic> toSupabaseJson(String userId) => {
        'user_id': userId,
        'category': category,
        'message': message,
        'contact': contact,
      };
}

/// FeedbackService submits feedback to Supabase.
/// Items are stored in memory and optionally synced to Supabase.
class FeedbackService extends ChangeNotifier {
  List<FeedbackItem> _items = [];
  bool _isLoading = false;
  String? _error;

  FeedbackService();

  bool get isLoading => _isLoading;
  List<FeedbackItem> get items => List.unmodifiable(_items);
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId != null) {
        // Try to load user's feedback from Supabase (if table exists)
        try {
          final feedbackData = await SupabaseConfig.client
              .from('feedback')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);

          _items = (feedbackData as List)
              .map((json) => FeedbackItem.fromSupabaseJson(json))
              .toList();
        } catch (e) {
          // Table might not exist yet - that's okay, just start with empty list
          debugPrint('FeedbackService: Could not load from Supabase (table may not exist): $e');
          _items = [];
        }
      } else {
        _items = [];
      }
    } catch (e) {
      debugPrint('FeedbackService.initialize error: $e');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<FeedbackItem> submit({
    required String category,
    required String message,
    String? contact,
  }) async {
    final userId = _currentUserId;
    final item = FeedbackItem(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      message: message.trim(),
      contact: (contact?.trim().isEmpty ?? true) ? null : contact!.trim(),
    );

    // Add to local list immediately
    _items.insert(0, item);
    notifyListeners();

    // Try to save to Supabase if authenticated
    if (userId != null) {
      try {
        await SupabaseService.insert('feedback', item.toSupabaseJson(userId));
        _error = null;
      } catch (e) {
        // Don't fail if Supabase save fails - feedback is already in local list
        debugPrint('FeedbackService: Could not save to Supabase: $e');
      }
    }

    return item;
  }

  /// Clear local state (called on logout)
  void clearFeedback() {
    _items = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
