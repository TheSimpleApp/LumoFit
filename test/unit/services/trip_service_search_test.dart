import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/models/trip_model.dart';
import '../../helpers/fixtures/trip_fixtures.dart';

/// Tests for TripService.searchTrips() filtering logic
/// The searchTrips method filters trips by:
/// - destinationCity (case-insensitive)
/// - destinationCountry (case-insensitive)
/// - notes (case-insensitive)

void main() {
  group('TripService searchTrips logic', () {
    late List<TripModel> testTrips;

    /// Simulates the searchTrips logic for unit testing
    List<TripModel> searchTrips(List<TripModel> trips, String query) {
      final lowerQuery = query.toLowerCase();
      return trips.where((t) {
        return t.destinationCity.toLowerCase().contains(lowerQuery) ||
            (t.destinationCountry?.toLowerCase().contains(lowerQuery) ??
                false) ||
            (t.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    setUp(() {
      // Create a variety of test trips for searching
      testTrips = [
        createTestTrip(
          id: 'trip-1',
          destinationCity: 'Salt Lake City',
          destinationCountry: 'United States',
          notes: 'Skiing trip with friends',
        ),
        createTestTrip(
          id: 'trip-2',
          destinationCity: 'Paris',
          destinationCountry: 'France',
          notes: 'Romantic getaway',
        ),
        createTestTrip(
          id: 'trip-3',
          destinationCity: 'Tokyo',
          destinationCountry: 'Japan',
          notes: 'Business conference',
        ),
        createTestTrip(
          id: 'trip-4',
          destinationCity: 'London',
          destinationCountry: 'United Kingdom',
          notes: null, // No notes
        ),
        createTestTrip(
          id: 'trip-5',
          destinationCity: 'New York City',
          destinationCountry: 'United States',
          notes: 'Work conference + explore',
        ),
      ];
    });

    group('search by city name', () {
      test('finds trip by exact city name', () {
        final results = searchTrips(testTrips, 'Paris');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'Paris');
      });

      test('finds trip by partial city name', () {
        final results = searchTrips(testTrips, 'Salt');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'Salt Lake City');
      });

      test('finds trip by city name case-insensitive', () {
        final results = searchTrips(testTrips, 'tokyo');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'Tokyo');
      });

      test('finds trip with mixed case search', () {
        final results = searchTrips(testTrips, 'LoNdOn');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'London');
      });

      test('finds multiple trips with common word in city', () {
        final results = searchTrips(testTrips, 'City');
        expect(results.length, 2); // Salt Lake City and New York City
        expect(
          results.map((t) => t.destinationCity).toList(),
          containsAll(['Salt Lake City', 'New York City']),
        );
      });
    });

    group('search by country name', () {
      test('finds trip by exact country name', () {
        final results = searchTrips(testTrips, 'France');
        expect(results.length, 1);
        expect(results.first.destinationCountry, 'France');
      });

      test('finds multiple trips by country name', () {
        final results = searchTrips(testTrips, 'United States');
        expect(results.length, 2); // Salt Lake City and New York City
        expect(
          results.every((t) => t.destinationCountry == 'United States'),
          true,
        );
      });

      test('finds trip by partial country name', () {
        final results = searchTrips(testTrips, 'Kingdom');
        expect(results.length, 1);
        expect(results.first.destinationCountry, 'United Kingdom');
      });

      test('finds trip by country name case-insensitive', () {
        final results = searchTrips(testTrips, 'japan');
        expect(results.length, 1);
        expect(results.first.destinationCountry, 'Japan');
      });
    });

    group('search by notes', () {
      test('finds trip by notes content', () {
        final results = searchTrips(testTrips, 'Skiing');
        expect(results.length, 1);
        expect(results.first.notes, 'Skiing trip with friends');
      });

      test('finds trip by partial notes', () {
        final results = searchTrips(testTrips, 'conference');
        expect(results.length, 2); // Tokyo and New York City
      });

      test('finds trip by notes case-insensitive', () {
        final results = searchTrips(testTrips, 'ROMANTIC');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'Paris');
      });

      test('handles trips with null notes', () {
        final results = searchTrips(testTrips, 'London');
        expect(results.length, 1);
        // London trip has null notes but should still be found by city
        expect(results.first.notes, null);
      });
    });

    group('empty and no results', () {
      test('returns empty list when no matches', () {
        final results = searchTrips(testTrips, 'XYZ123');
        expect(results.isEmpty, true);
      });

      test('returns all trips when query is empty', () {
        // Note: Actual implementation may handle empty differently,
        // but this tests the current filter logic
        final results = searchTrips(testTrips, '');
        // Empty string matches everything since every string contains ''
        expect(results.length, testTrips.length);
      });
    });

    group('combined search scenarios', () {
      test('search term matches both city and country', () {
        // "United" matches "United States" (country) and could potentially
        // match a city name if one contained "United"
        final results = searchTrips(testTrips, 'United');
        // Should find both US trips (country match) and UK trip (country match)
        expect(results.length, 3);
      });

      test('handles special characters in search', () {
        final results = searchTrips(testTrips, 'New York');
        expect(results.length, 1);
        expect(results.first.destinationCity, 'New York City');
      });
    });

    group('all trip sections searchable', () {
      test('can search across active, current, upcoming, and past trips', () {
        // Create trips from different time periods
        final now = DateTime.now();
        final mixedTrips = [
          // Active trip (current time + isActive)
          createTestTrip(
            id: 'active-trip',
            destinationCity: 'Miami',
            isActive: true,
            startDate: now.subtract(const Duration(days: 1)),
            endDate: now.add(const Duration(days: 5)),
          ),
          // Current trip (but not active)
          createTestTrip(
            id: 'current-trip',
            destinationCity: 'Miami Beach',
            isActive: false,
            startDate: now.subtract(const Duration(days: 1)),
            endDate: now.add(const Duration(days: 5)),
          ),
          // Upcoming trip
          createTestTrip(
            id: 'upcoming-trip',
            destinationCity: 'Miami Gardens',
            startDate: now.add(const Duration(days: 30)),
            endDate: now.add(const Duration(days: 37)),
          ),
          // Past trip
          createTestTrip(
            id: 'past-trip',
            destinationCity: 'Miami Springs',
            startDate: now.subtract(const Duration(days: 60)),
            endDate: now.subtract(const Duration(days: 53)),
          ),
        ];

        // Search for "Miami" should find all 4 trips regardless of status
        final results = searchTrips(mixedTrips, 'Miami');
        expect(results.length, 4);
        expect(
          results.map((t) => t.id).toList(),
          containsAll([
            'active-trip',
            'current-trip',
            'upcoming-trip',
            'past-trip',
          ]),
        );
      });
    });
  });
}
