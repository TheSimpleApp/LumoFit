import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fittravel/supabase/supabase_config.dart';

/// EventService fetches events from Supabase Edge Functions.
/// Demo events are seeded in memory on initialize.
class EventService extends ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = false;

  EventService();

  bool get isLoading => _isLoading;
  List<EventModel> get all => List.unmodifiable(_events);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Seed demo events in memory (not persisted)
      _seed();
    } catch (e) {
      debugPrint('EventService.initialize error: $e');
      _events = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    final id = const Uuid();
    _events = [
      EventModel(
        id: id.v4(),
        title: 'Cairo Runners 5K - Al-Azhar Park',
        category: EventCategory.running,
        start: DateTime(now.year, now.month, now.day + 3, 7, 0),
        venueName: 'Al-Azhar Park',
        address: 'Salah Salem St, El-Darb El-Ahmar, Cairo, Egypt',
        latitude: 30.0407,
        longitude: 31.2622,
        websiteUrl: 'https://www.cairorunners.com',
        registrationUrl: 'https://www.cairorunners.com/our-runs',
        description: 'Morning 5K run through historic Al-Azhar Park with stunning Nile views and Cairo skyline.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Sunrise Yoga by the Nile',
        category: EventCategory.yoga,
        start: DateTime(now.year, now.month, now.day + 1, 6, 30),
        venueName: 'Nile Corniche - Zamalek',
        address: '26th of July Corridor, Zamalek, Cairo, Egypt',
        latitude: 30.0626,
        longitude: 31.2218,
        websiteUrl: 'https://flexanaegypt.com',
        description: 'Outdoor yoga session with sunrise views over the Nile. All levels welcome. Bring your mat.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Wadi Degla Desert Hike',
        category: EventCategory.hiking,
        start: DateTime(now.year, now.month, now.day + 5, 8, 0),
        venueName: 'Wadi Degla Protectorate',
        address: 'Wadi Degla, Maadi, Cairo, Egypt',
        latitude: 29.9700,
        longitude: 31.3200,
        websiteUrl: 'https://desertadventuresegypt.com/destinations/wadi-degla-protectorate',
        description: 'Moderate desert canyon hike through rugged valleys. Bring water, hat, and sunscreen. 2-3 hours.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Nile Corniche Cycle Ride',
        category: EventCategory.cycling,
        start: DateTime(now.year, now.month, now.day + 2, 17, 30),
        venueName: 'Nile Corniche - Starting at Zamalek',
        address: '26th of July Corridor, Zamalek, Cairo, Egypt',
        latitude: 30.0626,
        longitude: 31.2218,
        websiteUrl: 'https://www.cairorunners.com',
        description: 'Evening group ride along the Nile Corniche. Helmets required. Moderate pace, 20km route.',
      ),
      EventModel(
        id: id.v4(),
        title: 'CrossFit Hustle Drop-In WOD',
        category: EventCategory.crossfit,
        start: DateTime(now.year, now.month, now.day + 6, 18, 0),
        venueName: 'CrossFit Hustle Maadi',
        address: 'Maadi Bandar Mall, Palestine Rd, Maadi, Cairo, Egypt',
        latitude: 29.9600,
        longitude: 31.2500,
        websiteUrl: 'https://yellow.place/en/crossfit-hustle-cairo-egypt',
        description: 'Visitors welcome for WOD (Workout of the Day). Arrive 15 min early for introduction and waiver.',
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
      out = out.where((ev) => ev.start.isAfter(s.subtract(const Duration(seconds: 1))) && ev.start.isBefore(e.add(const Duration(seconds: 1)))).toList();
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
    Uri make(String base, String fn) => Uri.parse('${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/$fn');

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
        debugPrint('fetchExternalEvents: functions.invoke failed, trying HTTP fallback. Error: $e');
      }

      // 2) Fallback to direct HTTP if functions base is provided (for dev/no-auth cases)
      final base = AppConfig.supabaseFunctionsBaseUrl;
      if (base.isEmpty) {
        debugPrint('fetchExternalEvents skipped: no Supabase Functions base URL and invoke failed');
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
        debugPrint('fetchExternalEvents/combined HTTP error: ${res.statusCode} ${res.body}');
        return [];
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
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
        final categoryStr = (item['category']?.toString().toLowerCase() ?? 'other');
        final category = eventCategoryFromString(categoryStr);
        final venueName = (item['venue'] ?? '').toString();
        final address = item['address']?.toString();
        final lat = (item['lat'] is num) ? (item['lat'] as num).toDouble() : null;
        final lon = (item['lon'] is num) ? (item['lon'] as num).toDouble() : null;
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
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
}
