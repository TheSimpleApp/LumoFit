import 'dart:convert';

/// Community-submitted photo associated with a place
class CommunityPhoto {
  final String id;
  final String placeId; // references PlaceModel.id
  final String? userId; // optional until auth is added
  final String imageUrl; // currently URL; later can be Supabase storage path
  final DateTime createdAt;

  CommunityPhoto({
    required this.id,
    required this.placeId,
    required this.imageUrl,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CommunityPhoto copyWith({
    String? id,
    String? placeId,
    String? userId,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return CommunityPhoto(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'userId': userId,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommunityPhoto.fromJson(Map<String, dynamic> json) => CommunityPhoto(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userId: json['userId'] as String?,
        imageUrl: json['imageUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());
  factory CommunityPhoto.fromJsonString(String source) =>
      CommunityPhoto.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  factory CommunityPhoto.fromSupabaseJson(Map<String, dynamic> json) =>
      CommunityPhoto(
        id: json['id'] as String,
        placeId: json['place_id'] as String,
        userId: json['user_id'] as String?,
        imageUrl: json['image_url'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  /// Convert to Supabase JSON (snake_case keys) for insert/update
  Map<String, dynamic> toSupabaseJson(String userId) => {
        'place_id': placeId,
        'user_id': userId,
        'image_url': imageUrl,
      };
}
