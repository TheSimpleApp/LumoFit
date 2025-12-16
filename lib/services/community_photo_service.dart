import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

/// Manages community photos for places. Currently uses local storage.
/// Later, this can be swapped to Supabase storage + table with minimal changes.
class CommunityPhotoService extends ChangeNotifier {
  final StorageService _storage;
  List<CommunityPhoto> _photos = [];
  bool _isLoading = false;

  CommunityPhotoService(this._storage);

  bool get isLoading => _isLoading;
  List<CommunityPhoto> get photos => _photos;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final jsonList = _storage.getJsonList(StorageKeys.communityPhotos);
      if (jsonList != null) {
        _photos = jsonList.map((j) => CommunityPhoto.fromJson(j)).toList();
      } else {
        _photos = [];
      }
    } catch (e) {
      debugPrint('CommunityPhotoService.initialize error: $e');
      _photos = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final jsonList = _photos.map((p) => p.toJson()).toList();
    await _storage.setJsonList(StorageKeys.communityPhotos, jsonList);
  }

  List<CommunityPhoto> getPhotosForPlace(String placeId) {
    return _photos
        .where((p) => p.placeId == placeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<CommunityPhoto> addPhotoUrl({
    required String placeId,
    required String imageUrl,
    String? userId,
  }) async {
    final photo = CommunityPhoto(
      id: const Uuid().v4(),
      placeId: placeId,
      imageUrl: imageUrl,
      userId: userId,
    );
    _photos.insert(0, photo);
    await _saveAll();
    notifyListeners();
    return photo;
  }

  Future<void> deletePhoto(String photoId) async {
    _photos.removeWhere((p) => p.id == photoId);
    await _saveAll();
    notifyListeners();
  }
}
