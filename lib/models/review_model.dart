import 'dart:convert';

/// Community review for a place
class ReviewModel {
  final String id;
  final String placeId; // Google Place ID or internal id
  final String? userId; // optional until auth is added
  final int rating; // 1-5
  final String? text;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.placeId,
    required this.rating,
    this.userId,
    this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ReviewModel copyWith({
    String? id,
    String? placeId,
    String? userId,
    int? rating,
    String? text,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'userId': userId,
        'rating': rating,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userId: json['userId'] as String?,
        rating: json['rating'] as int,
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());
  factory ReviewModel.fromJsonString(String source) =>
      ReviewModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
