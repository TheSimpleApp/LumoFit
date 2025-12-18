import 'dart:convert';

class TripModel {
  final String id;
  final String userId;
  final String destinationCity;
  final String? destinationCountry;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? notes;
  final String? imageUrl;
  final List<String> savedPlaceIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.userId,
    required this.destinationCity,
    this.destinationCountry,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.notes,
    this.imageUrl,
    this.savedPlaceIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TripModel copyWith({
    String? id,
    String? userId,
    String? destinationCity,
    String? destinationCountry,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
    String? imageUrl,
    List<String>? savedPlaceIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      savedPlaceIds: savedPlaceIds ?? this.savedPlaceIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'imageUrl': imageUrl,
      'savedPlaceIds': savedPlaceIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      destinationCity: json['destinationCity'] as String,
      destinationCountry: json['destinationCountry'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? false,
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
      savedPlaceIds: (json['savedPlaceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TripModel.fromJsonString(String source) =>
      TripModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  /// savedPlaceIds comes from join with trip_places table
  factory TripModel.fromSupabaseJson(
    Map<String, dynamic> json, {
    List<String>? savedPlaceIds,
  }) {
    return TripModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      destinationCity: json['destination_city'] as String,
      destinationCountry: json['destination_country'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? false,
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String?,
      savedPlaceIds: savedPlaceIds ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Supabase JSON (snake_case keys)
  /// Note: savedPlaceIds are stored in trip_places junction table, not here
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'destination_city': destinationCity,
      'destination_country': destinationCountry,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'notes': notes,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isPast => endDate.isBefore(DateTime.now());
  bool get isCurrent {
    final now = DateTime.now();
    return !startDate.isAfter(now) && !endDate.isBefore(now);
  }

  String get status {
    if (isActive) return 'Active';
    if (isCurrent) return 'Current';
    if (isUpcoming) return 'Upcoming';
    return 'Past';
  }
}
