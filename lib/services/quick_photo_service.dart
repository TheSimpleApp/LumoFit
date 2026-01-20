import 'package:flutter/foundation.dart';
import 'package:fittravel/models/quick_photo.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/services/photo_storage_service.dart';

/// Manages quick-added photos captured from the camera before assignment via Supabase Storage.
class QuickPhotoService extends ChangeNotifier {
  List<QuickPhoto> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  QuickPhotoService();

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<QuickPhoto> get photos => _photos;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        _photos = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load user's quick photos from Supabase
      final photosData = await SupabaseConfig.client
          .from('quick_photos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _photos = (photosData as List)
          .map((json) => QuickPhoto.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load quick photos';
      debugPrint('QuickPhotoService.initialize error: $e');
      _photos = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a photo from image bytes (recommended - uses Supabase Storage)
  Future<QuickPhoto> addPhoto({
    required Uint8List imageBytes,
    String? photoId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      // Upload to Supabase Storage with compression
      final storagePath = await PhotoStorageService.uploadQuickPhoto(
        imageBytes: imageBytes,
        photoId: photoId,
      );

      // Get public URL
      final imageUrl = PhotoStorageService.getQuickPhotoUrl(storagePath);

      // Save metadata to database
      final data = {
        'user_id': userId,
        'image_url': imageUrl,
        'place_id': null,
      };

      final result = await SupabaseService.insert('quick_photos', data);

      if (result.isNotEmpty) {
        final photo = QuickPhoto.fromSupabaseJson(result.first);
        _photos.insert(0, photo);
        _error = null;
        _isUploading = false;
        notifyListeners();
        return photo;
      }
      throw Exception('Failed to save quick photo metadata');
    } catch (e) {
      _error = 'Failed to upload quick photo: ${e.toString()}';
      debugPrint('QuickPhotoService.addPhoto error: $e');
      _isUploading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Legacy method: Add a photo from data URL (for backwards compatibility)
  @Deprecated('Use addPhoto() with image bytes instead')
  Future<QuickPhoto> addPhotoDataUrl({
    required String dataUrl,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'user_id': userId,
        'image_url': dataUrl,
        'place_id': null,
      };

      final result = await SupabaseService.insert('quick_photos', data);

      if (result.isNotEmpty) {
        final photo = QuickPhoto.fromSupabaseJson(result.first);
        _photos.insert(0, photo);
        _error = null;
        notifyListeners();
        return photo;
      }
      throw Exception('Failed to add quick photo');
    } catch (e) {
      _error = 'Failed to add quick photo';
      debugPrint('QuickPhotoService.addPhotoDataUrl error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignToPlace({
    required String photoId,
    required String placeId,
  }) async {
    try {
      await SupabaseConfig.client
          .from('quick_photos')
          .update({'place_id': placeId}).eq('id', photoId);

      final index = _photos.indexWhere((p) => p.id == photoId);
      if (index >= 0) {
        _photos[index] = _photos[index].copyWith(placeId: placeId);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to assign photo to place';
      debugPrint('QuickPhotoService.assignToPlace error: $e');
      notifyListeners();
    }
  }

  Future<void> delete(String photoId) async {
    try {
      await SupabaseService.delete('quick_photos', filters: {'id': photoId});

      _photos.removeWhere((p) => p.id == photoId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete quick photo';
      debugPrint('QuickPhotoService.delete error: $e');
      notifyListeners();
    }
  }

  /// Clear local state (called on logout)
  void clearPhotos() {
    _photos = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
