import 'dart:convert';

enum ChallengeType { daily, weekly, trip, special }

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int xpReward;
  final String requirementType; // 'workouts', 'meals', 'steps', etc.
  final int requirementValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String iconName;
  final DateTime createdAt;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.xpReward = 0,
    required this.requirementType,
    required this.requirementValue,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.iconName = 'emoji_events',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'xpReward': xpReward,
      'requirementType': requirementType,
      'requirementValue': requirementValue,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.daily,
      ),
      xpReward: json['xpReward'] as int? ?? 0,
      requirementType: json['requirementType'] as String,
      requirementValue: json['requirementValue'] as int,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      iconName: json['iconName'] as String? ?? 'emoji_events',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create from Supabase JSON (snake_case keys)
  factory ChallengeModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['challenge_type'],
        orElse: () => ChallengeType.daily,
      ),
      xpReward: json['xp_reward'] as int? ?? 0,
      requirementType: json['requirement_type'] as String,
      requirementValue: json['requirement_value'] as int,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      iconName: json['icon_name'] as String? ?? 'emoji_events',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.trip:
        return 'Trip';
      case ChallengeType.special:
        return 'Special';
    }
  }
}

class UserChallengeModel {
  final String id;
  final String odId;
  final String challengeId;
  final int progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  UserChallengeModel({
    required this.id,
    required this.odId,
    required this.challengeId,
    this.progress = 0,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserChallengeModel copyWith({
    String? id,
    String? userId,
    String? challengeId,
    int? progress,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return UserChallengeModel(
      id: id ?? this.id,
      odId: userId ?? odId,
      challengeId: challengeId ?? this.challengeId,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': odId,
      'challengeId': challengeId,
      'progress': progress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserChallengeModel.fromJson(Map<String, dynamic> json) {
    return UserChallengeModel(
      id: json['id'] as String,
      odId: json['userId'] as String,
      challengeId: json['challengeId'] as String,
      progress: json['progress'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserChallengeModel.fromJsonString(String source) =>
      UserChallengeModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  factory UserChallengeModel.fromSupabaseJson(Map<String, dynamic> json) {
    return UserChallengeModel(
      id: json['id'] as String,
      odId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      progress: json['progress'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Supabase JSON (snake_case keys) for insert/update
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'challenge_id': challengeId,
      'progress': progress,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
