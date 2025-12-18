import 'package:fittravel/models/trip_model.dart';

/// Test fixtures for TripModel

TripModel createTestTrip({
  String? id,
  String? userId,
  String? destinationCity,
  String? destinationCountry,
  DateTime? startDate,
  DateTime? endDate,
  bool? isActive,
  List<String>? savedPlaceIds,
  String? notes,
}) {
  final now = DateTime.now();
  return TripModel(
    id: id ?? 'test-trip-123',
    userId: userId ?? 'test-user-123',
    destinationCity: destinationCity ?? 'Salt Lake City',
    destinationCountry: destinationCountry ?? 'United States',
    startDate: startDate ?? now,
    endDate: endDate ?? now.add(const Duration(days: 7)),
    isActive: isActive ?? false,
    savedPlaceIds: savedPlaceIds ?? [],
    notes: notes,
  );
}

/// Active trip with places
TripModel get testActiveTrip => createTestTrip(
      id: 'active-trip',
      destinationCity: 'New York City',
      destinationCountry: 'United States',
      isActive: true,
      savedPlaceIds: ['place-1', 'place-2', 'place-3'],
      notes: 'Work conference + explore',
    );

/// Upcoming trip
TripModel get testUpcomingTrip {
  final now = DateTime.now();
  return createTestTrip(
    id: 'upcoming-trip',
    destinationCity: 'Los Angeles',
    startDate: now.add(const Duration(days: 14)),
    endDate: now.add(const Duration(days: 21)),
    isActive: false,
  );
}

/// Past trip
TripModel get testPastTrip {
  final now = DateTime.now();
  return createTestTrip(
    id: 'past-trip',
    destinationCity: 'San Francisco',
    startDate: now.subtract(const Duration(days: 30)),
    endDate: now.subtract(const Duration(days: 23)),
    isActive: false,
    savedPlaceIds: ['place-4', 'place-5'],
  );
}

/// Test trip JSON (camelCase)
Map<String, dynamic> testTripJson({
  String? id,
  String? userId,
}) =>
    {
      'id': id ?? 'test-trip-123',
      'userId': userId ?? 'test-user-123',
      'destinationCity': 'Salt Lake City',
      'destinationCountry': 'United States',
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'isActive': false,
      'savedPlaceIds': <String>[],
      'notes': null,
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
    };

/// Test trip Supabase JSON (snake_case)
Map<String, dynamic> testTripSupabaseJson({
  String? id,
  String? userId,
}) =>
    {
      'id': id ?? 'test-trip-123',
      'user_id': userId ?? 'test-user-123',
      'destination_city': 'Salt Lake City',
      'destination_country': 'United States',
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'is_active': false,
      'notes': null,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
