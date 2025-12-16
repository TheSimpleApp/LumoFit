import 'dart:convert';

enum FitnessLevel { beginner, intermediate, advanced }

class UserModel {
  final String id;
  final String? email;
  final String displayName;
  final String? avatarUrl;
  final String? homeCity;
  final FitnessLevel fitnessLevel;
  final List<String> dietaryPreferences;
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.email,
    required this.displayName,
    this.avatarUrl,
    this.homeCity,
    this.fitnessLevel = FitnessLevel.beginner,
    this.dietaryPreferences = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXp = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? homeCity,
    FitnessLevel? fitnessLevel,
    List<String>? dietaryPreferences,
    int? currentStreak,
    int? longestStreak,
    int? totalXp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      homeCity: homeCity ?? this.homeCity,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalXp: totalXp ?? this.totalXp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'homeCity': homeCity,
      'fitnessLevel': fitnessLevel.name,
      'dietaryPreferences': dietaryPreferences,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalXp': totalXp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      homeCity: json['homeCity'] as String?,
      fitnessLevel: FitnessLevel.values.firstWhere(
        (e) => e.name == json['fitnessLevel'],
        orElse: () => FitnessLevel.beginner,
      ),
      dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalXp: json['totalXp'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  
  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  int get level => (totalXp / 1000).floor() + 1;
  int get xpForNextLevel => (level * 1000) - totalXp;
  double get levelProgress => (totalXp % 1000) / 1000;
}
