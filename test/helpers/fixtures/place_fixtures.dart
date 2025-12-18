import 'package:fittravel/models/place_model.dart';

/// Test fixtures for PlaceModel

PlaceModel createTestPlace({
  String? id,
  String? userId,
  String? googlePlaceId,
  String? name,
  String? address,
  PlaceType? type,
  double? latitude,
  double? longitude,
  double? rating,
  bool? isVisited,
  DateTime? visitedAt,
  String? notes,
}) {
  return PlaceModel(
    id: id ?? 'test-place-123',
    userId: userId ?? 'test-user-123',
    googlePlaceId: googlePlaceId ?? 'google-place-abc123',
    name: name ?? 'Test Gym',
    address: address ?? '123 Main St, Salt Lake City, UT',
    type: type ?? PlaceType.gym,
    latitude: latitude ?? 40.7608,
    longitude: longitude ?? -111.8910,
    rating: rating ?? 4.5,
    isVisited: isVisited ?? false,
    visitedAt: visitedAt,
    notes: notes,
  );
}

/// Test gym place
PlaceModel get testGym => createTestPlace(
      id: 'gym-1',
      name: 'Iron Paradise Gym',
      type: PlaceType.gym,
      rating: 4.8,
    );

/// Test restaurant place
PlaceModel get testRestaurant => createTestPlace(
      id: 'restaurant-1',
      googlePlaceId: 'google-restaurant-xyz',
      name: 'Healthy Eats Cafe',
      address: '456 Wellness Ave, Salt Lake City, UT',
      type: PlaceType.restaurant,
      rating: 4.6,
    );

/// Visited place
PlaceModel get testVisitedPlace => createTestPlace(
      id: 'visited-1',
      name: 'CrossFit SLC',
      isVisited: true,
      visitedAt: DateTime.now().subtract(const Duration(days: 1)),
      notes: 'Great drop-in session!',
    );

/// Test place JSON (camelCase)
Map<String, dynamic> testPlaceJson({
  String? id,
  String? userId,
}) =>
    {
      'id': id ?? 'test-place-123',
      'userId': userId ?? 'test-user-123',
      'placeId': 'google-place-abc123',
      'name': 'Test Gym',
      'address': '123 Main St, Salt Lake City, UT',
      'placeType': 'gym',
      'latitude': 40.7608,
      'longitude': -111.8910,
      'rating': 4.5,
      'isVisited': false,
      'visitedAt': null,
      'notes': null,
    };

/// Test place Supabase JSON (snake_case)
Map<String, dynamic> testPlaceSupabaseJson({
  String? id,
  String? userId,
}) =>
    {
      'id': id ?? 'test-place-123',
      'user_id': userId ?? 'test-user-123',
      'place_id': 'google-place-abc123',
      'name': 'Test Gym',
      'address': '123 Main St, Salt Lake City, UT',
      'place_type': 'gym',
      'latitude': 40.7608,
      'longitude': -111.8910,
      'rating': 4.5,
      'is_visited': false,
      'visited_at': null,
      'notes': null,
      'created_at': '2024-01-01T00:00:00Z',
    };
