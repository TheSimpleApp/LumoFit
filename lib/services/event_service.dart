import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/supabase/supabase_config.dart';

/// EventService fetches events from Supabase database and Edge Functions.
/// Events are shared across all users and fetched per destination.
class EventService extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _destinationEvents = [];
  bool _isLoading = false;
  String? _currentCity;

  // For webhook-based event discovery
  bool _isDiscoveringEvents = false;
  String? _lastDiscoveryError;

  EventService();

  bool get isLoading => _isLoading;
  bool get isDiscoveringEvents => _isDiscoveringEvents;
  String? get lastDiscoveryError => _lastDiscoveryError;
  List<EventModel> get all =>
      List.unmodifiable([..._destinationEvents, ..._events]);

  /// Events for the current destination
  List<EventModel> get destinationEvents =>
      List.unmodifiable(_destinationEvents);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Try to load events from Supabase first
      await _loadEventsFromSupabase();

      // Seed demo events as fallback if no events in DB
      if (_events.isEmpty && _destinationEvents.isEmpty) {
        _seed();
      }
    } catch (e) {
      debugPrint('EventService.initialize error: $e');
      _events = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load all events from Supabase
  Future<void> _loadEventsFromSupabase() async {
    try {
      final now = DateTime.now();
      final response = await SupabaseConfig.client
          .from('events')
          .select()
          .gte('start_date', now.toIso8601String())
          .order('start_date', ascending: true)
          .limit(100);

      final List<dynamic> data = response as List<dynamic>;

      _events = data.map((json) {
        final map = json as Map<String, dynamic>;
        return EventModel(
          id: map['id'] as String,
          title: map['title'] as String? ?? 'Untitled Event',
          category:
              eventCategoryFromString(map['category'] as String? ?? 'other'),
          start: DateTime.parse(map['start_date'] as String),
          end: map['end_date'] != null
              ? DateTime.tryParse(map['end_date'] as String)
              : null,
          description: map['description'] as String?,
          venueName: map['venue_name'] as String? ?? 'TBA',
          address: map['address'] as String?,
          latitude: (map['latitude'] as num?)?.toDouble(),
          longitude: (map['longitude'] as num?)?.toDouble(),
          websiteUrl: map['website_url'] as String?,
          registrationUrl: map['registration_url'] as String?,
          imageUrl: map['image_url'] as String?,
          source: map['source'] as String?,
        );
      }).toList();

      debugPrint('EventService: Loaded ${_events.length} events from Supabase');
    } catch (e) {
      debugPrint('EventService._loadEventsFromSupabase error: $e');
      // Continue with empty events, will use seed data
    }
  }

  /// Fetch events for a specific city from Supabase
  /// Called when active trip changes or on demand
  Future<void> fetchEventsForCity({
    required String city,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentCity == city && _destinationEvents.isNotEmpty) {
      // Already have events for this city
      return;
    }

    _isLoading = true;
    _currentCity = city;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = startDate ?? now;
      final end = endDate ?? DateTime(now.year, now.month + 3, now.day);

      // Query events from Supabase
      var query = SupabaseConfig.client
          .from('events')
          .select()
          .ilike('city', '%$city%')
          .gte('start_date', start.toIso8601String())
          .lte('start_date', end.toIso8601String())
          .order('start_date', ascending: true)
          .limit(50);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      _destinationEvents = data.map((json) {
        final map = json as Map<String, dynamic>;
        return EventModel(
          id: map['id'] as String,
          title: map['title'] as String? ?? 'Untitled Event',
          category:
              eventCategoryFromString(map['category'] as String? ?? 'other'),
          start: DateTime.parse(map['start_date'] as String),
          end: map['end_date'] != null
              ? DateTime.tryParse(map['end_date'] as String)
              : null,
          description: map['description'] as String?,
          venueName: map['venue_name'] as String? ?? 'TBA',
          address: map['address'] as String?,
          latitude: (map['latitude'] as num?)?.toDouble(),
          longitude: (map['longitude'] as num?)?.toDouble(),
          websiteUrl: map['website_url'] as String?,
          registrationUrl: map['registration_url'] as String?,
          imageUrl: map['image_url'] as String?,
          source: map['source'] as String?,
        );
      }).toList();

      debugPrint(
          'EventService: Fetched ${_destinationEvents.length} events for $city');
    } catch (e) {
      debugPrint('EventService.fetchEventsForCity error: $e');
      // Keep existing events on error
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Trigger backend to fetch new events for a destination
  /// This calls the n8n webhook API that uses an AI agent to discover events
  Future<void> refreshEventsForCity({
    required String city,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('EventService: Triggering event refresh for $city...');

      final now = DateTime.now();
      await SupabaseConfig.client.functions.invoke(
        'fetch_destination_events',
        body: {
          'city': city,
          if (country != null) 'country': country,
          'start_date': (startDate ?? now).toIso8601String().split('T')[0],
          'end_date': (endDate ?? DateTime(now.year, now.month + 3, now.day))
              .toIso8601String()
              .split('T')[0],
          'max_events': 50,
        },
      );

      // Re-fetch events after refresh
      await fetchEventsForCity(
          city: city, startDate: startDate, endDate: endDate);
    } catch (e) {
      debugPrint('EventService.refreshEventsForCity error: $e');
    }
  }

  /// Clear destination events (e.g., when switching cities)
  void clearDestinationEvents() {
    _destinationEvents = [];
    _currentCity = null;
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    final id = const Uuid();
    _events = [
      EventModel(
        id: id.v4(),
        title: 'Lady Bird Lake Trail Run',
        category: EventCategory.running,
        start: DateTime(now.year, now.month, now.day + 3, 7, 0),
        venueName: 'Lady Bird Lake Trail',
        address: '2201 Lakeshore Blvd, Austin, TX 78741',
        latitude: 30.2628,
        longitude: -97.7451,
        websiteUrl: 'https://www.austinrunningclub.com',
        registrationUrl: 'https://www.austinrunningclub.com/events',
        imageUrl:
            'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800&q=80',
        description:
            'Scenic 5K run along Lady Bird Lake with skyline views. All paces welcome. Post-run coffee social.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Sunrise Yoga at Zilker Park',
        category: EventCategory.yoga,
        start: DateTime(now.year, now.month, now.day + 1, 6, 30),
        venueName: 'Zilker Park Great Lawn',
        address: '2100 Barton Springs Rd, Austin, TX 78746',
        latitude: 30.2672,
        longitude: -97.7681,
        websiteUrl: 'https://www.austinyoga.com',
        imageUrl:
            'https://images.unsplash.com/photo-1545389336-cf090694435e?w=800&q=80',
        description:
            'Free outdoor yoga session with downtown Austin views. All levels welcome. Bring your mat and water.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Barton Creek Greenbelt Hike',
        category: EventCategory.hiking,
        start: DateTime(now.year, now.month, now.day + 5, 8, 0),
        venueName: 'Barton Creek Greenbelt',
        address: '3755 S Capital of Texas Hwy, Austin, TX 78704',
        latitude: 30.2426,
        longitude: -97.8119,
        websiteUrl: 'https://www.austinparks.org/barton-creek-greenbelt',
        imageUrl:
            'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&q=80',
        description:
            'Moderate 7-mile hike through limestone cliffs and creek crossings. Bring water shoes and snacks.',
      ),
      EventModel(
        id: id.v4(),
        title: 'South Congress Cycle Tour',
        category: EventCategory.cycling,
        start: DateTime(now.year, now.month, now.day + 2, 17, 30),
        venueName: 'Starting at South Congress Bridge',
        address: 'S Congress Ave & Barton Springs Rd, Austin, TX 78704',
        latitude: 30.2631,
        longitude: -97.7446,
        websiteUrl: 'https://www.socialcycling.com',
        imageUrl:
            'https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=800&q=80',
        description:
            'Evening group ride through SoCo and East Austin. Helmets required. 15-mile loop, moderate pace.',
      ),
      EventModel(
        id: id.v4(),
        title: 'CrossFit Central Drop-In WOD',
        category: EventCategory.crossfit,
        start: DateTime(now.year, now.month, now.day + 6, 18, 0),
        venueName: 'CrossFit Central',
        address: '3801 N Capital of Texas Hwy, Austin, TX 78746',
        latitude: 30.3074,
        longitude: -97.7989,
        websiteUrl: 'https://www.crossfitcentral.com',
        registrationUrl: 'https://www.crossfitcentral.com/drop-in',
        imageUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
        description:
            'Travelers and visitors welcome for WOD. Arrive 15 min early for intro. One of Austin\'s top boxes.',
      ),
    ];
  }

  /// Basic text search with optional category and date window filters.
  List<EventModel> search({
    required String query,
    Set<EventCategory>? categories,
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
  }) {
    var out = _events;

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      out = out.where((e) {
        return e.title.toLowerCase().contains(q) ||
            (e.venueName.toLowerCase().contains(q)) ||
            (e.address?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (categories != null && categories.isNotEmpty) {
      out = out.where((e) => categories.contains(e.category)).toList();
    }

    if (startDate != null || endDate != null) {
      final s = startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final e = endDate ?? DateTime(2100);
      out = out
          .where((ev) =>
              ev.start.isAfter(s.subtract(const Duration(seconds: 1))) &&
              ev.start.isBefore(e.add(const Duration(seconds: 1))))
          .toList();
    }

    if (centerLat != null && centerLng != null && radiusKm != null) {
      out = out.where((ev) {
        if (ev.latitude == null || ev.longitude == null) return true;
        final d = _haversine(centerLat, centerLng, ev.latitude!, ev.longitude!);
        return d <= radiusKm;
      }).toList();
    }

    // Sort: soonest first
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  /// Fetch events from local cache (Supabase data).
  /// Events are discovered via discoverEventsForLocation() which uses the edge function.
  /// This method searches the locally loaded events.
  Future<List<EventModel>> fetchExternalEvents({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    int limit = 50,
  }) async {
    try {
      debugPrint('EventService: Searching local events with query: $query');

      // Use the local search method which searches _events and _destinationEvents
      final results = search(
        query: query,
        startDate: startDate,
        endDate: endDate,
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
      );

      debugPrint('EventService: Found ${results.length} events locally');

      // Return limited results
      return results.take(limit).toList();
    } catch (e, st) {
      debugPrint('fetchExternalEvents: Local search exception: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  // Simple haversine distance in km
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  /// Discover events for a location using the Supabase edge function
  /// This will fetch events using AI and save them to Supabase
  Future<void> discoverEventsForLocation({
    required String locationName,
    required double latitude,
    required double longitude,
  }) async {
    _isDiscoveringEvents = true;
    _lastDiscoveryError = null;
    notifyListeners();

    try {
      debugPrint('EventService: Discovering events for $locationName...');

      // Parse city from location name (handle formats like "Austin, TX" or "Austin, Texas, USA")
      final parts = locationName.split(',').map((s) => s.trim()).toList();
      final city = parts.isNotEmpty ? parts[0] : locationName;
      final country = parts.length > 2 ? parts.last : (parts.length > 1 ? parts[1] : null);

      // Calculate date range (today to 3 months from now)
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 3, now.day);

      // Call Supabase edge function
      final response = await SupabaseConfig.client.functions.invoke(
        'fetch_destination_events',
        body: {
          'city': city,
          if (country != null) 'country': country,
          'start_date': now.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'latitude': latitude,
          'longitude': longitude,
          'max_events': 50,
        },
      );

      if (response.status != 200) {
        throw Exception('Edge function returned ${response.status}: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final eventsCount = data['events_count'] as int? ?? 0;
      final cached = data['cached'] as bool? ?? false;

      debugPrint('EventService: Edge function returned $eventsCount events (cached: $cached)');

      if (eventsCount == 0) {
        _lastDiscoveryError = 'No events found for this location';
        notifyListeners();
        _isDiscoveringEvents = false;
        return;
      }

      // Reload events from Supabase (edge function already saved them)
      await _loadEventsFromSupabase();

      // Also fetch for this specific city
      await fetchEventsForCity(city: city);

      debugPrint('EventService: Successfully loaded $eventsCount events');
    } catch (e, st) {
      debugPrint('EventService.discoverEventsForLocation error: $e');
      debugPrint(st.toString());
      _lastDiscoveryError = 'Failed to discover events: ${e.toString()}';
    } finally {
      _isDiscoveringEvents = false;
      notifyListeners();
    }
  }

  /// Get events near a specific location (for trip planning).
  /// Returns events within [radiusMiles] of the given coordinates.
  /// Useful for filtering events to only show those relevant to a trip destination.
  List<EventModel> getEventsNearLocation({
    required double latitude,
    required double longitude,
    double radiusMiles = 50, // Default 50 mile radius
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final radiusKm = radiusMiles * 1.60934; // Convert miles to km
    return search(
      query: '',
      centerLat: latitude,
      centerLng: longitude,
      radiusKm: radiusKm,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
