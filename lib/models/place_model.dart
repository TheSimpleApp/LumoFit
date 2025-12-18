import 'dart:convert';

enum PlaceType { gym, restaurant, park, trail, other }

class PlaceModel {
  final String id;
  final String? googlePlaceId;
  final PlaceType type;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String? photoReference;
  final String? phoneNumber;
  final String? website;
  final List<String> openingHours;
  final String? priceLevel;
  final String? notes;
  final bool isVisited;
  final DateTime? visitedAt;
  final DateTime createdAt;
  final String? userId;

  PlaceModel({
    required this.id,
    this.googlePlaceId,
    required this.type,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.photoReference,
    this.phoneNumber,
    this.website,
    this.openingHours = const [],
    this.priceLevel,
    this.notes,
    this.isVisited = false,
    this.visitedAt,
    DateTime? createdAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  PlaceModel copyWith({
    String? id,
    String? googlePlaceId,
    PlaceType? type,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? userRatingsTotal,
    String? photoReference,
    String? phoneNumber,
    String? website,
    List<String>? openingHours,
    String? priceLevel,
    String? notes,
    bool? isVisited,
    DateTime? visitedAt,
    DateTime? createdAt,
    String? userId,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      type: type ?? this.type,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      photoReference: photoReference ?? this.photoReference,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      priceLevel: priceLevel ?? this.priceLevel,
      notes: notes ?? this.notes,
      isVisited: isVisited ?? this.isVisited,
      visitedAt: visitedAt ?? this.visitedAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'googlePlaceId': googlePlaceId,
      'type': type.name,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'photoReference': photoReference,
      'phoneNumber': phoneNumber,
      'website': website,
      'openingHours': openingHours,
      'priceLevel': priceLevel,
      'notes': notes,
      'isVisited': isVisited,
      'visitedAt': visitedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      googlePlaceId: json['googlePlaceId'] as String?,
      type: PlaceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaceType.other,
      ),
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingsTotal'] as int?,
      photoReference: json['photoReference'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
      openingHours: (json['openingHours'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      priceLevel: json['priceLevel'] as String?,
      notes: json['notes'] as String?,
      isVisited: json['isVisited'] as bool? ?? false,
      visitedAt: json['visitedAt'] != null
          ? DateTime.parse(json['visitedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PlaceModel.fromJsonString(String source) =>
      PlaceModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  factory PlaceModel.fromSupabaseJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      googlePlaceId: json['google_place_id'] as String?,
      type: PlaceType.values.firstWhere(
        (e) => e.name == json['place_type'],
        orElse: () => PlaceType.other,
      ),
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      photoReference: json['photo_reference'] as String?,
      phoneNumber: json['phone_number'] as String?,
      website: json['website'] as String?,
      openingHours: (json['opening_hours'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      priceLevel: json['price_level'] as String?,
      notes: json['notes'] as String?,
      isVisited: json['is_visited'] as bool? ?? false,
      visitedAt: json['visited_at'] != null
          ? DateTime.parse(json['visited_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      userId: json['user_id'] as String?,
    );
  }

  /// Convert to Supabase JSON (snake_case keys) for insert/update
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'google_place_id': googlePlaceId,
      'place_type': type.name,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'photo_reference': photoReference,
      'phone_number': phoneNumber,
      'website': website,
      'opening_hours': openingHours,
      'price_level': priceLevel,
      'notes': notes,
      'is_visited': isVisited,
      'visited_at': visitedAt?.toIso8601String(),
    };
  }

  String get typeEmoji {
    switch (type) {
      case PlaceType.gym:
        return '🏋️';
      case PlaceType.restaurant:
        return '🥗';
      case PlaceType.park:
        return '🌳';
      case PlaceType.trail:
        return '🥾';
      case PlaceType.other:
        return '📍';
    }
  }

  String get typeLabel {
    switch (type) {
      case PlaceType.gym:
        return 'Gym';
      case PlaceType.restaurant:
        return 'Restaurant';
      case PlaceType.park:
        return 'Park';
      case PlaceType.trail:
        return 'Trail';
      case PlaceType.other:
        return 'Place';
    }
  }
}
