import 'package:flutter_test/flutter_test.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/models/trip_model.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/services/storage_service.dart';
import 'package:fittravel/services/event_service.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/services/user_trip_events_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock Classes
// ─────────────────────────────────────────────────────────────────────────────

/// Mock StorageService for testing
class MockStorageService extends StorageService {
  final Map<String, dynamic> _stringData = {};
  final Map<String, List<Map<String, dynamic>>> _jsonListData = {};

  MockStorageService._() : super._();

  static MockStorageService create() {
    return MockStorageService._();
  }

  @override
  Future<bool> setString(String key, String value) async {
    _stringData[key] = value;
    return true;
  }

  @override
  String? getString(String key) {
    return _stringData[key] as String?;
  }

  @override
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    _jsonListData[key] = value;
    return true;
  }

  @override
  List<Map<String, dynamic>>? getJsonList(String key) {
    return _jsonListData[key];
  }

  @override
  Future<bool> remove(String key) async {
    _stringData.remove(key);
    _jsonListData.remove(key);
    return true;
  }

  @override
  bool containsKey(String key) {
    return _stringData.containsKey(key) || _jsonListData.containsKey(key);
  }

  void clearAll() {
    _stringData.clear();
    _jsonListData.clear();
  }

  /// Helper to set cached events for testing
  void setCachedEvents(String tripId, List<EventModel> events) {
    _jsonListData['${StorageKeys.tripEvents}_$tripId'] =
        events.map((e) => e.toJson()).toList();
  }

  /// Helper to set cache timestamp for testing
  void setCacheTimestamp(String tripId, DateTime timestamp) {
    _stringData['${StorageKeys.tripEvents}_${tripId}_updated'] =
        timestamp.toIso8601String();
  }
}

/// Mock EventService for testing
class MockEventService extends EventService {
  List<EventModel> _mockEvents = [];
  bool _shouldFail = false;
  int fetchCallCount = 0;

  MockEventService(MockStorageService storage) : super(storage);

  void setMockEvents(List<EventModel> events) {
    _mockEvents = events;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<List<EventModel>> fetchExternalEvents({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    int limit = 50,
  }) async {
    fetchCallCount++;
    if (_shouldFail) {
      throw Exception('Mock API failure');
    }
    return _mockEvents;
  }

  void reset() {
    _mockEvents = [];
    _shouldFail = false;
    fetchCallCount = 0;
  }
}

/// Mock TripService for testing
class MockTripService extends TripService {
  TripModel? _mockActiveTrip;
  List<TripModel> _mockUpcomingTrips = [];
  List<TripModel> _mockCurrentTrips = [];
  final Map<String, TripModel> _tripMap = {};

  MockTripService(MockStorageService storage) : super(storage);

  void setMockActiveTrip(TripModel? trip) {
    _mockActiveTrip = trip;
    if (trip != null) {
      _tripMap[trip.id] = trip;
    }
  }

  void setMockUpcomingTrips(List<TripModel> trips) {
    _mockUpcomingTrips = trips;
    for (final trip in trips) {
      _tripMap[trip.id] = trip;
    }
  }

  void setMockCurrentTrips(List<TripModel> trips) {
    _mockCurrentTrips = trips;
    for (final trip in trips) {
      _tripMap[trip.id] = trip;
    }
  }

  @override
  TripModel? get activeTrip => _mockActiveTrip;

  @override
  List<TripModel> get upcomingTrips => _mockUpcomingTrips;

  @override
  List<TripModel> get currentTrips => _mockCurrentTrips;

  @override
  TripModel? getTripById(String id) => _tripMap[id];

  void reset() {
    _mockActiveTrip = null;
    _mockUpcomingTrips = [];
    _mockCurrentTrips = [];
    _tripMap.clear();
  }
}

/// Mock UserService for testing
class MockUserService extends UserService {
  UserModel? _mockUser;

  MockUserService(MockStorageService storage) : super(storage);

  void setMockUser(UserModel? user) {
    _mockUser = user;
  }

  @override
  UserModel? get currentUser => _mockUser;

  void reset() {
    _mockUser = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Fixtures
// ─────────────────────────────────────────────────────────────────────────────

TripModel createTestTrip({
  String id = 'test-trip-1',
  String destinationCity = 'Salt Lake City',
  bool isActive = true,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final now = DateTime.now();
  return TripModel(
    id: id,
    userId: 'test-user',
    destinationCity: destinationCity,
    startDate: startDate ?? now.subtract(const Duration(days: 2)),
    endDate: endDate ?? now.add(const Duration(days: 5)),
    isActive: isActive,
  );
}

TripModel createUpcomingTrip({
  String id = 'upcoming-trip-1',
  String destinationCity = 'Denver',
}) {
  final now = DateTime.now();
  return TripModel(
    id: id,
    userId: 'test-user',
    destinationCity: destinationCity,
    startDate: now.add(const Duration(days: 14)),
    endDate: now.add(const Duration(days: 21)),
    isActive: false,
  );
}

EventModel createTestEvent({
  String id = 'event-1',
  String title = 'Test Event',
  DateTime? start,
}) {
  return EventModel(
    id: id,
    title: title,
    category: EventCategory.running,
    start: start ?? DateTime.now().add(const Duration(days: 1)),
    venueName: 'Test Venue',
  );
}

List<EventModel> createTestEventList(int count, {String prefix = 'event'}) {
  return List.generate(
    count,
    (i) => createTestEvent(
      id: '$prefix-$i',
      title: 'Event ${i + 1}',
    ),
  );
}

UserModel createTestUser() {
  return UserModel(
    id: 'test-user',
    displayName: 'Test User',
    email: 'test@example.com',
    homeCity: 'Salt Lake City',
    fitnessLevel: FitnessLevel.intermediate,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockStorageService mockStorage;
  late MockEventService mockEventService;
  late MockTripService mockTripService;
  late MockUserService mockUserService;
  late UserTripEventsLoader loader;

  setUp(() {
    mockStorage = MockStorageService.create();
    mockEventService = MockEventService(mockStorage);
    mockTripService = MockTripService(mockStorage);
    mockUserService = MockUserService(mockStorage);

    loader = UserTripEventsLoader(
      storage: mockStorage,
      eventService: mockEventService,
      tripService: mockTripService,
      userService: mockUserService,
    );
  });

  tearDown(() {
    mockStorage.clearAll();
    mockEventService.reset();
    mockTripService.reset();
    mockUserService.reset();
  });

  group('UserTripEventsLoader - Initialization', () {
    test('initializes with dependencies correctly', () {
      expect(loader.isLoading, isFalse);
      expect(loader.isRefreshing, isFalse);
      expect(loader.lastError, isNull);
      expect(loader.allTripEvents, isEmpty);
    });

    test('exposes service references correctly', () {
      expect(loader.userService, same(mockUserService));
      expect(loader.tripService, same(mockTripService));
      expect(loader.eventService, same(mockEventService));
    });

    test('initialize sets isLoading during execution', () async {
      bool wasLoading = false;
      loader.addListener(() {
        if (loader.isLoading) wasLoading = true;
      });

      await loader.initialize();

      expect(wasLoading, isTrue);
      expect(loader.isLoading, isFalse);
    });

    test('initialize loads cached events for active trip', () async {
      final trip = createTestTrip();
      final events = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now());

      await loader.initialize();

      expect(loader.hasEventsForTrip(trip.id), isTrue);
      expect(loader.getEventsForTrip(trip.id).length, equals(3));
    });

    test('initialize loads cached events for upcoming trips', () async {
      final upcomingTrip = createUpcomingTrip();
      final events = createTestEventList(2);

      mockTripService.setMockUpcomingTrips([upcomingTrip]);
      mockStorage.setCachedEvents(upcomingTrip.id, events);
      mockStorage.setCacheTimestamp(upcomingTrip.id, DateTime.now());

      await loader.initialize();

      expect(loader.hasEventsForTrip(upcomingTrip.id), isTrue);
      expect(loader.getEventsForTrip(upcomingTrip.id).length, equals(2));
    });

    test('initialize handles missing cached events gracefully', () async {
      final trip = createTestTrip();
      mockTripService.setMockActiveTrip(trip);
      // No cached events set

      await loader.initialize();

      expect(loader.hasEventsForTrip(trip.id), isFalse);
      expect(loader.getEventsForTrip(trip.id), isEmpty);
      expect(loader.lastError, isNull);
    });
  });

  group('UserTripEventsLoader - loadEventsForTrip', () {
    test('returns cached data when cache is valid', () async {
      final trip = createTestTrip(isActive: true);
      final cachedEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, cachedEvents);
      // Set recent cache timestamp (within 1 hour for active trips)
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(minutes: 30)));

      // Load cached events first via initialize
      await loader.initialize();

      // Now load for trip
      final events = await loader.loadEventsForTrip(trip);

      expect(events.length, equals(3));
      expect(mockEventService.fetchCallCount, equals(0)); // Should not call API
    });

    test('fetches fresh data when cache is expired for active trip', () async {
      final trip = createTestTrip(isActive: true);
      final freshEvents = createTestEventList(5, prefix: 'fresh');

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(freshEvents);
      // Set old cache timestamp (more than 1 hour for active trips)
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(hours: 2)));

      await loader.initialize();
      final events = await loader.loadEventsForTrip(trip);

      expect(events.length, equals(5));
      expect(mockEventService.fetchCallCount, equals(1));
    });

    test('fetches fresh data when cache is expired for upcoming trip', () async {
      final trip = createUpcomingTrip();
      final freshEvents = createTestEventList(4, prefix: 'fresh');

      mockTripService.setMockUpcomingTrips([trip]);
      mockEventService.setMockEvents(freshEvents);
      // Set old cache timestamp (more than 24 hours for upcoming trips)
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(hours: 25)));

      await loader.initialize();
      final events = await loader.loadEventsForTrip(trip);

      expect(events.length, equals(4));
      expect(mockEventService.fetchCallCount, equals(1));
    });

    test('fetches fresh data when no cache exists', () async {
      final trip = createTestTrip();
      final freshEvents = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(freshEvents);
      // No cache set

      await loader.initialize();
      final events = await loader.loadEventsForTrip(trip);

      expect(events.length, equals(2));
      expect(mockEventService.fetchCallCount, equals(1));
    });

    test('caches fetched events after successful API call', () async {
      final trip = createTestTrip();
      final freshEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(freshEvents);

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Verify events are cached in memory
      expect(loader.getEventsForTrip(trip.id).length, equals(3));

      // Verify events are cached in storage
      final storedEvents = mockStorage.getJsonList('${StorageKeys.tripEvents}_${trip.id}');
      expect(storedEvents, isNotNull);
      expect(storedEvents!.length, equals(3));
    });

    test('notifies listeners when new events are loaded', () async {
      final trip = createTestTrip();
      final freshEvents = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(freshEvents);

      int notifyCount = 0;
      loader.addListener(() {
        notifyCount++;
      });

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Should notify: init start, init end, and events loaded
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('UserTripEventsLoader - Error Handling', () {
    test('returns cached data on API failure', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, cachedEvents);
      mockEventService.setShouldFail(true);

      // Force load cached events
      await loader.initialize();

      // Now cause API to fail, but we still have stale cache
      final events = await loader.loadEventsForTrip(trip);

      expect(events.length, equals(3)); // Returns cached events
    });

    test('returns empty list on API failure with no cache', () async {
      final trip = createTestTrip();

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setShouldFail(true);
      // No cache

      await loader.initialize();
      final events = await loader.loadEventsForTrip(trip);

      expect(events, isEmpty); // Fail-open: returns empty list
    });

    test('does not crash when initialize encounters errors', () async {
      // Simulate an error scenario by having no trips
      mockTripService.setMockActiveTrip(null);

      // Should not throw
      await loader.initialize();

      expect(loader.isLoading, isFalse);
      expect(loader.allTripEvents, isEmpty);
    });

    test('keeps existing cache on empty API response', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, cachedEvents);
      mockEventService.setMockEvents([]); // Empty response

      await loader.initialize();
      final events = await loader.loadEventsForTrip(trip);

      // Should keep cached data when API returns empty
      expect(events.length, equals(3));
    });
  });

  group('UserTripEventsLoader - Handle Empty Trips', () {
    test('returns empty events map when no trips exist', () async {
      mockTripService.setMockActiveTrip(null);
      mockTripService.setMockUpcomingTrips([]);

      await loader.initialize();
      final results = await loader.loadAllTripEvents();

      expect(results, isEmpty);
    });

    test('getEventsForTrip returns empty list for unknown trip', () {
      final events = loader.getEventsForTrip('non-existent-trip');
      expect(events, isEmpty);
    });

    test('hasEventsForTrip returns false for unknown trip', () {
      expect(loader.hasEventsForTrip('non-existent-trip'), isFalse);
    });
  });

  group('UserTripEventsLoader - Cache Invalidation', () {
    test('invalidateCache clears specific trip cache', () async {
      final trip = createTestTrip();
      final events = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now());

      await loader.initialize();
      expect(loader.hasEventsForTrip(trip.id), isTrue);

      await loader.invalidateCache(trip.id);

      expect(loader.hasEventsForTrip(trip.id), isFalse);
      expect(mockStorage.containsKey('${StorageKeys.tripEvents}_${trip.id}'), isFalse);
    });

    test('invalidateCache notifies listeners', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);

      await loader.initialize();

      bool notified = false;
      loader.addListener(() {
        notified = true;
      });

      await loader.invalidateCache(trip.id);

      expect(notified, isTrue);
    });

    test('invalidateAllCache clears all trip caches', () async {
      final trip1 = createTestTrip(id: 'trip-1');
      final trip2 = createUpcomingTrip(id: 'trip-2');
      final events1 = createTestEventList(2, prefix: 'trip1');
      final events2 = createTestEventList(3, prefix: 'trip2');

      mockTripService.setMockActiveTrip(trip1);
      mockTripService.setMockUpcomingTrips([trip2]);
      mockStorage.setCachedEvents(trip1.id, events1);
      mockStorage.setCachedEvents(trip2.id, events2);
      mockStorage.setCacheTimestamp(trip1.id, DateTime.now());
      mockStorage.setCacheTimestamp(trip2.id, DateTime.now());

      await loader.initialize();
      expect(loader.hasEventsForTrip(trip1.id), isTrue);
      expect(loader.hasEventsForTrip(trip2.id), isTrue);

      await loader.invalidateAllCache();

      expect(loader.hasEventsForTrip(trip1.id), isFalse);
      expect(loader.hasEventsForTrip(trip2.id), isFalse);
    });
  });

  group('UserTripEventsLoader - loadAllTripEvents', () {
    test('loads events for all active and upcoming trips', () async {
      final activeTrip = createTestTrip(id: 'active-trip');
      final upcomingTrip = createUpcomingTrip(id: 'upcoming-trip');
      final events1 = createTestEventList(2, prefix: 'active');
      final events2 = createTestEventList(3, prefix: 'upcoming');

      mockTripService.setMockActiveTrip(activeTrip);
      mockTripService.setMockUpcomingTrips([upcomingTrip]);

      // First call returns events1, second returns events2
      int callCount = 0;
      mockEventService.setMockEvents(events1);

      await loader.initialize();

      // For loadAllTripEvents, set up events so each trip gets different events
      mockEventService.setMockEvents([...events1, ...events2]);

      final results = await loader.loadAllTripEvents();

      expect(results.containsKey(activeTrip.id), isTrue);
      expect(results.containsKey(upcomingTrip.id), isTrue);
    });

    test('sets isRefreshing during loadAllTripEvents', () async {
      final trip = createTestTrip();
      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(createTestEventList(1));

      bool wasRefreshing = false;
      loader.addListener(() {
        if (loader.isRefreshing) wasRefreshing = true;
      });

      await loader.initialize();
      await loader.loadAllTripEvents();

      expect(wasRefreshing, isTrue);
      expect(loader.isRefreshing, isFalse); // Should be false after completion
    });

    test('continues loading other trips even if one fails', () async {
      final trip1 = createTestTrip(id: 'trip-1');
      final trip2 = createUpcomingTrip(id: 'trip-2');
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip1);
      mockTripService.setMockUpcomingTrips([trip2]);
      mockStorage.setCachedEvents(trip2.id, events);
      mockStorage.setCacheTimestamp(trip2.id, DateTime.now());

      // First trip will fail (no cached events), second has cached events
      await loader.initialize();

      // trip2 should have cached events, trip1 should be empty
      final results = await loader.loadAllTripEvents();

      expect(results.containsKey(trip1.id), isTrue);
      expect(results.containsKey(trip2.id), isTrue);
      expect(results[trip2.id]!.length, equals(2)); // From cache
    });
  });

  group('UserTripEventsLoader - refreshEventsForTrip', () {
    test('forces fresh fetch ignoring cache', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(2, prefix: 'cached');
      final freshEvents = createTestEventList(4, prefix: 'fresh');

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, cachedEvents);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now()); // Fresh cache
      mockEventService.setMockEvents(freshEvents);

      await loader.initialize();

      // Even with fresh cache, refresh should fetch new data
      final events = await loader.refreshEventsForTrip(trip.id);

      expect(events.length, equals(4));
      expect(mockEventService.fetchCallCount, equals(1));
    });

    test('sets isRefreshing during refresh', () async {
      final trip = createTestTrip();
      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(createTestEventList(1));

      bool wasRefreshing = false;
      loader.addListener(() {
        if (loader.isRefreshing) wasRefreshing = true;
      });

      await loader.initialize();
      await loader.refreshEventsForTrip(trip.id);

      expect(wasRefreshing, isTrue);
      expect(loader.isRefreshing, isFalse);
    });

    test('returns cached data on refresh failure', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, cachedEvents);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now());
      mockEventService.setShouldFail(true);

      await loader.initialize();
      final events = await loader.refreshEventsForTrip(trip.id);

      expect(events.length, equals(3)); // Returns cached on failure
    });

    test('returns empty list when trip not found', () async {
      mockTripService.setMockActiveTrip(null);

      await loader.initialize();
      final events = await loader.refreshEventsForTrip('non-existent-trip');

      expect(events, isEmpty);
    });

    test('sets lastError on refresh failure', () async {
      final trip = createTestTrip();
      mockTripService.setMockActiveTrip(trip);
      mockEventService.setShouldFail(true);

      await loader.initialize();
      await loader.refreshEventsForTrip(trip.id);

      expect(loader.lastError, isNotNull);
      expect(loader.lastError, contains('Failed to refresh'));
    });
  });

  group('UserTripEventsLoader - Cache Validation', () {
    test('isCacheValid returns true for fresh active trip cache', () async {
      final trip = createTestTrip(isActive: true);
      final events = createTestEventList(1);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(minutes: 30)));

      await loader.initialize();

      expect(loader.isCacheValid(trip.id), isTrue);
    });

    test('isCacheValid returns false for expired active trip cache', () async {
      final trip = createTestTrip(isActive: true);
      final events = createTestEventList(1);

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(hours: 2)));

      await loader.initialize();

      expect(loader.isCacheValid(trip.id), isFalse);
    });

    test('isCacheValid returns true for fresh upcoming trip cache', () async {
      final trip = createUpcomingTrip();
      final events = createTestEventList(1);

      mockTripService.setMockUpcomingTrips([trip]);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(hours: 12)));

      await loader.initialize();

      expect(loader.isCacheValid(trip.id), isTrue);
    });

    test('isCacheValid returns false for expired upcoming trip cache', () async {
      final trip = createUpcomingTrip();
      final events = createTestEventList(1);

      mockTripService.setMockUpcomingTrips([trip]);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, DateTime.now().subtract(const Duration(hours: 25)));

      await loader.initialize();

      expect(loader.isCacheValid(trip.id), isFalse);
    });

    test('getCacheAge returns correct duration', () async {
      final trip = createTestTrip();
      final events = createTestEventList(1);
      final cacheTime = DateTime.now().subtract(const Duration(minutes: 45));

      mockTripService.setMockActiveTrip(trip);
      mockStorage.setCachedEvents(trip.id, events);
      mockStorage.setCacheTimestamp(trip.id, cacheTime);

      await loader.initialize();

      final age = loader.getCacheAge(trip.id);
      expect(age, isNotNull);
      expect(age!.inMinutes, closeTo(45, 1)); // Allow 1 minute tolerance
    });

    test('getCacheAge returns null for unknown trip', () {
      final age = loader.getCacheAge('unknown-trip');
      expect(age, isNull);
    });
  });

  group('UserTripEventsLoader - Static Constants', () {
    test('has correct default radius', () {
      expect(UserTripEventsLoader.defaultRadiusKm, equals(50.0));
    });

    test('has correct cache TTL for active trips', () {
      expect(UserTripEventsLoader.activeTripCacheTtl, equals(const Duration(hours: 1)));
    });

    test('has correct cache TTL for upcoming trips', () {
      expect(UserTripEventsLoader.upcomingTripCacheTtl, equals(const Duration(hours: 24)));
    });
  });
}
