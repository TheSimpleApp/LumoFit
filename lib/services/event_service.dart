import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fittravel/supabase/supabase_config.dart';

/// EventService fetches events from Supabase database and Edge Functions.
/// Events are shared across all users and fetched per destination.
class EventService extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _destinationEvents = [];
  bool _isLoading = false;
  String? _currentCity;

  EventService();

  bool get isLoading => _isLoading;
  List<EventModel> get all =>
      List.unmodifiable([..._destinationEvents, ..._events]);

  /// Events for the current destination
  List<EventModel> get destinationEvents =>
      List.unmodifiable(_destinationEvents);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Seed demo events as fallback
      _seed();
    } catch (e) {
      debugPrint('EventService.initialize error: $e');
      _events = [];
    }
    _isLoading = false;
    notifyListeners();
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
  /// This calls the edge function that uses AI to find events
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

  /// Fetch events via the Combined Supabase Edge Function.
  /// Prefer Supabase Edge Functions via Supabase client (with auth) when available.
  /// Falls back to direct HTTP using SUPABASE_FUNCTIONS_BASE_URL if provided.
  /// Always returns [] on error and logs details via debugPrint.
  Future<List<EventModel>> fetchExternalEvents({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    int limit = 50,
  }) async {
    Uri make(String base, String fn) => Uri.parse(
        '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/$fn');

    // Match combined function parameter names
    final payload = <String, dynamic>{
      if (query.isNotEmpty) 'q': query,
      if (centerLat != null) 'lat': centerLat,
      if (centerLng != null) 'lon': centerLng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      'page': 1,
      'perPage': limit,
      'providers': ['eventbrite', 'runsignup'],
    };

    try {
      // 1) Try via Supabase client (adds user/session auth for verify_jwt=true)
      try {
        final response = await SupabaseConfig.client.functions.invoke(
          'list_events_combined',
          body: payload,
        );
        final data = (response.data is Map<String, dynamic>)
            ? response.data as Map<String, dynamic>
            : jsonDecode(jsonEncode(response.data)) as Map<String, dynamic>;
        return _mapNormalizedEvents(data);
      } catch (e) {
        debugPrint(
            'fetchExternalEvents: functions.invoke failed, trying HTTP fallback. Error: $e');
      }

      // 2) Fallback to direct HTTP if functions base is provided (for dev/no-auth cases)
      final base = AppConfig.supabaseFunctionsUrl;
      if (base.isEmpty) {
        debugPrint(
            'fetchExternalEvents skipped: no Supabase Functions base URL and invoke failed');
        return [];
      }
      final res = await http.post(
        make(base, 'list_events_combined'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint(
            'fetchExternalEvents/combined HTTP error: ${res.statusCode} ${res.body}');
        return [];
      }
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return _mapNormalizedEvents(data);
    } catch (e) {
      debugPrint('fetchExternalEvents/combined exception: $e');
      return [];
    }
  }

  List<EventModel> _mapNormalizedEvents(Map<String, dynamic> data) {
    final list = (data['events'] as List?) ?? const [];
    final out = <EventModel>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final id = (item['id'] ?? '').toString();
        final title = (item['title'] ?? '').toString();
        final startStr = item['start']?.toString();
        if (id.isEmpty || title.isEmpty || startStr == null) continue;
        final start = DateTime.tryParse(startStr);
        if (start == null) continue;
        final categoryStr =
            (item['category']?.toString().toLowerCase() ?? 'other');
        final category = eventCategoryFromString(categoryStr);
        final venueName = (item['venue'] ?? '').toString();
        final address = item['address']?.toString();
        final lat =
            (item['lat'] is num) ? (item['lat'] as num).toDouble() : null;
        final lon =
            (item['lon'] is num) ? (item['lon'] as num).toDouble() : null;
        final websiteUrl = item['url']?.toString();
        final registrationUrl = item['registrationUrl']?.toString();
        final endStr = item['end']?.toString();
        final end = endStr != null ? DateTime.tryParse(endStr) : null;
        final imageUrl = item['imageUrl']?.toString();
        final source = (item['source'] ?? item['provider'])?.toString();

        out.add(EventModel(
          id: id,
          title: title,
          category: category,
          start: start,
          end: end,
          description: null,
          venueName: venueName,
          address: address,
          latitude: lat,
          longitude: lon,
          websiteUrl: websiteUrl,
          registrationUrl: registrationUrl,
          imageUrl: imageUrl,
          source: source,
        ));
      } catch (e) {
        debugPrint('fetchExternalEvents mapping error: $e');
        continue;
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
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
}
