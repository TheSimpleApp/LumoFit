import 'package:flutter/foundation.dart';
import 'package:fittravel/models/review_model.dart';
import 'package:fittravel/supabase/supabase_config.dart';

/// Manages community reviews via Supabase.
class ReviewService extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewService();

  bool get isLoading => _isLoading;
  List<ReviewModel> get reviews => _reviews;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all reviews (public read access)
      final reviewsData = await SupabaseConfig.client
          .from('reviews')
          .select()
          .order('created_at', ascending: false);

      _reviews = (reviewsData as List)
          .map((json) => ReviewModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load reviews';
      debugPrint('ReviewService.initialize error: $e');
      _reviews = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<ReviewModel> getReviewsForPlace(String placeId) {
    return _reviews
        .where((r) => r.placeId == placeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double? getAverageRating(String placeId) {
    final list = _reviews.where((r) => r.placeId == placeId).toList();
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / list.length;
  }

  int getReviewCount(String placeId) =>
      _reviews.where((r) => r.placeId == placeId).length;

  Future<ReviewModel> addReview({
    required String placeId,
    required int rating,
    String? text,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'place_id': placeId,
        'user_id': userId,
        'rating': rating.clamp(1, 5),
        'text': text,
      };

      final result = await SupabaseService.insert('reviews', data);

      if (result.isNotEmpty) {
        final review = ReviewModel.fromSupabaseJson(result.first);
        _reviews.insert(0, review);
        _error = null;
        notifyListeners();
        return review;
      }
      throw Exception('Failed to add review');
    } catch (e) {
      _error = 'Failed to add review';
      debugPrint('ReviewService.addReview error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await SupabaseService.delete('reviews', filters: {'id': reviewId});

      _reviews.removeWhere((r) => r.id == reviewId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete review';
      debugPrint('ReviewService.deleteReview error: $e');
      notifyListeners();
    }
  }

  /// Clear local state (called on logout)
  void clearReviews() {
    _reviews = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
