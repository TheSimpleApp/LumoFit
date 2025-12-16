import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/review_model.dart';
import 'package:fittravel/services/storage_service.dart';

/// Manages community reviews. Local-first via SharedPreferences.
/// Later: replace persistence with Supabase tables.
class ReviewService extends ChangeNotifier {
  final StorageService _storage;
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;

  ReviewService(this._storage);

  bool get isLoading => _isLoading;
  List<ReviewModel> get reviews => _reviews;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final jsonList = _storage.getJsonList(StorageKeys.reviews);
      _reviews = jsonList?.map((j) => ReviewModel.fromJson(j)).toList() ?? [];
    } catch (e) {
      debugPrint('ReviewService.initialize error: $e');
      _reviews = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final jsonList = _reviews.map((r) => r.toJson()).toList();
    await _storage.setJsonList(StorageKeys.reviews, jsonList);
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
    String? userId,
  }) async {
    final review = ReviewModel(
      id: const Uuid().v4(),
      placeId: placeId,
      rating: rating.clamp(1, 5),
      text: text,
      userId: userId,
    );
    _reviews.insert(0, review);
    await _saveAll();
    notifyListeners();
    return review;
  }

  Future<void> deleteReview(String reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
    await _saveAll();
    notifyListeners();
  }
}
