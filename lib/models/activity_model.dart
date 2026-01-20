import 'dart:convert';

enum ActivityType { workout, meal, walk, run, hike, swim, yoga, other }

class ActivityModel {
  final String id;
  final String userId;
  final String? tripId;
  final ActivityType type;
  final String? placeId;
  final String title;
  final String? description;
  final int? durationMinutes;
  final int? caloriesBurned;
  final int xpEarned;
  final DateTime completedAt;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.userId,
    this.tripId,
    required this.type,
    this.placeId,
    required this.title,
    this.description,
    this.durationMinutes,
    this.caloriesBurned,
    this.xpEarned = 0,
    DateTime? completedAt,
    DateTime? createdAt,
  })  : completedAt = completedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  ActivityModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    ActivityType? type,
    String? placeId,
    String? title,
    String? description,
    int? durationMinutes,
    int? caloriesBurned,
    int? xpEarned,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'type': type.name,
      'placeId': placeId,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'xpEarned': xpEarned,
      'completedAt': completedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.other,
      ),
      placeId: json['placeId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      caloriesBurned: json['caloriesBurned'] as int?,
      xpEarned: json['xpEarned'] as int? ?? 0,
      completedAt: DateTime.parse(json['completedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ActivityModel.fromJsonString(String source) =>
      ActivityModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  factory ActivityModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripId: json['trip_id'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['activity_type'],
        orElse: () => ActivityType.other,
      ),
      placeId: json['place_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      caloriesBurned: json['calories_burned'] as int?,
      xpEarned: json['xp_earned'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Supabase JSON (snake_case keys) for insert/update
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'trip_id': tripId,
      'activity_type': type.name,
      'place_id': placeId,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'xp_earned': xpEarned,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  String get typeEmoji {
    switch (type) {
      case ActivityType.workout:
        return '🏋️';
      case ActivityType.meal:
        return '🥗';
      case ActivityType.walk:
        return '🚶';
      case ActivityType.run:
        return '🏃';
      case ActivityType.hike:
        return '🥾';
      case ActivityType.swim:
        return '🏊';
      case ActivityType.yoga:
        return '🧘';
      case ActivityType.other:
        return '⭐';
    }
  }

  String get typeLabel {
    switch (type) {
      case ActivityType.workout:
        return 'Workout';
      case ActivityType.meal:
        return 'Healthy Meal';
      case ActivityType.walk:
        return 'Walk';
      case ActivityType.run:
        return 'Run';
      case ActivityType.hike:
        return 'Hike';
      case ActivityType.swim:
        return 'Swim';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.other:
        return 'Activity';
    }
  }

  static int calculateXp(ActivityType type, int? durationMinutes) {
    final basXp = {
      ActivityType.workout: 50,
      ActivityType.meal: 20,
      ActivityType.walk: 15,
      ActivityType.run: 40,
      ActivityType.hike: 60,
      ActivityType.swim: 45,
      ActivityType.yoga: 30,
      ActivityType.other: 10,
    };

    int base = basXp[type] ?? 10;
    if (durationMinutes != null && durationMinutes > 0) {
      base += (durationMinutes / 10).floor() * 5;
    }
    return base;
  }
}
