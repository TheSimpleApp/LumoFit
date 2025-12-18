import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing Supabase Storage operations for photos
/// Handles photo uploads, downloads, and deletions for all storage buckets
class PhotoStorageService {
  // Bucket names
  static const String communityPhotosBucket = 'community-photos';
  static const String quickPhotosBucket = 'quick-photos';
  static const String avatarsBucket = 'avatars';

  // Image quality settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int thumbnailSize = 400;
  static const int jpegQuality = 85;

  /// Get current authenticated user ID
  static String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  /// Upload a photo to community photos bucket
  /// Returns the storage path (not the full URL)
  static Future<String> uploadCommunityPhoto({
    required Uint8List imageBytes,
    required String placeId,
    String? photoId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Compress and resize image
      final processedBytes = await _processImage(imageBytes);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = photoId ?? 'photo_$timestamp';
      final path = '$userId/$placeId/$filename.jpg';

      // Upload to Supabase Storage
      await SupabaseConfig.storage
          .from(communityPhotosBucket)
          .uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('✅ Uploaded community photo to: $path');
      return path;
    } catch (e) {
      debugPrint('❌ Failed to upload community photo: $e');
      rethrow;
    }
  }

  /// Upload a quick photo to quick photos bucket
  /// Returns the storage path (not the full URL)
  static Future<String> uploadQuickPhoto({
    required Uint8List imageBytes,
    String? photoId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Compress and resize image
      final processedBytes = await _processImage(imageBytes);

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = photoId ?? 'quick_$timestamp';
      final path = '$userId/$filename.jpg';

      // Upload to Supabase Storage
      await SupabaseConfig.storage
          .from(quickPhotosBucket)
          .uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('✅ Uploaded quick photo to: $path');
      return path;
    } catch (e) {
      debugPrint('❌ Failed to upload quick photo: $e');
      rethrow;
    }
  }

  /// Upload an avatar photo
  /// Returns the storage path (not the full URL)
  static Future<String> uploadAvatar({
    required Uint8List imageBytes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Process avatar (smaller size, square crop)
      final processedBytes = await _processAvatar(imageBytes);

      // Use consistent filename for easy overwriting
      final path = '$userId/avatar.jpg';

      // Upload to Supabase Storage (upsert to replace existing)
      await SupabaseConfig.storage
          .from(avatarsBucket)
          .uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true, // Allow replacing existing avatar
            ),
          );

      debugPrint('✅ Uploaded avatar to: $path');
      return path;
    } catch (e) {
      debugPrint('❌ Failed to upload avatar: $e');
      rethrow;
    }
  }

  /// Delete a photo from community photos bucket
  static Future<void> deleteCommunityPhoto(String path) async {
    try {
      await SupabaseConfig.storage
          .from(communityPhotosBucket)
          .remove([path]);
      debugPrint('✅ Deleted community photo: $path');
    } catch (e) {
      debugPrint('❌ Failed to delete community photo: $e');
      rethrow;
    }
  }

  /// Delete a photo from quick photos bucket
  static Future<void> deleteQuickPhoto(String path) async {
    try {
      await SupabaseConfig.storage
          .from(quickPhotosBucket)
          .remove([path]);
      debugPrint('✅ Deleted quick photo: $path');
    } catch (e) {
      debugPrint('❌ Failed to delete quick photo: $e');
      rethrow;
    }
  }

  /// Delete an avatar
  static Future<void> deleteAvatar(String path) async {
    try {
      await SupabaseConfig.storage
          .from(avatarsBucket)
          .remove([path]);
      debugPrint('✅ Deleted avatar: $path');
    } catch (e) {
      debugPrint('❌ Failed to delete avatar: $e');
      rethrow;
    }
  }

  /// Get public URL for a storage path
  static String getPublicUrl(String bucket, String path) {
    return SupabaseConfig.storage.from(bucket).getPublicUrl(path);
  }

  /// Get public URL for a community photo
  static String getCommunityPhotoUrl(String path) {
    return getPublicUrl(communityPhotosBucket, path);
  }

  /// Get public URL for a quick photo
  static String getQuickPhotoUrl(String path) {
    return getPublicUrl(quickPhotosBucket, path);
  }

  /// Get public URL for an avatar
  static String getAvatarUrl(String path) {
    return getPublicUrl(avatarsBucket, path);
  }

  /// Process and compress an image
  /// Resizes to max dimensions and compresses to JPEG
  static Future<Uint8List> _processImage(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed (maintain aspect ratio)
      img.Image processedImage;
      if (image.width > maxImageWidth || image.height > maxImageHeight) {
        processedImage = img.copyResize(
          image,
          width: image.width > image.height ? maxImageWidth : null,
          height: image.height > image.width ? maxImageHeight : null,
          interpolation: img.Interpolation.linear,
        );
      } else {
        processedImage = image;
      }

      // Encode as JPEG with quality compression
      final compressedBytes = img.encodeJpg(processedImage, quality: jpegQuality);

      debugPrint('📸 Image processed: ${imageBytes.length} bytes → ${compressedBytes.length} bytes');
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('⚠️ Image processing failed, using original: $e');
      return imageBytes;
    }
  }

  /// Process an avatar image (square crop, smaller size)
  static Future<Uint8List> _processAvatar(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Crop to square (center crop)
      final size = image.width < image.height ? image.width : image.height;
      final x = (image.width - size) ~/ 2;
      final y = (image.height - size) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Resize to thumbnail size
      final resized = img.copyResize(
        cropped,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG
      final compressedBytes = img.encodeJpg(resized, quality: jpegQuality);

      debugPrint('👤 Avatar processed: ${imageBytes.length} bytes → ${compressedBytes.length} bytes');
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('⚠️ Avatar processing failed, using fallback processing: $e');
      return _processImage(imageBytes);
    }
  }

  /// Download a photo from storage
  static Future<Uint8List> downloadPhoto(String bucket, String path) async {
    try {
      final bytes = await SupabaseConfig.storage
          .from(bucket)
          .download(path);
      return bytes;
    } catch (e) {
      debugPrint('❌ Failed to download photo: $e');
      rethrow;
    }
  }

  /// Check if a file exists in storage
  static Future<bool> fileExists(String bucket, String path) async {
    try {
      final files = await SupabaseConfig.storage
          .from(bucket)
          .list(path: path);
      return files.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check file existence: $e');
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int?> getFileSize(String bucket, String path) async {
    try {
      final bytes = await downloadPhoto(bucket, path);
      return bytes.length;
    } catch (e) {
      debugPrint('❌ Failed to get file size: $e');
      return null;
    }
  }
}
