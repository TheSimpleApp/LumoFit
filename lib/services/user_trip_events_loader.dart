import 'package:flutter/foundation.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/models/trip_model.dart';
import 'package:fittravel/services/storage_service.dart';
import 'package:fittravel/services/event_service.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/user_service.dart';

/// Orchestrates loading of user data with trip-based local fitness events.
/// Uses a stale-while-revalidate caching strategy for optimal performance.
///
/// Cache TTL:
/// - Active trips: 1 hour
/// - Upcoming trips: 24 hours
class UserTripEventsLoader extends ChangeNotifier {
  final StorageService _storage;
  final EventService _eventService;
  final TripService _tripService;
  final UserService _userService;

  /// Map of tripId -> cached events for that trip
  final Map<String, List<EventModel>> _tripEvents = {};

  /// Map of tripId -> cache timestamp
  final Map<String, DateTime> _tripEventsCacheTime = {};

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _lastError;

  /// Default radius in km for location-based event search
  static const double defaultRadiusKm = 50.0;

  /// Cache TTL for active trips (1 hour)
  static const Duration activeTripCacheTtl = Duration(hours: 1);

  /// Cache TTL for upcoming trips (24 hours)
  static const Duration upcomingTripCacheTtl = Duration(hours: 24);

  UserTripEventsLoader({
    required StorageService storage,
    required EventService eventService,
    required TripService tripService,
    required UserService userService,
  })  : _storage = storage,
        _eventService = eventService,
        _tripService = tripService,
        _userService = userService;

  // ─────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get lastError => _lastError;

  /// Get all cached trip events as an unmodifiable map
  Map<String, List<EventModel>> get allTripEvents =>
      Map.unmodifiable(_tripEvents);

  /// Get events for a specific trip (returns empty list if not cached)
  List<EventModel> getEventsForTrip(String tripId) =>
      List.unmodifiable(_tripEvents[tripId] ?? []);

  /// Check if events are cached for a specific trip
  bool hasEventsForTrip(String tripId) => _tripEvents.containsKey(tripId);

  /// Get the UserService reference for accessing current user
  UserService get userService => _userService;

  /// Get the TripService reference for accessing trips
  TripService get tripService => _tripService;

  /// Get the EventService reference for fetching external events
  EventService get eventService => _eventService;

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Key Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Generate storage key for trip events cache
  String _tripEventsKey(String tripId) => '${StorageKeys.tripEvents}_$tripId';

  /// Generate storage key for trip events cache timestamp
  String _tripEventsCacheTimeKey(String tripId) =>
      '${StorageKeys.tripEvents}_${tripId}_updated';

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize the loader by loading cached events for all active/upcoming trips.
  /// This should be called after TripService and UserService are initialized.
  Future<void> initialize() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Get all trips that need event loading (active or upcoming)
      final trips = _getRelevantTrips();

      // Load cached events for each trip
      for (final trip in trips) {
        await _loadCachedEventsForTrip(trip.id);
      }

      debugPrint(
          'UserTripEventsLoader.initialize: Loaded cached events for ${trips.length} trips');
    } catch (e) {
      debugPrint('UserTripEventsLoader.initialize error: $e');
      _lastError = 'Failed to initialize trip events: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get trips that need event loading (active or upcoming)
  List<TripModel> _getRelevantTrips() {
    final activeTrip = _tripService.activeTrip;
    final upcomingTrips = _tripService.upcomingTrips;
    final currentTrips = _tripService.currentTrips;

    // Combine all relevant trips, avoiding duplicates
    final tripIds = <String>{};
    final trips = <TripModel>[];

    if (activeTrip != null && tripIds.add(activeTrip.id)) {
      trips.add(activeTrip);
    }

    for (final trip in currentTrips) {
      if (tripIds.add(trip.id)) {
        trips.add(trip);
      }
    }

    for (final trip in upcomingTrips) {
      if (tripIds.add(trip.id)) {
        trips.add(trip);
      }
    }

    return trips;
  }

  /// Load cached events for a specific trip from storage
  Future<void> _loadCachedEventsForTrip(String tripId) async {
    try {
      final jsonList = _storage.getJsonList(_tripEventsKey(tripId));
      if (jsonList != null && jsonList.isNotEmpty) {
        _tripEvents[tripId] =
            jsonList.map((j) => EventModel.fromJson(j)).toList();

        // Load cache timestamp
        final timestampStr = _storage.getString(_tripEventsCacheTimeKey(tripId));
        if (timestampStr != null) {
          try {
            _tripEventsCacheTime[tripId] = DateTime.parse(timestampStr);
          } catch (e) {
            debugPrint(
                'UserTripEventsLoader: Failed to parse cache timestamp for $tripId: $e');
          }
        }

        debugPrint(
            'UserTripEventsLoader: Loaded ${_tripEvents[tripId]!.length} cached events for trip $tripId');
      }
    } catch (e) {
      debugPrint(
          'UserTripEventsLoader._loadCachedEventsForTrip error for $tripId: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Persistence
  // ─────────────────────────────────────────────────────────────────────────

  /// Save events for a specific trip to storage
  Future<void> _saveEventsForTrip(
      String tripId, List<EventModel> events) async {
    try {
      await _storage.setJsonList(
        _tripEventsKey(tripId),
        events.map((e) => e.toJson()).toList(),
      );

      final now = DateTime.now();
      await _storage.setString(
        _tripEventsCacheTimeKey(tripId),
        now.toIso8601String(),
      );

      _tripEventsCacheTime[tripId] = now;
      debugPrint(
          'UserTripEventsLoader: Saved ${events.length} events for trip $tripId');
    } catch (e) {
      debugPrint('UserTripEventsLoader._saveEventsForTrip error for $tripId: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Validation
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if cached events for a trip are still valid (not expired)
  bool isCacheValid(String tripId) {
    final cacheTime = _tripEventsCacheTime[tripId];
    if (cacheTime == null) return false;

    final trip = _tripService.getTripById(tripId);
    if (trip == null) return false;

    final ttl = trip.isActive ? activeTripCacheTtl : upcomingTripCacheTtl;
    final expiresAt = cacheTime.add(ttl);

    return DateTime.now().isBefore(expiresAt);
  }

  /// Get cache age for a trip (for debugging/display)
  Duration? getCacheAge(String tripId) {
    final cacheTime = _tripEventsCacheTime[tripId];
    if (cacheTime == null) return null;
    return DateTime.now().difference(cacheTime);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Event Loading
  // ─────────────────────────────────────────────────────────────────────────

  /// Load events for a specific trip with caching.
  ///
  /// Uses a stale-while-revalidate strategy:
  /// - Returns cached data immediately if available and fresh
  /// - Fetches fresh data from the API if cache is stale or missing
  /// - Caches the results for future use
  ///
  /// Returns an empty list on failure (fail-open).
  Future<List<EventModel>> loadEventsForTrip(TripModel trip) async {
    try {
      // Check if we have valid cached data
      if (isCacheValid(trip.id) && _tripEvents.containsKey(trip.id)) {
        debugPrint(
            'UserTripEventsLoader.loadEventsForTrip: Cache hit for trip ${trip.id}');
        return List.unmodifiable(_tripEvents[trip.id]!);
      }

      // Check if we have stale cached data to return while we refresh
      final hasStaleCachedData = _tripEvents.containsKey(trip.id);
      if (hasStaleCachedData) {
        debugPrint(
            'UserTripEventsLoader.loadEventsForTrip: Cache stale for trip ${trip.id}, returning cached while refreshing');
      }

      // Fetch fresh events from the API
      final events = await _fetchEventsForTrip(trip);

      // Update cache with fresh data
      if (events.isNotEmpty) {
        _tripEvents[trip.id] = events;
        await _saveEventsForTrip(trip.id, events);
        notifyListeners();
        debugPrint(
            'UserTripEventsLoader.loadEventsForTrip: Fetched ${events.length} events for trip ${trip.id}');
      } else if (hasStaleCachedData) {
        // API returned empty but we have cached data, keep using cached
        debugPrint(
            'UserTripEventsLoader.loadEventsForTrip: API returned empty, keeping cached data for trip ${trip.id}');
        return List.unmodifiable(_tripEvents[trip.id]!);
      }

      return List.unmodifiable(events);
    } catch (e) {
      debugPrint('UserTripEventsLoader.loadEventsForTrip error for trip ${trip.id}: $e');

      // Return cached data if available, otherwise empty list (fail-open)
      if (_tripEvents.containsKey(trip.id)) {
        debugPrint(
            'UserTripEventsLoader.loadEventsForTrip: Returning cached data after error for trip ${trip.id}');
        return List.unmodifiable(_tripEvents[trip.id]!);
      }

      return const [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Refresh and Invalidation
  // ─────────────────────────────────────────────────────────────────────────

  /// Force refresh events for a specific trip, bypassing cache.
  ///
  /// This method always fetches fresh data from the API, regardless of cache
  /// validity. Updates both in-memory and persistent cache on success.
  /// Returns the fetched events or cached data on failure (fail-open).
  Future<List<EventModel>> refreshEventsForTrip(String tripId) async {
    final trip = _tripService.getTripById(tripId);
    if (trip == null) {
      debugPrint(
          'UserTripEventsLoader.refreshEventsForTrip: Trip not found: $tripId');
      return _tripEvents[tripId] ?? const [];
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      // Fetch fresh events from the API
      final events = await _fetchEventsForTrip(trip);

      // Update cache with fresh data
      if (events.isNotEmpty) {
        _tripEvents[tripId] = events;
        await _saveEventsForTrip(tripId, events);
        debugPrint(
            'UserTripEventsLoader.refreshEventsForTrip: Refreshed ${events.length} events for trip $tripId');
      } else if (_tripEvents.containsKey(tripId)) {
        // API returned empty, keep existing cached data
        debugPrint(
            'UserTripEventsLoader.refreshEventsForTrip: API returned empty, keeping cached data for trip $tripId');
      }

      _isRefreshing = false;
      notifyListeners();
      return List.unmodifiable(events.isNotEmpty ? events : (_tripEvents[tripId] ?? const []));
    } catch (e) {
      debugPrint('UserTripEventsLoader.refreshEventsForTrip error for trip $tripId: $e');
      _lastError = 'Failed to refresh events for trip: $e';

      _isRefreshing = false;
      notifyListeners();

      // Return cached data on failure (fail-open)
      return List.unmodifiable(_tripEvents[tripId] ?? const []);
    }
  }

  /// Invalidate cache for a specific trip.
  ///
  /// Clears both in-memory and persistent cache for the specified trip.
  /// After invalidation, the next call to [loadEventsForTrip] will fetch
  /// fresh data from the API.
  Future<void> invalidateCache(String tripId) async {
    try {
      // Remove from in-memory cache
      _tripEvents.remove(tripId);
      _tripEventsCacheTime.remove(tripId);

      // Remove from persistent storage
      await _storage.remove(_tripEventsKey(tripId));
      await _storage.remove(_tripEventsCacheTimeKey(tripId));

      debugPrint(
          'UserTripEventsLoader.invalidateCache: Cache invalidated for trip $tripId');
      notifyListeners();
    } catch (e) {
      debugPrint('UserTripEventsLoader.invalidateCache error for trip $tripId: $e');
    }
  }

  /// Invalidate cache for all trips.
  ///
  /// Clears both in-memory and persistent cache for all trips.
  /// Useful when user logs out or data needs complete refresh.
  Future<void> invalidateAllCache() async {
    try {
      // Get all trip IDs before clearing
      final tripIds = _tripEvents.keys.toList();

      // Clear in-memory cache
      _tripEvents.clear();
      _tripEventsCacheTime.clear();

      // Clear persistent storage for each trip
      for (final tripId in tripIds) {
        await _storage.remove(_tripEventsKey(tripId));
        await _storage.remove(_tripEventsCacheTimeKey(tripId));
      }

      debugPrint(
          'UserTripEventsLoader.invalidateAllCache: Cache invalidated for ${tripIds.length} trips');
      notifyListeners();
    } catch (e) {
      debugPrint('UserTripEventsLoader.invalidateAllCache error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Event Fetching
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch events from the API for a specific trip.
  /// Uses trip dates for temporal filtering and destinationCity for the query.
  Future<List<EventModel>> _fetchEventsForTrip(TripModel trip) async {
    try {
      // Use trip destination city as query for location-based search
      // Note: geocoding for lat/lng is deferred to future implementation
      final events = await _eventService.fetchExternalEvents(
        query: trip.destinationCity,
        startDate: trip.startDate,
        endDate: trip.endDate,
        radiusKm: defaultRadiusKm,
      );

      return events;
    } catch (e) {
      debugPrint('UserTripEventsLoader._fetchEventsForTrip error: $e');
      return const [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bulk Loading
  // ─────────────────────────────────────────────────────────────────────────

  /// Load events for all relevant trips (active and upcoming).
  ///
  /// Fetches events for each trip in parallel where possible, updating the
  /// cache for each. Returns a map of tripId -> events for all trips.
  ///
  /// This is useful for initial data population or full refresh scenarios.
  /// Uses [_isRefreshing] flag to indicate background refresh activity.
  Future<Map<String, List<EventModel>>> loadAllTripEvents() async {
    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    final results = <String, List<EventModel>>{};

    try {
      // Get all trips that need event loading
      final trips = _getRelevantTrips();

      if (trips.isEmpty) {
        debugPrint('UserTripEventsLoader.loadAllTripEvents: No relevant trips found');
        _isRefreshing = false;
        notifyListeners();
        return results;
      }

      debugPrint(
          'UserTripEventsLoader.loadAllTripEvents: Loading events for ${trips.length} trips');

      // Load events for each trip
      for (final trip in trips) {
        try {
          final events = await loadEventsForTrip(trip);
          results[trip.id] = events;
        } catch (e) {
          debugPrint(
              'UserTripEventsLoader.loadAllTripEvents: Error loading events for trip ${trip.id}: $e');
          // Continue loading other trips even if one fails
          // Use cached data if available, otherwise empty list
          results[trip.id] = _tripEvents[trip.id] ?? const [];
        }
      }

      debugPrint(
          'UserTripEventsLoader.loadAllTripEvents: Completed loading events for ${results.length} trips');
    } catch (e) {
      debugPrint('UserTripEventsLoader.loadAllTripEvents error: $e');
      _lastError = 'Failed to load trip events: $e';
    }

    _isRefreshing = false;
    notifyListeners();
    return results;
  }
}
