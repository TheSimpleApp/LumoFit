import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/services/photo_storage_service.dart';

/// Manages community photos for places via Supabase Storage.
class CommunityPhotoService extends ChangeNotifier {
  List<CommunityPhoto> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  CommunityPhotoService();

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  List<CommunityPhoto> get photos => _photos;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all community photos (public read access)
      final photosData = await SupabaseConfig.client
          .from('community_photos')
          .select()
          .order('created_at', ascending: false);

      _photos = (photosData as List)
          .map((json) => CommunityPhoto.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load community photos';
      debugPrint('CommunityPhotoService.initialize error: $e');
      _photos = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<CommunityPhoto> getPhotosForPlace(String placeId) {
    return _photos
        .where((p) => p.placeId == placeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Add a photo from image bytes (recommended - uses Supabase Storage)
  Future<CommunityPhoto> addPhoto({
    required String placeId,
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
      final storagePath = await PhotoStorageService.uploadCommunityPhoto(
        imageBytes: imageBytes,
        placeId: placeId,
        photoId: photoId,
      );

      // Get public URL
      final imageUrl = PhotoStorageService.getCommunityPhotoUrl(storagePath);

      // Save metadata to database
      final data = {
        'place_id': placeId,
        'user_id': userId,
        'image_url': imageUrl,
      };

      final result = await SupabaseService.insert('community_photos', data);

      if (result.isNotEmpty) {
        final photo = CommunityPhoto.fromSupabaseJson(result.first);
        _photos.insert(0, photo);
        _error = null;
        _isUploading = false;
        notifyListeners();
        return photo;
      }
      throw Exception('Failed to save photo metadata');
    } catch (e) {
      _error = 'Failed to upload photo: ${e.toString()}';
      debugPrint('CommunityPhotoService.addPhoto error: $e');
      _isUploading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Legacy method: Add a photo from URL (for backwards compatibility)
  @Deprecated('Use addPhoto() with image bytes instead')
  Future<CommunityPhoto> addPhotoUrl({
    required String placeId,
    required String imageUrl,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'place_id': placeId,
        'user_id': userId,
        'image_url': imageUrl,
      };

      final result = await SupabaseService.insert('community_photos', data);

      if (result.isNotEmpty) {
        final photo = CommunityPhoto.fromSupabaseJson(result.first);
        _photos.insert(0, photo);
        _error = null;
        notifyListeners();
        return photo;
      }
      throw Exception('Failed to add photo');
    } catch (e) {
      _error = 'Failed to add photo';
      debugPrint('CommunityPhotoService.addPhotoUrl error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await SupabaseService.delete('community_photos', filters: {'id': photoId});

      _photos.removeWhere((p) => p.id == photoId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete photo';
      debugPrint('CommunityPhotoService.deletePhoto error: $e');
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
