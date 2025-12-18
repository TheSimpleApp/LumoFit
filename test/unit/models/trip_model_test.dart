import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/models/trip_model.dart';
import '../../helpers/fixtures/trip_fixtures.dart';

void main() {
  group('TripModel', () {
    group('JSON serialization', () {
      test('toJson() creates valid camelCase JSON', () {
        final trip = createTestTrip(
          savedPlaceIds: ['place-1', 'place-2'],
          notes: 'Test notes',
        );
        final json = trip.toJson();

        expect(json['id'], 'test-trip-123');
        expect(json['userId'], 'test-user-123');
        expect(json['destinationCity'], 'Salt Lake City');
        expect(json['destinationCountry'], 'United States');
        expect(json['isActive'], false);
        expect(json['savedPlaceIds'], ['place-1', 'place-2']);
        expect(json['notes'], 'Test notes');
        expect(json['startDate'], isNotNull);
        expect(json['endDate'], isNotNull);
      });

      test('fromJson() creates TripModel from camelCase JSON', () {
        final json = testTripJson();
        final trip = TripModel.fromJson(json);

        expect(trip.id, 'test-trip-123');
        expect(trip.userId, 'test-user-123');
        expect(trip.destinationCity, 'Salt Lake City');
        expect(trip.destinationCountry, 'United States');
        expect(trip.isActive, false);
      });

      test('fromJson() -> toJson() roundtrip preserves data', () {
        final original = testTripJson();
        final trip = TripModel.fromJson(original);
        final serialized = trip.toJson();

        expect(serialized['id'], original['id']);
        expect(serialized['userId'], original['userId']);
        expect(serialized['destinationCity'], original['destinationCity']);
        expect(serialized['isActive'], original['isActive']);
      });
    });

    group('Supabase JSON serialization', () {
      test('fromSupabaseJson() creates TripModel from snake_case JSON', () {
        final json = testTripSupabaseJson();
        final trip = TripModel.fromSupabaseJson(json);

        expect(trip.id, 'test-trip-123');
        expect(trip.userId, 'test-user-123');
        expect(trip.destinationCity, 'Salt Lake City');
        expect(trip.destinationCountry, 'United States');
        expect(trip.isActive, false);
      });

      test('fromSupabaseJson() handles savedPlaceIds from query', () {
        final json = testTripSupabaseJson();
        final trip = TripModel.fromSupabaseJson(
          json,
          savedPlaceIds: ['place-1', 'place-2', 'place-3'],
        );

        expect(trip.savedPlaceIds, ['place-1', 'place-2', 'place-3']);
      });

      test('toSupabaseJson() creates valid snake_case JSON', () {
        final trip = createTestTrip(
          notes: 'Conference trip',
        );
        final json = trip.toSupabaseJson('test-user-456');

        expect(json['destination_city'], 'Salt Lake City');
        expect(json['destination_country'], 'United States');
        expect(json['is_active'], false);
        expect(json['notes'], 'Conference trip');
        expect(json['user_id'], 'test-user-456');
      });
    });

    group('trip status', () {
      test('identifies active trip correctly', () {
        final trip = testActiveTrip;
        expect(trip.status, 'Active');
      });

      test('identifies upcoming trip correctly', () {
        final trip = testUpcomingTrip;
        expect(trip.status, 'Upcoming');
      });

      test('identifies past trip correctly', () {
        final trip = testPastTrip;
        expect(trip.status, 'Past');
      });
    });

    group('trip duration', () {
      test('calculates duration in days correctly', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 8);
        final trip = createTestTrip(startDate: start, endDate: end);

        // durationDays = endDate.difference(startDate).inDays + 1
        // = 7 days difference + 1 = 8 days total
        expect(trip.durationDays, 8);
      });

      test('handles single-day trips', () {
        final date = DateTime(2024, 1, 1);
        final trip = createTestTrip(startDate: date, endDate: date);

        // Single day trip: 0 days difference + 1 = 1 day
        expect(trip.durationDays, 1);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = createTestTrip();
        final updated = original.copyWith(
          destinationCity: 'New York City',
          isActive: true,
        );

        expect(updated.destinationCity, 'New York City');
        expect(updated.isActive, true);
        // Other fields remain unchanged
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
      });

      test('can update savedPlaceIds', () {
        final original = createTestTrip(savedPlaceIds: ['place-1']);
        final updated = original.copyWith(
          savedPlaceIds: ['place-1', 'place-2', 'place-3'],
        );

        expect(updated.savedPlaceIds, ['place-1', 'place-2', 'place-3']);
        expect(original.savedPlaceIds, ['place-1']); // Original unchanged
      });
    });
  });
}
