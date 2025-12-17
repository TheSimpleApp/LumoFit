import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/services/storage_service.dart';

class FeedbackItem {
  final String id;
  final String category; // bug | idea | other
  final String message;
  final String? contact;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.category,
    required this.message,
    this.contact,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'message': message,
        'contact': contact,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        id: json['id'] as String,
        category: json['category'] as String? ?? 'other',
        message: json['message'] as String? ?? '',
        contact: json['contact'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class FeedbackService extends ChangeNotifier {
  final StorageService _storage;
  List<FeedbackItem> _items = [];
  bool _isLoading = false;

  FeedbackService(this._storage);

  bool get isLoading => _isLoading;
  List<FeedbackItem> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final jsonList = _storage.getJsonList('feedback_items');
      _items = jsonList?.map((j) => FeedbackItem.fromJson(j)).toList() ?? [];
    } catch (e) {
      debugPrint('FeedbackService.initialize error: $e');
      _items = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    await _storage.setJsonList('feedback_items', _items.map((e) => e.toJson()).toList());
  }

  Future<FeedbackItem> submit({
    required String category,
    required String message,
    String? contact,
  }) async {
    final item = FeedbackItem(
      id: const Uuid().v4(),
      category: category,
      message: message.trim(),
      contact: (contact?.trim().isEmpty ?? true) ? null : contact!.trim(),
    );
    _items.insert(0, item);
    await _saveAll();
    notifyListeners();
    return item;
  }
}
