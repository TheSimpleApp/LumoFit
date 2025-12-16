import 'dart:convert';

enum BadgeRequirementType { streak, visits, activities, cities, xp }

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int xpReward;
  final BadgeRequirementType requirementType;
  final int requirementValue;
  final String tier; // bronze, silver, gold
  final DateTime createdAt;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.xpReward = 0,
    required this.requirementType,
    required this.requirementValue,
    this.tier = 'bronze',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'xpReward': xpReward,
      'requirementType': requirementType.name,
      'requirementValue': requirementValue,
      'tier': tier,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      xpReward: json['xpReward'] as int? ?? 0,
      requirementType: BadgeRequirementType.values.firstWhere(
        (e) => e.name == json['requirementType'],
        orElse: () => BadgeRequirementType.activities,
      ),
      requirementValue: json['requirementValue'] as int,
      tier: json['tier'] as String? ?? 'bronze',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UserBadgeModel {
  final String id;
  final String odId;
  final String badgeId;
  final DateTime earnedAt;

  UserBadgeModel({
    required this.id,
    required this.odId,
    required this.badgeId,
    DateTime? earnedAt,
  }) : earnedAt = earnedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': odId,
      'badgeId': badgeId,
      'earnedAt': earnedAt.toIso8601String(),
    };
  }

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) {
    return UserBadgeModel(
      id: json['id'] as String,
      odId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserBadgeModel.fromJsonString(String source) =>
      UserBadgeModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
