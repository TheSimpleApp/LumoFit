import 'dart:convert';

/// A quick-added photo captured by the user (not yet assigned to a place)
class QuickPhoto {
  final String id;
  final String? userId;
  final String? placeId; // null until assigned later
  final String imageUrl; // can be data URL or network URL
  final DateTime createdAt;

  QuickPhoto({
    required this.id,
    required this.imageUrl,
    this.userId,
    this.placeId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QuickPhoto copyWith({
    String? id,
    String? userId,
    String? placeId,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return QuickPhoto(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'placeId': placeId,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuickPhoto.fromJson(Map<String, dynamic> json) => QuickPhoto(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        placeId: json['placeId'] as String?,
        imageUrl: json['imageUrl'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());
  factory QuickPhoto.fromJsonString(String source) =>
      QuickPhoto.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
