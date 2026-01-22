import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/supabase/supabase_config.dart';

const String _n8nWebhookUrl = 'https://thesimpleapp.app.n8n.cloud/webhook/lifestyle-events';

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
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _currentCity == city && _destinationEvents.isNotEmpty) {
      // Already have events for this city, use cached
      debugPrint('EventService: Using cached ${_destinationEvents.length} events for $city');
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
  /// Searches both general events and destination-specific events.
  /// If destinationOnly is true, only searches _destinationEvents for the current city.
  List<EventModel> search({
    required String query,
    Set<EventCategory>? categories,
    DateTime? startDate,
    DateTime? endDate,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    bool destinationOnly = false,
  }) {
    List<EventModel> out;

    if (destinationOnly && _destinationEvents.isNotEmpty) {
      // Only use destination events (for trip-specific views)
      out = List.from(_destinationEvents);
    } else {
      // Combine all events and deduplicate by ID
      final allEvents = <String, EventModel>{};
      for (final e in _events) {
        allEvents[e.id] = e;
      }
      for (final e in _destinationEvents) {
        allEvents[e.id] = e;
      }
      out = allEvents.values.toList();
    }

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

  /// Discover events for a location using the n8n webhook
  /// This fetches events from multiple sources and saves them to Supabase
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

      // Parse city/state/country from location name
      final parts = locationName.split(',').map((s) => s.trim()).toList();
      final city = parts.isNotEmpty ? parts[0] : locationName;
      final state = parts.length > 1 ? parts[1] : null;
      final country = parts.length > 2 ? parts.last : 'USA';

      // Calculate date range (today to 3 months from now)
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 3, now.day);

      // Call n8n webhook to discover events
      final events = await _fetchEventsFromN8n(
        city: city,
        state: state,
        country: country,
        startDate: now,
        endDate: endDate,
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint('EventService: n8n returned ${events.length} events');

      if (events.isEmpty) {
        _lastDiscoveryError = 'No events found for this location';
        notifyListeners();
        _isDiscoveringEvents = false;
        return;
      }

      // Save events to Supabase
      await _saveEventsToSupabase(events, city, country);

      // Reload events from Supabase (force refresh to get new events)
      await _loadEventsFromSupabase();
      await fetchEventsForCity(city: city, forceRefresh: true);

      debugPrint('EventService: Successfully saved and loaded ${events.length} events');
    } catch (e, st) {
      debugPrint('EventService.discoverEventsForLocation error: $e');
      debugPrint(st.toString());
      _lastDiscoveryError = 'Failed to discover events: ${e.toString()}';
    } finally {
      _isDiscoveringEvents = false;
      notifyListeners();
    }
  }

  /// Fetch events from the n8n webhook
  Future<List<Map<String, dynamic>>> _fetchEventsFromN8n({
    required String city,
    String? state,
    String? country,
    required DateTime startDate,
    required DateTime endDate,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': city,
          if (state != null) 'state': state,
          'country': country ?? 'USA',
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('n8n webhook error: ${response.statusCode} - ${response.body}');
        return [];
      }

      // Parse the response - n8n returns markdown-wrapped JSON
      String content = response.body;

      // Try to parse as JSON first
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('n8n response not direct JSON, trying to extract');
        return [];
      }

      // Check if response has 'output' field with markdown-wrapped JSON
      if (parsed.containsKey('output')) {
        String output = parsed['output'] as String;

        // Remove markdown code fences if present
        final codeFenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(output);
        if (codeFenceMatch != null) {
          output = codeFenceMatch.group(1) ?? output;
        }

        try {
          parsed = jsonDecode(output) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Failed to parse n8n output JSON: $e');
          return [];
        }
      }

      // Extract events array
      final events = parsed['events'] as List<dynamic>? ?? [];
      return events.cast<Map<String, dynamic>>();
    } catch (e, st) {
      debugPrint('_fetchEventsFromN8n error: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// Save events to Supabase
  Future<void> _saveEventsToSupabase(
    List<Map<String, dynamic>> events,
    String city,
    String? country,
  ) async {
    try {
      final eventsToInsert = events.map((e) {
        final details = e['details'] as Map<String, dynamic>? ?? {};
        final tags = (e['tags'] as List<dynamic>?)?.cast<String>() ?? [];

        // Parse date and time from n8n format
        final dateStr = details['date'] as String? ?? '';
        final timeStr = details['time'] as String? ?? '';
        DateTime? startDate;
        DateTime? endDate;

        if (dateStr.isNotEmpty) {
          try {
            // Parse date (YYYY-MM-DD format)
            startDate = DateTime.parse(dateStr);

            // Try to parse time range (e.g., "6:00 PM" or "6:00 PM - 7:00 PM")
            if (timeStr.isNotEmpty) {
              final timeParts = timeStr.split(' - ');
              final startTime = _parseTime(timeParts[0].trim());
              if (startTime != null) {
                startDate = DateTime(
                  startDate.year, startDate.month, startDate.day,
                  startTime.hour, startTime.minute,
                );
              }
              if (timeParts.length > 1) {
                final endTime = _parseTime(timeParts[1].trim());
                if (endTime != null) {
                  endDate = DateTime(
                    startDate.year, startDate.month, startDate.day,
                    endTime.hour, endTime.minute,
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Failed to parse date: $dateStr - $e');
          }
        }

        // Map tags to category
        String category = 'other';
        for (final tag in tags) {
          final mapped = _mapTagToCategory(tag);
          if (mapped != 'other') {
            category = mapped;
            break;
          }
        }

        // Generate unique external_id
        final title = e['title'] as String? ?? 'Untitled Event';
        final externalId = 'n8n_${city.replaceAll(' ', '_')}_${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').substring(0, min(30, title.length))}_${dateStr.replaceAll('-', '')}';

        return {
          'title': title,
          'category': category,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'description': e['description'] as String?,
          'venue_name': details['location']?.toString().split(',').first ?? 'TBA',
          'address': details['location'] as String?,
          'website_url': e['source_url'] as String?,
          'price_info': details['price'] as String?,
          'source': 'n8n_webhook',
          'external_id': externalId,
          'city': city,
          'country': country,
          'fetched_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        };
      }).where((e) => e['start_date'] != null).toList();

      if (eventsToInsert.isEmpty) {
        debugPrint('No valid events to insert');
        return;
      }

      debugPrint('Inserting ${eventsToInsert.length} events to Supabase...');

      // Upsert events (uses external_id unique constraint)
      await SupabaseConfig.client
          .from('events')
          .upsert(eventsToInsert, onConflict: 'external_id', ignoreDuplicates: true);

      debugPrint('Events saved to Supabase');
    } catch (e, st) {
      debugPrint('_saveEventsToSupabase error: $e');
      debugPrint(st.toString());
    }
  }

  /// Parse time string like "6:00 PM" or "18:00" to DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      timeStr = timeStr.trim().toUpperCase();

      // Handle 12-hour format (6:00 PM)
      final match12 = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(timeStr);
      if (match12 != null) {
        int hour = int.parse(match12.group(1)!);
        final minute = int.parse(match12.group(2)!);
        final period = match12.group(3);

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        return DateTime(2000, 1, 1, hour, minute);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Map event tag to category
  String _mapTagToCategory(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('run') || lower.contains('5k') || lower.contains('10k') || lower.contains('marathon')) return 'running';
    if (lower.contains('yoga') || lower.contains('pilates')) return 'yoga';
    if (lower.contains('hik') || lower.contains('outdoor') || lower.contains('trek')) return 'hiking';
    if (lower.contains('cycl') || lower.contains('bike') || lower.contains('spin')) return 'cycling';
    if (lower.contains('crossfit') || lower.contains('functional')) return 'crossfit';
    if (lower.contains('swim')) return 'swimming';
    if (lower.contains('boot') || lower.contains('hiit') || lower.contains('fitness')) return 'bootcamp';
    if (lower.contains('triath')) return 'triathlon';
    if (lower.contains('obstacle') || lower.contains('spartan')) return 'obstacle';
    if (lower.contains('class') || lower.contains('group')) return 'group_fitness';
    if (lower.contains('martial') || lower.contains('boxing') || lower.contains('mma')) return 'martial_arts';
    if (lower.contains('dance') || lower.contains('zumba')) return 'dance';
    if (lower.contains('climb') || lower.contains('boulder')) return 'climbing';
    if (lower.contains('well') || lower.contains('spa') || lower.contains('meditat')) return 'wellness';
    if (lower.contains('sport') || lower.contains('social')) return 'sports';
    return 'other';
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
