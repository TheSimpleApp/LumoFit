import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/models/user_model.dart';
import '../../helpers/fixtures/user_fixtures.dart';

void main() {
  group('UserModel', () {
    group('JSON serialization', () {
      test('toJson() creates valid camelCase JSON', () {
        final user = createTestUser();
        final json = user.toJson();

        expect(json['id'], 'test-user-123');
        expect(json['email'], 'test@fittravel.app');
        expect(json['displayName'], 'Test User');
        expect(json['totalXp'], 1000);
        expect(json['currentStreak'], 5);
        expect(json['longestStreak'], 10);
        expect(json['fitnessLevel'], 'intermediate');
      });

      test('fromJson() creates UserModel from camelCase JSON', () {
        final user = UserModel.fromJson(testUserJson);

        expect(user.id, 'test-user-123');
        expect(user.email, 'test@fittravel.app');
        expect(user.displayName, 'Test User');
        expect(user.totalXp, 1000);
        expect(user.currentStreak, 5);
        expect(user.longestStreak, 10);
        expect(user.fitnessLevel, FitnessLevel.intermediate);
      });

      test('fromJson() -> toJson() roundtrip preserves data', () {
        final original = testUserJson;
        final user = UserModel.fromJson(original);
        final serialized = user.toJson();

        expect(serialized['id'], original['id']);
        expect(serialized['email'], original['email']);
        expect(serialized['displayName'], original['displayName']);
        expect(serialized['totalXp'], original['totalXp']);
        expect(serialized['currentStreak'], original['currentStreak']);
        expect(serialized['longestStreak'], original['longestStreak']);
        expect(serialized['fitnessLevel'], original['fitnessLevel']);
      });
    });

    group('Supabase JSON serialization', () {
      test('fromSupabaseJson() creates UserModel from snake_case JSON', () {
        final user = UserModel.fromSupabaseJson(testUserSupabaseJson);

        expect(user.id, 'test-user-123');
        expect(user.email, 'test@fittravel.app');
        expect(user.displayName, 'Test User');
        expect(user.totalXp, 1000);
        expect(user.currentStreak, 5);
        expect(user.longestStreak, 10);
        expect(user.fitnessLevel, FitnessLevel.intermediate);
      });

      test('toSupabaseJson() creates valid snake_case JSON', () {
        final user = createTestUser();
        final json = user.toSupabaseJson();

        expect(json['display_name'], 'Test User');
        expect(json['total_xp'], 1000);
        expect(json['current_streak'], 5);
        expect(json['longest_streak'], 10);
        expect(json['fitness_level'], 'intermediate');
        // Note: id and email are not included in toSupabaseJson
        // as they are managed by Supabase Auth
      });
    });

    group('FitnessLevel enum', () {
      test('serializes to correct string values', () {
        expect(FitnessLevel.beginner.name, 'beginner');
        expect(FitnessLevel.intermediate.name, 'intermediate');
        expect(FitnessLevel.advanced.name, 'advanced');
      });

      test('deserializes from string values', () {
        final beginner = FitnessLevel.values.firstWhere(
          (e) => e.name == 'beginner',
        );
        expect(beginner, FitnessLevel.beginner);

        final advanced = FitnessLevel.values.firstWhere(
          (e) => e.name == 'advanced',
        );
        expect(advanced, FitnessLevel.advanced);
      });
    });

    group('level calculation', () {
      test('calculates correct level from XP', () {
        // Level formula: (totalXp / 1000).floor() + 1
        final newUser = createTestUser(totalXp: 100);
        expect(newUser.level, 1); // (100/1000).floor() + 1 = 0 + 1 = 1

        final levelThree = createTestUser(totalXp: 2500);
        expect(levelThree.level, 3); // (2500/1000).floor() + 1 = 2 + 1 = 3

        final levelEleven = createTestUser(totalXp: 10000);
        expect(levelEleven.level, 11); // (10000/1000).floor() + 1 = 10 + 1 = 11
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = createTestUser();
        final updated = original.copyWith(
          displayName: 'Updated Name',
          totalXp: 2000,
        );

        expect(updated.displayName, 'Updated Name');
        expect(updated.totalXp, 2000);
        // Other fields remain unchanged
        expect(updated.id, original.id);
        expect(updated.email, original.email);
      });

      test('returns new instance, not mutated original', () {
        final original = createTestUser(totalXp: 1000);
        final updated = original.copyWith(totalXp: 2000);

        expect(original.totalXp, 1000); // Original unchanged
        expect(updated.totalXp, 2000);
      });
    });
  });
}
