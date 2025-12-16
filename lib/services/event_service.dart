import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/services/storage_service.dart';
import 'package:fittravel/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Local-first EventService. Seeds a few SLC demo events.
/// Later in Phase 9, replace storage with Supabase tables.
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

  Future<void> _save() async {
    await _storage.setJsonList(StorageKeys.events, _events.map((e) => e.toJson()).toList());
  }

  Future<void> _seed() async {
    final now = DateTime.now();
    final id = const Uuid();
    _events = [
      EventModel(
        id: id.v4(),
        title: 'Liberty Park 5K',
        category: EventCategory.running,
        start: DateTime(now.year, now.month, now.day + 3, 9, 0),
        venueName: 'Liberty Park',
        address: '600 E 900 S, Salt Lake City, UT',
        latitude: 40.7450,
        longitude: -111.8730,
        websiteUrl: 'https://example.com/liberty-park-5k',
        registrationUrl: 'https://example.com/register/5k',
        description: 'Community-friendly timed 5K through the park loop.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Sunrise Yoga at the Gallivan',
        category: EventCategory.yoga,
        start: DateTime(now.year, now.month, now.day + 1, 7, 0),
        venueName: 'Gallivan Center',
        address: '239 Main St, Salt Lake City, UT',
        latitude: 40.7624,
        longitude: -111.8902,
        websiteUrl: 'https://example.com/gallivan-yoga',
        description: 'Bring a mat and water. All levels welcome. Free.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Wasatch Hiking Group: City Creek Trail',
        category: EventCategory.hiking,
        start: DateTime(now.year, now.month, now.day + 5, 8, 30),
        venueName: 'Memory Grove Park',
        address: '375 N Canyon Rd, Salt Lake City, UT',
        latitude: 40.7773,
        longitude: -111.8882,
        websiteUrl: 'https://example.com/wasatch-hike',
        description: 'Moderate 6-mile out-and-back. Bring layers and snacks.',
      ),
      EventModel(
        id: id.v4(),
        title: 'Downtown Cycle Social (20mi)',
        category: EventCategory.cycling,
        start: DateTime(now.year, now.month, now.day + 2, 18, 0),
        venueName: 'Pioneer Park',
        address: '350 S 300 W, Salt Lake City, UT',
        latitude: 40.7644,
        longitude: -111.9011,
        websiteUrl: 'https://example.com/cycle-social',
        description: 'No-drop group ride. Helmets required. Avg 15 mph.',
      ),
      EventModel(
        id: id.v4(),
        title: 'CrossFit Drop-In: Benchmark Saturday',
        category: EventCategory.crossfit,
        start: DateTime(now.year, now.month, now.day + 6, 10, 0),
        venueName: 'CrossFit SLC',
        address: '619 S 600 W, Salt Lake City, UT',
        latitude: 40.7560,
        longitude: -111.9060,
        websiteUrl: 'https://example.com/crossfit-sl',
        description: 'Visitors welcome. Arrive 15 min early for waiver/briefing.',
      ),
    ];
    await _save();
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
  /// Requires SUPABASE_FUNCTIONS_BASE_URL (and typically SUPABASE_ANON_KEY if verify_jwt=true).
  /// Gracefully returns [] if not configured or on error.
  Future<List<EventModel>> fetchExternalEvents({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    int limit = 50,
  }) async {
    final base = AppConfig.supabaseFunctionsBaseUrl;
    if (base.isEmpty) {
      debugPrint('fetchExternalEvents skipped: SUPABASE_FUNCTIONS_BASE_URL not set');
      return [];
    }

    Uri make(String fn) => Uri.parse('${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/$fn');

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

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (AppConfig.supabaseAnonKey.isNotEmpty) 'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
      if (AppConfig.supabaseAnonKey.isNotEmpty) 'apikey': AppConfig.supabaseAnonKey,
    };

    try {
      final res = await http.post(
        make('list_events_combined'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('fetchExternalEvents/combined error: ${res.statusCode} ${res.body}');
        return [];
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
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
          ));
        } catch (e) {
          debugPrint('fetchExternalEvents mapping error: $e');
          continue;
        }
      }

      // Sort soonest first
      out.sort((a, b) => a.start.compareTo(b.start));
      return out;
    } catch (e) {
      debugPrint('fetchExternalEvents/combined exception: $e');
      return [];
    }
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
