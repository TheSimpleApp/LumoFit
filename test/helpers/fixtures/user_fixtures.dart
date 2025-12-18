import 'package:fittravel/models/user_model.dart';

/// Test fixtures for UserModel

UserModel createTestUser({
  String? id,
  String? email,
  String? displayName,
  int? totalXp,
  int? currentStreak,
  int? longestStreak,
  FitnessLevel? fitnessLevel,
}) {
  return UserModel(
    id: id ?? 'test-user-123',
    email: email ?? 'test@fittravel.app',
    displayName: displayName ?? 'Test User',
    totalXp: totalXp ?? 1000,
    currentStreak: currentStreak ?? 5,
    longestStreak: longestStreak ?? 10,
    fitnessLevel: fitnessLevel ?? FitnessLevel.intermediate,
  );
}

/// Test user with beginner fitness level
UserModel get testBeginnerUser => createTestUser(
      id: 'beginner-user',
      displayName: 'Beginner User',
      fitnessLevel: FitnessLevel.beginner,
      totalXp: 100,
      currentStreak: 1,
      longestStreak: 3,
    );

/// Test user with advanced fitness level
UserModel get testAdvancedUser => createTestUser(
      id: 'advanced-user',
      displayName: 'Advanced User',
      fitnessLevel: FitnessLevel.advanced,
      totalXp: 10000,
      currentStreak: 30,
      longestStreak: 90,
    );

/// Test user JSON data (camelCase - for local storage)
Map<String, dynamic> get testUserJson => {
      'id': 'test-user-123',
      'email': 'test@fittravel.app',
      'displayName': 'Test User',
      'totalXp': 1000,
      'currentStreak': 5,
      'longestStreak': 10,
      'fitnessLevel': 'intermediate',
      'homeCity': null,
      'dietaryPreferences': <String>[],
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
    };

/// Test user Supabase JSON data (snake_case - for database)
Map<String, dynamic> get testUserSupabaseJson => {
      'id': 'test-user-123',
      'email': 'test@fittravel.app',
      'display_name': 'Test User',
      'total_xp': 1000,
      'current_streak': 5,
      'longest_streak': 10,
      'fitness_level': 'intermediate',
      'home_city': null,
      'dietary_preferences': <String>[],
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
