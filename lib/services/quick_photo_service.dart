import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/services/storage_service.dart';
import 'package:fittravel/models/quick_photo.dart';

/// Manages quick-added photos captured from the camera before assignment
class QuickPhotoService extends ChangeNotifier {
  final StorageService _storage;
  List<QuickPhoto> _photos = [];
  bool _isLoading = false;

  QuickPhotoService(this._storage);

  bool get isLoading => _isLoading;
  List<QuickPhoto> get photos => _photos;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final jsonList = _storage.getJsonList(StorageKeys.quickPhotos);
      if (jsonList != null) {
        _photos = jsonList.map((j) => QuickPhoto.fromJson(j)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _photos = [];
      }
    } catch (e) {
      debugPrint('QuickPhotoService.initialize error: $e');
      _photos = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    try {
      final jsonList = _photos.map((p) => p.toJson()).toList();
      await _storage.setJsonList(StorageKeys.quickPhotos, jsonList);
    } catch (e) {
      debugPrint('QuickPhotoService._saveAll error: $e');
    }
  }

  Future<QuickPhoto> addPhotoDataUrl({
    required String dataUrl,
    String? userId,
  }) async {
    final photo = QuickPhoto(
      id: const Uuid().v4(),
      imageUrl: dataUrl,
      userId: userId,
    );
    _photos.insert(0, photo);
    await _saveAll();
    notifyListeners();
    return photo;
  }

  Future<void> assignToPlace({
    required String photoId,
    required String placeId,
  }) async {
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return;
    _photos[index] = _photos[index].copyWith(placeId: placeId);
    await _saveAll();
    notifyListeners();
  }

  Future<void> delete(String photoId) async {
    _photos.removeWhere((p) => p.id == photoId);
    await _saveAll();
    notifyListeners();
  }
}
