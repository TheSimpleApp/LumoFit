# Specification: Load User Data with Local Trip-Based Events

## Overview

Build a bulletproof system to load user data along with local fitness events relevant to their active or planned trips. The system uses trip start and end dates as the primary temporal filter for event discovery. This feature enables users to discover local running events, yoga classes, hiking groups, and other fitness activities occurring during their travel dates at their destination. The implementation must be reliable with graceful fallback mechanisms, proper caching, and comprehensive error handling.

## Workflow Type

**Type**: feature

**Rationale**: This is a new feature that coordinates multiple existing services (UserService, TripService, EventService) into a unified data loading flow with added reliability patterns. It requires creating new service orchestration code, enhancing caching, and adding robust error handling.

## Task Scope

### Services Involved
- **Flutter App** (primary) - Main application containing all services and UI
- **Supabase Edge Functions** (integration) - External event data source via `list_events_combined` function

### This Task Will:
- [ ] Create a new `UserTripEventsLoader` service to orchestrate coordinated data loading
- [ ] Implement trip-based event filtering using trip `startDate` and `endDate`
- [ ] Support loading events for both active AND planned (upcoming) trips
- [ ] Add robust caching layer for offline/failure scenarios
- [ ] Implement comprehensive error handling with graceful degradation
- [ ] Use destination city location for geographic event filtering
- [ ] Follow existing service patterns for consistency

### Out of Scope:
- Additional API sources beyond current Supabase Edge Functions (designed for future extensibility)
- AI/ML recommendations (foundation laid for future integration)
- Real-time event updates/push notifications
- User preference-based event filtering (beyond trip dates/location)

## Service Context

### Flutter App

**Tech Stack:**
- Language: Dart 3.6+
- Framework: Flutter
- State Management: Provider
- Backend: Supabase (supabase_flutter ^1.10.0)
- HTTP: http package ^1.0.0
- Storage: shared_preferences ^2.0.0
- Location: geolocator 13.0.4

**Key Directories:**
- `lib/models/` - Data models (TripModel, EventModel, UserModel)
- `lib/services/` - Business logic services
- `lib/config/` - App configuration

**Entry Point:** `lib/main.dart`

**How to Run:**
```bash
flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key --dart-define=SUPABASE_FUNCTIONS_BASE_URL=your_url
```

**Port:** N/A (mobile app)

### Supabase Edge Functions

**Endpoint:** `list_events_combined`

**Request Parameters:**
```json
{
  "q": "optional search query",
  "lat": 40.7608,
  "lon": -111.8910,
  "radiusKm": 50,
  "startDate": "2025-01-01T00:00:00.000Z",
  "endDate": "2025-01-15T00:00:00.000Z",
  "page": 1,
  "perPage": 50,
  "providers": ["eventbrite", "runsignup"]
}
```

**Response Format:**
```json
{
  "events": [
    {
      "id": "string",
      "title": "string",
      "start": "ISO8601",
      "end": "ISO8601",
      "category": "running|yoga|hiking|cycling|crossfit|other",
      "venue": "string",
      "address": "string",
      "lat": 40.7608,
      "lon": -111.8910,
      "url": "string",
      "imageUrl": "string",
      "source": "eventbrite|runsignup"
    }
  ]
}
```

## Files to Modify

| File | Service | What to Change |
|------|---------|----------------|
| `lib/services/user_trip_events_loader.dart` | Flutter | **CREATE** - New orchestration service for coordinated data loading |
| `lib/services/storage_service.dart` | Flutter | Add new storage keys for cached trip events |
| `lib/services/services.dart` | Flutter | Export the new loader service |
| `lib/services/event_service.dart` | Flutter | Add method for trip-specific event loading with caching |
| `lib/main.dart` | Flutter | Register new service in provider tree |

## Files to Reference

These files show patterns to follow:

| File | Pattern to Copy |
|------|----------------|
| `lib/services/event_service.dart` | Service structure, Supabase Edge Function calls, error handling, local storage fallback |
| `lib/services/trip_service.dart` | ChangeNotifier pattern, initialize/save flow, storage integration |
| `lib/services/user_service.dart` | User data loading, error recovery, sample data seeding |
| `lib/services/storage_service.dart` | StorageKeys pattern, JSON serialization |
| `lib/openai/openai_config.dart` | Retry logic with exponential backoff |
| `lib/services/google_places_service.dart` | HTTP request patterns, error handling |

## Patterns to Follow

### Service Structure Pattern

From `lib/services/event_service.dart`:

```dart
class EventService extends ChangeNotifier {
  final StorageService _storage;
  List<EventModel> _events = [];
  bool _isLoading = false;

  EventService(this._storage);

  bool get isLoading => _isLoading;
  List<EventModel> get all => List.unmodifiable(_events);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Load from storage first
      final jsonList = _storage.getJsonList(StorageKeys.events);
      if (jsonList != null && jsonList.isNotEmpty) {
        _events = jsonList.map((j) => EventModel.fromJson(j)).toList();
      } else {
        await _seed();
      }
    } catch (e) {
      debugPrint('EventService.initialize error: $e');
      await _seed();
    }
    _isLoading = false;
    notifyListeners();
  }
}
```

**Key Points:**
- Extend `ChangeNotifier` for Provider integration
- Inject `StorageService` dependency
- Maintain loading state with `_isLoading`
- Load from local storage first, then fetch external
- Catch errors and provide fallback data

### Retry with Exponential Backoff Pattern

From `lib/openai/openai_config.dart`:

```dart
Future<http.Response> _postWithRetry(Map<String, dynamic> body) async {
  const maxAttempts = 3;
  var attempt = 0;
  int delayMs = 600;
  http.Response? last;
  while (attempt < maxAttempts) {
    attempt += 1;
    try {
      final res = await http.post(_uri, headers: _headers, body: utf8.encode(jsonEncode(body)));
      if (res.statusCode < 500 && res.statusCode != 429) return res;
      last = res;
    } catch (e) {
      debugPrint('Request error (attempt $attempt): $e');
    }
    await Future.delayed(Duration(milliseconds: delayMs));
    delayMs *= 2;
  }
  return last ?? http.Response('{"error":"request_failed"}', 500);
}
```

**Key Points:**
- 3 retry attempts maximum
- Exponential backoff (600ms -> 1200ms -> 2400ms)
- Return cached/fallback on failure
- Log errors for debugging

### Storage Keys Pattern

From `lib/services/storage_service.dart`:

```dart
class StorageKeys {
  static const String userProfile = 'user_profile';
  static const String trips = 'trips';
  static const String events = 'events';
  // Add new keys here following naming convention
}
```

**Key Points:**
- Use descriptive snake_case key names
- Group related keys together
- Add documentation for complex keys

## Requirements

### Functional Requirements

1. **Coordinated User Data Loading**
   - Description: Load user profile, trips, and relevant events in a single coordinated operation
   - Acceptance: `loadUserWithTripEvents()` returns user, their trips, and events for each trip

2. **Trip Date-Based Event Filtering**
   - Description: Filter events using trip's `startDate` and `endDate` as temporal boundaries
   - Acceptance: Only events occurring within trip date range are returned

3. **Active and Planned Trip Support**
   - Description: Load events for currently active trips and upcoming planned trips
   - Acceptance: Events loaded for trips where `isActive == true` OR `isUpcoming == true`

4. **Location-Based Event Discovery**
   - Description: Use trip's `destinationCity` to find geographically relevant events
   - Acceptance: Events are filtered to trip destination area (default 50km radius)

5. **Offline/Failure Resilience**
   - Description: System must work when API calls fail using cached data
   - Acceptance: Cached events returned when network unavailable; loading never crashes

6. **Cache Management**
   - Description: Cache trip-specific events locally for fast access and offline use
   - Acceptance: Events cached per trip ID; cache invalidated when trip dates change

### Edge Cases

1. **No trips exist** - Return user data with empty events list
2. **Trip has no destination coordinates** - Use city name geocoding fallback or skip geo-filter
3. **API returns empty events** - Return empty list (not error), use cached if available
4. **Network timeout** - Use cached data, log warning, don't block UI
5. **Multiple concurrent load requests** - Debounce/deduplicate to prevent duplicate API calls
6. **Trip dates in the past** - Still load events (user may want historical data)
7. **Very long trip duration (30+ days)** - Paginate event fetching or limit to nearest 30 days

## Implementation Notes

### DO
- Follow the ChangeNotifier pattern from `EventService` for provider integration
- Reuse `EventService.fetchExternalEvents()` for API calls (don't duplicate HTTP logic)
- Use `StorageService` for all caching with new `StorageKeys.tripEvents` pattern
- Use `TripModel.destinationCity` for location-based queries
- Implement retry with exponential backoff for critical API calls
- Always use `utf8.decode(response.bodyBytes)` for HTTP response parsing
- Return cached data immediately, then refresh in background ("stale-while-revalidate")
- Log all errors with `debugPrint()` for troubleshooting

### DON'T
- Create new HTTP client patterns - use existing `EventService` or `http` package patterns
- Block UI on network failures - always have cached/fallback data ready
- Store raw API responses - transform to `EventModel` before caching
- Call APIs without rate limiting - implement debounce for user-triggered refreshes
- Hardcode coordinates - use trip destination or geocoding
- Ignore error cases - every async operation needs try/catch

## Development Environment

### Start Services

```bash
# Run Flutter app
flutter run

# With environment variables
flutter run \
  --dart-define=GOOGLE_PLACES_API_KEY=your_key \
  --dart-define=SUPABASE_FUNCTIONS_BASE_URL=https://your-project.functions.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Service URLs
- Flutter App: iOS Simulator / Android Emulator / Chrome
- Supabase Dashboard: https://supabase.com/dashboard (for Edge Functions)

### Required Environment Variables
- `GOOGLE_PLACES_API_KEY`: Google Places API for geocoding destination cities
- `SUPABASE_FUNCTIONS_BASE_URL`: Base URL for Supabase Edge Functions
- `SUPABASE_ANON_KEY`: Supabase anonymous key for authenticated requests (optional)
- `OPENAI_PROXY_API_KEY`: OpenAI proxy key (for future AI/ML integration)
- `OPENAI_PROXY_ENDPOINT`: OpenAI proxy endpoint (for future AI/ML integration)

## Success Criteria

The task is complete when:

1. [ ] New `UserTripEventsLoader` service created and exports via `services.dart`
2. [ ] Service loads user data via `UserService`
3. [ ] Service loads trips via `TripService`
4. [ ] Service loads events for active/upcoming trips using date filters
5. [ ] Events are cached per trip ID in local storage
6. [ ] Cached events returned immediately, background refresh occurs
7. [ ] System works offline using cached data (no crashes)
8. [ ] API failures handled gracefully with fallback to cache
9. [ ] No console errors during normal operation
10. [ ] Existing tests still pass (currently none - add tests)
11. [ ] Service integrated in Provider tree in `main.dart`

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| UserTripEventsLoader initialization | `test/services/user_trip_events_loader_test.dart` | Service initializes with dependencies |
| Load events for active trip | `test/services/user_trip_events_loader_test.dart` | Events filtered by trip dates |
| Load events for upcoming trip | `test/services/user_trip_events_loader_test.dart` | Upcoming trips included in event loading |
| Handle API failure | `test/services/user_trip_events_loader_test.dart` | Returns cached data on network error |
| Handle empty trips | `test/services/user_trip_events_loader_test.dart` | Returns empty events when no trips |
| Cache invalidation | `test/services/user_trip_events_loader_test.dart` | Cache refreshed when trip dates change |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Full data loading flow | UserService + TripService + EventService | All services coordinate correctly |
| Storage persistence | UserTripEventsLoader + StorageService | Events cached and retrieved correctly |
| Provider integration | UserTripEventsLoader + Provider | Widget tree receives updates |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| First app launch | 1. Open app 2. Wait for initialization | User, trips, and events load without error |
| Offline access | 1. Load data 2. Toggle airplane mode 3. Restart app | Cached data displayed |
| Network recovery | 1. Start offline 2. Connect network 3. Pull to refresh | Fresh data loads and displays |

### Browser Verification (if frontend)
| Page/Component | URL | Checks |
|----------------|-----|--------|
| Home Screen | App home tab | Active trip with events displayed |
| Trip Detail Screen | Tap on trip | Events for that trip's date range shown |
| Discover Screen | Discover tab | Events loaded based on active trip context |

### Database Verification (if applicable)
| Check | Query/Command | Expected |
|-------|---------------|----------|
| Cached events exist | `StorageService.getJsonList('trip_events_<tripId>')` | Returns cached EventModel list |
| Cache timestamp valid | `StorageService.getString('trip_events_<tripId>_updated')` | ISO8601 timestamp within 24h |

### QA Sign-off Requirements
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] Browser/app verification complete
- [ ] Offline scenario works correctly
- [ ] No regressions in existing functionality
- [ ] Code follows established ChangeNotifier + StorageService patterns
- [ ] No security vulnerabilities introduced (no hardcoded keys, proper error handling)
- [ ] Performance acceptable (data loads within 3 seconds on good network)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    UserTripEventsLoader                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐   │
│  │ UserService │  │ TripService │  │     EventService        │   │
│  │             │  │             │  │  fetchExternalEvents()  │   │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘   │
│         │                │                      │                 │
│         ▼                ▼                      ▼                 │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                   StorageService                          │    │
│  │  user_profile | trips | trip_events_<id> | events        │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │   Supabase Edge Functions           │
            │   list_events_combined              │
            │   (eventbrite, runsignup)           │
            └─────────────────────────────────────┘
```

## Data Flow

1. **App Launch / Refresh Triggered**
   ```
   UserTripEventsLoader.loadAll()
       ├── UserService.initialize() → Load user from cache
       ├── TripService.initialize() → Load trips from cache
       └── For each active/upcoming trip:
           ├── Check cache: StorageService.getJsonList('trip_events_<tripId>')
           ├── If cached & fresh → Return immediately
           └── Background: EventService.fetchExternalEvents(
                   startDate: trip.startDate,
                   endDate: trip.endDate,
                   lat: trip.lat (from geocode),
                   lon: trip.lon (from geocode)
               )
               └── Cache result → StorageService.setJsonList(...)
   ```

2. **Cache Strategy**: Stale-While-Revalidate
   - Return cached data immediately for fast UI
   - Fetch fresh data in background
   - Update UI when fresh data arrives
   - Cache TTL: 1 hour for active trips, 24 hours for upcoming trips
