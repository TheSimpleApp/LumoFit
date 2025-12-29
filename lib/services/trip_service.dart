import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripService extends ChangeNotifier {
  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;
  // tripId -> itinerary items (cached locally)
  final Map<String, List<ItineraryItem>> _itineraries = {};
  StreamSubscription? _authSub;

  TripService();

  List<TripModel> get trips => _trips;
  List<TripModel> get upcomingTrips => _trips.where((t) => t.isUpcoming).toList();
  List<TripModel> get pastTrips => _trips.where((t) => t.isPast).toList();
  List<TripModel> get currentTrips => _trips.where((t) => t.isCurrent).toList();
  TripModel? get activeTrip {
    try {
      return _trips.firstWhere((t) => t.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Get coordinates of the active trip destination for map centering
  /// Returns null if no active trip or no coordinates set
  (double lat, double lng)? get activeTripCoordinates {
    final trip = activeTrip;
    if (trip?.destinationLatitude != null && trip?.destinationLongitude != null) {
      return (trip!.destinationLatitude!, trip.destinationLongitude!);
    }
    return null;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    // Ensure we listen to auth changes exactly once
    _authSub ??= SupabaseConfig.auth.onAuthStateChange.listen((event) async {
      debugPrint('TripService: auth state changed, reloading trips');
      await initialize();
    });

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('TripService.initialize: no auth user, clearing trips');
        _trips = [];
        _itineraries.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch trips with joined trip_places for savedPlaceIds
      final tripsData = await SupabaseConfig.client
          .from('trips')
          .select('*, trip_places(place_id)')
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      _trips = (tripsData as List).map((json) {
        final placeIds = (json['trip_places'] as List?)
                ?.map((tp) => tp['place_id'] as String)
                .toList() ??
            [];
        return TripModel.fromSupabaseJson(json, savedPlaceIds: placeIds);
      }).toList();

      // Load all itineraries for user's trips
      await _loadAllItineraries();
    } catch (e) {
      _error = 'Failed to load trips';
      debugPrint('TripService.initialize error: $e');
      _trips = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllItineraries() async {
    if (_trips.isEmpty) return;

    final tripIds = _trips.map((t) => t.id).toList();

    try {
      final items = await SupabaseConfig.client
          .from('itinerary_items')
          .select()
          .inFilter('trip_id', tripIds)
          .order('date')
          .order('start_time');

      _itineraries.clear();
      for (final item in items) {
        final tripId = item['trip_id'] as String;
        _itineraries.putIfAbsent(tripId, () => []);
        _itineraries[tripId]!.add(ItineraryItem.fromSupabaseJson(item));
      }
    } catch (e) {
      debugPrint('TripService._loadAllItineraries error: $e');
    }
  }

  Future<TripModel> createTrip({
    required String destinationCity,
    String? destinationCountry,
    double? destinationLatitude,
    double? destinationLongitude,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final data = {
        'user_id': userId,
        'destination_city': destinationCity,
        'destination_country': destinationCountry,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'notes': notes,
        'is_active': false,
      };

      final result = await SupabaseService.insert('trips', data);

      TripModel? trip;
      if (result.isNotEmpty) {
        trip = TripModel.fromSupabaseJson(result.first, savedPlaceIds: []);
        _trips.insert(0, trip);
        _error = null;
        notifyListeners();
      } else {
        // Some RLS setups allow insert but deny select on returning rows.
        // As a resilient fallback, reload trips from backend and try to find the new one.
        debugPrint('TripService.createTrip: insert returned empty, attempting fallback reload');
        await initialize();
        try {
          trip = _trips.firstWhere((t) =>
              t.userId == userId &&
              t.destinationCity.toLowerCase() == destinationCity.toLowerCase() &&
              t.startDate.year == startDate.year && t.startDate.month == startDate.month && t.startDate.day == startDate.day &&
              t.endDate.year == endDate.year && t.endDate.month == endDate.month && t.endDate.day == endDate.day);
        } catch (_) {
          throw Exception('Trip created but could not load it due to RLS');
        }
      }

      // Trigger async event fetching for this destination
      _fetchEventsForDestination(
        city: destinationCity,
        country: destinationCountry,
        startDate: startDate,
        endDate: endDate,
        latitude: destinationLatitude,
        longitude: destinationLongitude,
        tripId: trip.id,
      );

      return trip;
    } catch (e) {
      _error = 'Failed to create trip';
      debugPrint('TripService.createTrip error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTrip(TripModel trip) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Check if destination or dates changed (need to fetch new events)
      final index = _trips.indexWhere((t) => t.id == trip.id);
      final oldTrip = index >= 0 ? _trips[index] : null;
      final destinationChanged = oldTrip != null && (
        oldTrip.destinationCity != trip.destinationCity ||
        oldTrip.startDate != trip.startDate ||
        oldTrip.endDate != trip.endDate
      );

      await SupabaseService.update(
        'trips',
        trip.toSupabaseJson(userId),
        filters: {'id': trip.id},
      );

      if (index >= 0) {
        _trips[index] = trip.copyWith(updatedAt: DateTime.now());
        _error = null;
        notifyListeners();
      }

      // If destination or dates changed, fetch new events
      if (destinationChanged) {
        _fetchEventsForDestination(
          city: trip.destinationCity,
          country: trip.destinationCountry,
          startDate: trip.startDate,
          endDate: trip.endDate,
          latitude: trip.destinationLatitude,
          longitude: trip.destinationLongitude,
          tripId: trip.id,
        );
      }
    } catch (e) {
      _error = 'Failed to update trip';
      debugPrint('TripService.updateTrip error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      // Delete trip (cascade will handle trip_places and itinerary_items)
      await SupabaseService.delete('trips', filters: {'id': tripId});

      _trips.removeWhere((t) => t.id == tripId);
      _itineraries.remove(tripId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete trip';
      debugPrint('TripService.deleteTrip error: $e');
      notifyListeners();
    }
  }

  Future<void> setActiveTrip(String tripId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // First, deactivate all trips for this user
      await SupabaseConfig.client
          .from('trips')
          .update({'is_active': false})
          .eq('user_id', userId);

      // Then activate the selected trip
      await SupabaseConfig.client
          .from('trips')
          .update({'is_active': true})
          .eq('id', tripId);

      // Update local state
      for (int i = 0; i < _trips.length; i++) {
        _trips[i] = _trips[i].copyWith(isActive: _trips[i].id == tripId);
      }
      _error = null;
      notifyListeners();

      // If the trip has no coordinates, geocode the destination
      final trip = getTripById(tripId);
      if (trip != null &&
          trip.destinationLatitude == null &&
          trip.destinationLongitude == null) {
        await _geocodeTripDestination(trip);
      }

      // Fetch events for the active trip destination
      // This ensures events are fetched for any trip, including previously created ones
      if (trip != null) {
        _fetchEventsForDestination(
          city: trip.destinationCity,
          country: trip.destinationCountry,
          startDate: trip.startDate,
          endDate: trip.endDate,
          latitude: trip.destinationLatitude,
          longitude: trip.destinationLongitude,
          tripId: trip.id,
        );
      }
    } catch (e) {
      _error = 'Failed to set active trip';
      debugPrint('TripService.setActiveTrip error: $e');
      notifyListeners();
    }
  }

  /// Trigger async event fetching for a destination
  /// This calls the edge function to fetch fitness events using AI
  Future<void> _fetchEventsForDestination({
    required String city,
    String? country,
    required DateTime startDate,
    required DateTime endDate,
    double? latitude,
    double? longitude,
    String? tripId,
  }) async {
    try {
      debugPrint('TripService: Fetching events for $city...');
      final FunctionsClient functions = SupabaseConfig.client.functions;

      // Fire and forget - don't await, let it run in background
      functions.invoke(
        'fetch_destination_events',
        body: {
          'city': city,
          'country': country,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (tripId != null) 'trip_id': tripId,
          'max_events': 50,
        },
      ).then((response) {
        debugPrint('TripService: Event fetch response: ${response.data}');
      }).catchError((e) {
        debugPrint('TripService: Event fetch error (non-blocking): $e');
      });
    } catch (e) {
      // Non-fatal: don't fail trip creation if event fetching fails
      debugPrint('TripService._fetchEventsForDestination error: $e');
    }
  }

  /// Geocode a trip's destination city and update the trip with coordinates
  Future<void> _geocodeTripDestination(TripModel trip) async {
    try {
      final placesService = GooglePlacesService();
      final coords = await placesService.geocodeCity(
        trip.destinationCity,
        country: trip.destinationCountry,
      );

      if (coords != null) {
        final (lat, lng) = coords;

        // Update in database
        await SupabaseConfig.client.from('trips').update({
          'destination_latitude': lat,
          'destination_longitude': lng,
        }).eq('id', trip.id);

        // Update local state
        final index = _trips.indexWhere((t) => t.id == trip.id);
        if (index >= 0) {
          _trips[index] = _trips[index].copyWith(
            destinationLatitude: lat,
            destinationLongitude: lng,
          );
          notifyListeners();
          debugPrint(
              'TripService: Geocoded ${trip.destinationCity} to ($lat, $lng)');
        }
      }
    } catch (e) {
      debugPrint('TripService._geocodeTripDestination error: $e');
      // Non-fatal: trip still works without coordinates
    }
  }

  Future<void> addPlaceToTrip(String tripId, String placeId) async {
    try {
      // Check if already exists
      final existing = await SupabaseService.selectSingle(
        'trip_places',
        filters: {'trip_id': tripId, 'place_id': placeId},
      );

      if (existing != null) return;

      // Insert into junction table
      await SupabaseService.insert('trip_places', {
        'trip_id': tripId,
        'place_id': placeId,
      });

      // Update local state
      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index >= 0 && !_trips[index].savedPlaceIds.contains(placeId)) {
        _trips[index] = _trips[index].copyWith(
          savedPlaceIds: [..._trips[index].savedPlaceIds, placeId],
        );
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add place to trip';
      debugPrint('TripService.addPlaceToTrip error: $e');
      notifyListeners();
    }
  }

  Future<void> removePlaceFromTrip(String tripId, String placeId) async {
    try {
      await SupabaseConfig.client
          .from('trip_places')
          .delete()
          .eq('trip_id', tripId)
          .eq('place_id', placeId);

      // Update local state
      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index >= 0) {
        _trips[index] = _trips[index].copyWith(
          savedPlaceIds: _trips[index].savedPlaceIds.where((id) => id != placeId).toList(),
        );
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove place from trip';
      debugPrint('TripService.removePlaceFromTrip error: $e');
      notifyListeners();
    }
  }

  TripModel? getTripById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TripModel> searchTrips(String query) {
    final lowerQuery = query.toLowerCase();
    return _trips.where((t) {
      return t.destinationCity.toLowerCase().contains(lowerQuery) ||
          (t.destinationCountry?.toLowerCase().contains(lowerQuery) ?? false) ||
          (t.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ---------- Itinerary APIs ----------

  List<ItineraryItem> getItinerary(String tripId, {DateTime? forDate}) {
    final items = List<ItineraryItem>.from(_itineraries[tripId] ?? const []);
    if (forDate == null) return items..sort(_compareItems);
    final d = DateTime(forDate.year, forDate.month, forDate.day);
    return items
      ..retainWhere((it) => _isSameDay(it.date, d))
      ..sort(_compareItems);
  }

  Future<void> addItineraryItem(String tripId, ItineraryItem item) async {
    try {
      final data = item.toSupabaseJson(tripId);
      final result = await SupabaseService.insert('itinerary_items', data);

      if (result.isNotEmpty) {
        final newItem = ItineraryItem.fromSupabaseJson(result.first);
        final list = _itineraries.putIfAbsent(tripId, () => []);
        list.add(newItem);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add itinerary item';
      debugPrint('TripService.addItineraryItem error: $e');
      notifyListeners();
    }
  }

  Future<void> updateItineraryItem(String tripId, ItineraryItem item) async {
    try {
      await SupabaseService.update(
        'itinerary_items',
        item.toSupabaseJson(tripId),
        filters: {'id': item.id},
      );

      final list = _itineraries[tripId];
      if (list != null) {
        final idx = list.indexWhere((e) => e.id == item.id);
        if (idx >= 0) list[idx] = item;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update itinerary item';
      debugPrint('TripService.updateItineraryItem error: $e');
      notifyListeners();
    }
  }

  Future<void> removeItineraryItem(String tripId, String itemId) async {
    try {
      await SupabaseService.delete('itinerary_items', filters: {'id': itemId});

      final list = _itineraries[tripId];
      if (list != null) {
        list.removeWhere((e) => e.id == itemId);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove itinerary item';
      debugPrint('TripService.removeItineraryItem error: $e');
      notifyListeners();
    }
  }

  Future<void> reorderItinerary(String tripId, List<ItineraryItem> newOrder) async {
    // For now, just update local state - full reorder would need order column in DB
    _itineraries[tripId] = List<ItineraryItem>.from(newOrder);
    notifyListeners();
  }

  int _compareItems(ItineraryItem a, ItineraryItem b) {
    final at = a.startTime ?? '99:99';
    final bt = b.startTime ?? '99:99';
    final cmpDate = a.date.compareTo(b.date);
    if (cmpDate != 0) return cmpDate;
    return at.compareTo(bt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Clear local state (called on logout)
  void clearTrips() {
    _trips = [];
    _itineraries.clear();
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
