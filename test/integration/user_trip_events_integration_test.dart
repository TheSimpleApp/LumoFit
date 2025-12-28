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
// Integration Test Mock Classes
// These mocks simulate real service behavior for integration testing
// ─────────────────────────────────────────────────────────────────────────────

/// Mock StorageService that uses in-memory storage for testing
/// Simulates real StorageService behavior without SharedPreferences dependency
class IntegrationMockStorageService extends StorageService {
  final Map<String, String> _stringData = {};
  final Map<String, List<String>> _stringListData = {};

  IntegrationMockStorageService._() : super._();

  static IntegrationMockStorageService create() {
    return IntegrationMockStorageService._();
  }

  @override
  Future<bool> setString(String key, String value) async {
    _stringData[key] = value;
    return true;
  }

  @override
  String? getString(String key) {
    return _stringData[key];
  }

  @override
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    _stringListData[key] = value.map((e) => e.toString()).toList();
    // Store as proper JSON for retrieval
    final List<String> jsonStrings = [];
    for (final item in value) {
      jsonStrings.add(_encodeJson(item));
    }
    _stringListData[key] = jsonStrings;
    return true;
  }

  @override
  List<Map<String, dynamic>>? getJsonList(String key) {
    final stringList = _stringListData[key];
    if (stringList == null) return null;

    final List<Map<String, dynamic>> result = [];
    for (final s in stringList) {
      try {
        result.add(_decodeJson(s));
      } catch (e) {
        // Skip corrupted entries
      }
    }
    return result;
  }

  @override
  Future<bool> remove(String key) async {
    _stringData.remove(key);
    _stringListData.remove(key);
    return true;
  }

  @override
  bool containsKey(String key) {
    return _stringData.containsKey(key) || _stringListData.containsKey(key);
  }

  void clearAll() {
    _stringData.clear();
    _stringListData.clear();
  }

  /// Get all stored keys (for debugging)
  Set<String> get allKeys => {..._stringData.keys, ..._stringListData.keys};

  /// Get raw string data (for verification)
  Map<String, String> get rawStringData => Map.unmodifiable(_stringData);

  /// Helper method to encode JSON as string
  String _encodeJson(Map<String, dynamic> json) {
    final buffer = StringBuffer('{');
    var first = true;
    json.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value == null) {
        buffer.write('null');
      } else if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is num || value is bool) {
        buffer.write(value);
      } else if (value is List) {
        buffer.write('[${value.map((e) => e is String ? '"$e"' : e).join(',')}]');
      } else {
        buffer.write('"$value"');
      }
    });
    buffer.write('}');
    return buffer.toString();
  }

  /// Helper method to decode JSON string
  Map<String, dynamic> _decodeJson(String s) {
    // Simple JSON parser for test data
    final map = <String, dynamic>{};
    if (!s.startsWith('{') || !s.endsWith('}')) return map;

    var content = s.substring(1, s.length - 1);
    var depth = 0;
    var inString = false;
    var keyStart = 0;
    var valueStart = 0;
    String? currentKey;

    for (var i = 0; i < content.length; i++) {
      final c = content[i];

      if (c == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (c == '{' || c == '[') depth++;
      if (c == '}' || c == ']') depth--;

      if (depth == 0 && c == ':' && currentKey == null) {
        final keyPart = content.substring(keyStart, i).trim();
        currentKey = keyPart.startsWith('"') && keyPart.endsWith('"')
            ? keyPart.substring(1, keyPart.length - 1)
            : keyPart;
        valueStart = i + 1;
      }

      if (depth == 0 && (c == ',' || i == content.length - 1)) {
        if (currentKey != null) {
          var valuePart = content.substring(valueStart, c == ',' ? i : i + 1).trim();
          map[currentKey] = _parseValue(valuePart);
          currentKey = null;
          keyStart = i + 1;
        }
      }
    }

    return map;
  }

  dynamic _parseValue(String s) {
    s = s.trim();
    if (s == 'null') return null;
    if (s == 'true') return true;
    if (s == 'false') return false;
    if (s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1).replaceAll('\\"', '"');
    }
    if (s.startsWith('[') && s.endsWith(']')) {
      // Simple array parsing
      final inner = s.substring(1, s.length - 1);
      if (inner.isEmpty) return <String>[];
      return inner.split(',').map((e) => _parseValue(e.trim())).toList();
    }
    final numValue = num.tryParse(s);
    if (numValue != null) return numValue;
    return s;
  }
}

/// Mock EventService for integration testing
class IntegrationMockEventService extends EventService {
  List<EventModel> _mockEvents = [];
  bool _shouldFail = false;
  int _fetchCallCount = 0;
  Duration _fetchDelay = Duration.zero;

  IntegrationMockEventService(IntegrationMockStorageService storage)
      : super(storage);

  int get fetchCallCount => _fetchCallCount;

  void setMockEvents(List<EventModel> events) {
    _mockEvents = events;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  void setFetchDelay(Duration delay) {
    _fetchDelay = delay;
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
    _fetchCallCount++;

    if (_fetchDelay > Duration.zero) {
      await Future.delayed(_fetchDelay);
    }

    if (_shouldFail) {
      throw Exception('Mock API failure');
    }
    return _mockEvents;
  }

  void reset() {
    _mockEvents = [];
    _shouldFail = false;
    _fetchCallCount = 0;
    _fetchDelay = Duration.zero;
  }
}

/// Mock TripService for integration testing
class IntegrationMockTripService extends TripService {
  TripModel? _mockActiveTrip;
  List<TripModel> _mockUpcomingTrips = [];
  List<TripModel> _mockCurrentTrips = [];
  final Map<String, TripModel> _tripMap = {};

  IntegrationMockTripService(IntegrationMockStorageService storage)
      : super(storage);

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

  void addTrip(TripModel trip) {
    _tripMap[trip.id] = trip;
    if (trip.isActive) {
      _mockActiveTrip = trip;
    } else if (trip.isUpcoming) {
      _mockUpcomingTrips = [..._mockUpcomingTrips, trip];
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

/// Mock UserService for integration testing
class IntegrationMockUserService extends UserService {
  UserModel? _mockUser;

  IntegrationMockUserService(IntegrationMockStorageService storage)
      : super(storage);

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
// Integration Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late IntegrationMockStorageService mockStorage;
  late IntegrationMockEventService mockEventService;
  late IntegrationMockTripService mockTripService;
  late IntegrationMockUserService mockUserService;

  setUp(() {
    mockStorage = IntegrationMockStorageService.create();
    mockEventService = IntegrationMockEventService(mockStorage);
    mockTripService = IntegrationMockTripService(mockStorage);
    mockUserService = IntegrationMockUserService(mockStorage);
  });

  tearDown(() {
    mockStorage.clearAll();
    mockEventService.reset();
    mockTripService.reset();
    mockUserService.reset();
  });

  group('Integration: StorageService + UserTripEventsLoader', () {
    test('events are persisted to storage after fetch', () async {
      final trip = createTestTrip();
      final events = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Verify events are stored in storage
      final storedEvents =
          mockStorage.getJsonList('${StorageKeys.tripEvents}_${trip.id}');
      expect(storedEvents, isNotNull);
      expect(storedEvents!.length, equals(3));

      // Verify cache timestamp is stored
      final timestamp =
          mockStorage.getString('${StorageKeys.tripEvents}_${trip.id}_updated');
      expect(timestamp, isNotNull);
      expect(() => DateTime.parse(timestamp!), returnsNormally);
    });

    test('cached events are loaded correctly on initialization', () async {
      final trip = createTestTrip();
      final events = createTestEventList(4);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      // Create first loader instance to populate cache
      final loader1 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader1.initialize();
      await loader1.loadEventsForTrip(trip);

      expect(mockEventService.fetchCallCount, equals(1));

      // Create second loader instance (simulating app restart)
      final loader2 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader2.initialize();

      // Events should be loaded from cache without API call
      expect(loader2.hasEventsForTrip(trip.id), isTrue);
      expect(loader2.getEventsForTrip(trip.id).length, equals(4));
      expect(mockEventService.fetchCallCount, equals(1)); // No additional fetch
    });

    test('storage correctly serializes and deserializes event data', () async {
      final trip = createTestTrip();
      final originalEvent = EventModel(
        id: 'special-event',
        title: 'Special Running Event',
        category: EventCategory.running,
        start: DateTime(2025, 6, 15, 9, 0),
        end: DateTime(2025, 6, 15, 12, 0),
        description: 'A great running event',
        venueName: 'Central Park',
        address: '123 Park Ave',
        latitude: 40.785091,
        longitude: -73.968285,
        websiteUrl: 'https://example.com/event',
        source: 'eventbrite',
      );

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents([originalEvent]);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Create new loader to load from storage
      mockEventService.reset();
      final loader2 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader2.initialize();

      final loadedEvents = loader2.getEventsForTrip(trip.id);
      expect(loadedEvents.length, equals(1));

      final loadedEvent = loadedEvents.first;
      expect(loadedEvent.id, equals('special-event'));
      expect(loadedEvent.title, equals('Special Running Event'));
      expect(loadedEvent.category, equals(EventCategory.running));
      expect(loadedEvent.venueName, equals('Central Park'));
    });

    test('invalidateCache removes data from storage', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Verify cache exists
      expect(
          mockStorage.containsKey('${StorageKeys.tripEvents}_${trip.id}'), isTrue);

      // Invalidate cache
      await loader.invalidateCache(trip.id);

      // Verify cache is removed from storage
      expect(
          mockStorage.containsKey('${StorageKeys.tripEvents}_${trip.id}'), isFalse);
      expect(
          mockStorage.containsKey('${StorageKeys.tripEvents}_${trip.id}_updated'),
          isFalse);
    });
  });

  group('Integration: Cache Persistence Across Service Restarts', () {
    test('cache persists events across loader instances', () async {
      final trip = createTestTrip();
      final events = createTestEventList(5);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      // First loader instance
      final loader1 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader1.initialize();
      await loader1.loadEventsForTrip(trip);

      // Verify data is cached
      expect(loader1.getEventsForTrip(trip.id).length, equals(5));

      // Simulate service restart by creating new loader
      final loader2 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader2.initialize();

      // Cached data should be available immediately
      expect(loader2.getEventsForTrip(trip.id).length, equals(5));
    });

    test('cache timestamp is preserved across restarts', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader1 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader1.initialize();
      await loader1.loadEventsForTrip(trip);

      final originalCacheAge = loader1.getCacheAge(trip.id);
      expect(originalCacheAge, isNotNull);

      // Small delay to ensure time passes
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate restart
      final loader2 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader2.initialize();

      final newCacheAge = loader2.getCacheAge(trip.id);
      expect(newCacheAge, isNotNull);
      // New cache age should be slightly older than original
      expect(newCacheAge!.inMilliseconds,
          greaterThanOrEqualTo(originalCacheAge!.inMilliseconds));
    });

    test('multiple trips cache independently', () async {
      final activeTrip = createTestTrip(id: 'active-1', destinationCity: 'NYC');
      final upcomingTrip =
          createUpcomingTrip(id: 'upcoming-1', destinationCity: 'LA');
      final activeEvents = createTestEventList(3, prefix: 'active');
      final upcomingEvents = createTestEventList(4, prefix: 'upcoming');

      mockTripService.setMockActiveTrip(activeTrip);
      mockTripService.setMockUpcomingTrips([upcomingTrip]);

      // Set up events for each trip
      var callCount = 0;
      mockEventService.setMockEvents(activeEvents);

      final loader1 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader1.initialize();

      // Load active trip events
      await loader1.loadEventsForTrip(activeTrip);

      // Change mock events for upcoming trip
      mockEventService.setMockEvents(upcomingEvents);

      // Load upcoming trip events
      await loader1.loadEventsForTrip(upcomingTrip);

      // Simulate restart
      final loader2 = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader2.initialize();

      // Both trip caches should be independent
      expect(loader2.getEventsForTrip(activeTrip.id).length, equals(3));
      expect(loader2.getEventsForTrip(upcomingTrip.id).length, equals(4));
    });

    test('invalidateAllCache clears all trip data from storage', () async {
      final trip1 = createTestTrip(id: 'trip-1');
      final trip2 = createUpcomingTrip(id: 'trip-2');
      final events1 = createTestEventList(2, prefix: 'trip1');
      final events2 = createTestEventList(3, prefix: 'trip2');

      mockTripService.setMockActiveTrip(trip1);
      mockTripService.setMockUpcomingTrips([trip2]);
      mockEventService.setMockEvents([...events1, ...events2]);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      mockEventService.setMockEvents(events1);
      await loader.loadEventsForTrip(trip1);
      mockEventService.setMockEvents(events2);
      await loader.loadEventsForTrip(trip2);

      // Verify both caches exist
      expect(mockStorage.containsKey('${StorageKeys.tripEvents}_${trip1.id}'),
          isTrue);
      expect(mockStorage.containsKey('${StorageKeys.tripEvents}_${trip2.id}'),
          isTrue);

      // Invalidate all
      await loader.invalidateAllCache();

      // Both should be cleared
      expect(mockStorage.containsKey('${StorageKeys.tripEvents}_${trip1.id}'),
          isFalse);
      expect(mockStorage.containsKey('${StorageKeys.tripEvents}_${trip2.id}'),
          isFalse);
    });
  });

  group('Integration: Concurrent Load Prevention', () {
    test('loadEventsForTrip does not duplicate API calls for same trip', () async {
      final trip = createTestTrip();
      final events = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();

      // Load trip events
      await loader.loadEventsForTrip(trip);
      expect(mockEventService.fetchCallCount, equals(1));

      // Load again - should use cache, not call API
      await loader.loadEventsForTrip(trip);
      expect(mockEventService.fetchCallCount, equals(1)); // Still 1
    });

    test('loadAllTripEvents processes all trips sequentially', () async {
      final trip1 = createTestTrip(id: 'trip-1');
      final trip2 = createUpcomingTrip(id: 'trip-2');

      mockTripService.setMockActiveTrip(trip1);
      mockTripService.setMockUpcomingTrips([trip2]);
      mockEventService.setMockEvents(createTestEventList(2));

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      final results = await loader.loadAllTripEvents();

      // Both trips should have results
      expect(results.containsKey(trip1.id), isTrue);
      expect(results.containsKey(trip2.id), isTrue);
      // API should be called for each trip
      expect(mockEventService.fetchCallCount, equals(2));
    });

    test('multiple loadAllTripEvents calls use cache on second call', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();

      // First call
      await loader.loadAllTripEvents();
      expect(mockEventService.fetchCallCount, equals(1));

      // Second call should use cache
      await loader.loadAllTripEvents();
      expect(mockEventService.fetchCallCount, equals(1)); // Still 1
    });

    test('refreshEventsForTrip bypasses cache and calls API', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(2, prefix: 'cached');
      final freshEvents = createTestEventList(4, prefix: 'fresh');

      mockTripService.setMockActiveTrip(trip);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      // First, populate cache
      mockEventService.setMockEvents(cachedEvents);
      await loader.initialize();
      await loader.loadEventsForTrip(trip);
      expect(mockEventService.fetchCallCount, equals(1));

      // Refresh with new events
      mockEventService.setMockEvents(freshEvents);
      final refreshedEvents = await loader.refreshEventsForTrip(trip.id);

      expect(mockEventService.fetchCallCount, equals(2)); // New API call
      expect(refreshedEvents.length, equals(4));
    });
  });

  group('Integration: Full Data Flow', () {
    test('complete flow: user -> trips -> events', () async {
      final user = createTestUser();
      final activeTrip = createTestTrip(id: 'active-trip');
      final upcomingTrip = createUpcomingTrip(id: 'upcoming-trip');
      final activeEvents = createTestEventList(3, prefix: 'active');
      final upcomingEvents = createTestEventList(2, prefix: 'upcoming');

      mockUserService.setMockUser(user);
      mockTripService.setMockActiveTrip(activeTrip);
      mockTripService.setMockUpcomingTrips([upcomingTrip]);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      // Initialize loads cached data
      await loader.initialize();

      // Verify services are accessible
      expect(loader.userService.currentUser, equals(user));
      expect(loader.tripService.activeTrip, equals(activeTrip));
      expect(loader.tripService.upcomingTrips.length, equals(1));

      // Load events for each trip
      mockEventService.setMockEvents(activeEvents);
      await loader.loadEventsForTrip(activeTrip);

      mockEventService.setMockEvents(upcomingEvents);
      await loader.loadEventsForTrip(upcomingTrip);

      // Verify all data is accessible
      expect(loader.getEventsForTrip(activeTrip.id).length, equals(3));
      expect(loader.getEventsForTrip(upcomingTrip.id).length, equals(2));
      expect(loader.allTripEvents.keys.length, equals(2));
    });

    test('graceful degradation when services fail', () async {
      final trip = createTestTrip();

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setShouldFail(true);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();

      // Should not throw, should return empty list
      final events = await loader.loadEventsForTrip(trip);
      expect(events, isEmpty);
      expect(loader.lastError, isNull); // Error handled gracefully
    });

    test('returns cached data when API fails after initial load', () async {
      final trip = createTestTrip();
      final cachedEvents = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(cachedEvents);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Now fail the API
      mockEventService.setShouldFail(true);

      // Invalidate to force refresh attempt
      await loader.invalidateCache(trip.id);

      // Re-add cached data to storage for recovery test
      mockEventService.setShouldFail(false);
      mockEventService.setMockEvents(cachedEvents);
      await loader.loadEventsForTrip(trip);

      // Then fail again
      mockEventService.setShouldFail(true);

      // Refresh should fail but return cached data
      final events = await loader.refreshEventsForTrip(trip.id);
      expect(events.length, equals(3)); // Cached data returned
    });

    test('notifies listeners through complete flow', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      final notifications = <String>[];

      loader.addListener(() {
        if (loader.isLoading) {
          notifications.add('loading_start');
        } else if (loader.isRefreshing) {
          notifications.add('refreshing');
        } else {
          notifications.add('complete');
        }
      });

      await loader.initialize();
      await loader.loadEventsForTrip(trip);

      // Should have received multiple notifications
      expect(notifications, isNotEmpty);
      expect(notifications.contains('loading_start'), isTrue);
      expect(notifications.contains('complete'), isTrue);
    });
  });

  group('Integration: Provider Coordination', () {
    test('loader exposes dependent services correctly', () async {
      final user = createTestUser();
      final trip = createTestTrip();

      mockUserService.setMockUser(user);
      mockTripService.setMockActiveTrip(trip);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      await loader.initialize();

      // Verify service references are correctly exposed
      expect(loader.userService, same(mockUserService));
      expect(loader.tripService, same(mockTripService));
      expect(loader.eventService, same(mockEventService));

      // Verify data is accessible through services
      expect(loader.userService.currentUser?.id, equals(user.id));
      expect(loader.tripService.activeTrip?.id, equals(trip.id));
    });

    test('ChangeNotifier notifications work for UI updates', () async {
      final trip = createTestTrip();
      final events = createTestEventList(3);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      var notificationCount = 0;
      var lastLoadingState = false;
      var lastRefreshingState = false;

      loader.addListener(() {
        notificationCount++;
        lastLoadingState = loader.isLoading;
        lastRefreshingState = loader.isRefreshing;
      });

      await loader.initialize();

      // Should have notified during initialization
      expect(notificationCount, greaterThan(0));

      final preLoadCount = notificationCount;

      await loader.loadEventsForTrip(trip);

      // Should have notified during event loading
      expect(notificationCount, greaterThan(preLoadCount));
    });

    test('loader correctly reports loading and refreshing states', () async {
      final trip = createTestTrip();
      final events = createTestEventList(2);

      mockTripService.setMockActiveTrip(trip);
      mockEventService.setMockEvents(events);

      final loader = UserTripEventsLoader(
        storage: mockStorage,
        eventService: mockEventService,
        tripService: mockTripService,
        userService: mockUserService,
      );

      final loadingStates = <bool>[];
      final refreshingStates = <bool>[];

      loader.addListener(() {
        loadingStates.add(loader.isLoading);
        refreshingStates.add(loader.isRefreshing);
      });

      // Initial state
      expect(loader.isLoading, isFalse);
      expect(loader.isRefreshing, isFalse);

      await loader.initialize();

      // Loading should have been true during initialization
      expect(loadingStates.contains(true), isTrue);

      // After initialization, loading should be false
      expect(loader.isLoading, isFalse);

      await loader.loadAllTripEvents();

      // Refreshing should have been true during loadAllTripEvents
      expect(refreshingStates.contains(true), isTrue);

      // After completion, refreshing should be false
      expect(loader.isRefreshing, isFalse);
    });
  });
}
