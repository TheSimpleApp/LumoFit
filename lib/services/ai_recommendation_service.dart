import 'package:flutter/foundation.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/supabase/supabase_config.dart';

/// Service for AI-powered event and place recommendations using AIML API
class AiRecommendationService extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Get personalized event recommendations using AIML
  Future<AiRecommendationResult> getRecommendations({
    required String query,
    List<EventModel>? candidateEvents,
    double? userLat,
    double? userLng,
    String? fitnessLevel,
    List<String>? preferences,
    String model = 'gpt-4o-mini',
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Prepare event data for AI context
      List<Map<String, dynamic>>? eventData;
      if (candidateEvents != null && candidateEvents.isNotEmpty) {
        eventData = candidateEvents
            .take(20)
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'category': e.category.name,
                  'start': e.start.toIso8601String(),
                  'venue': e.venueName,
                  if (e.distanceKm != null) 'distance': e.distanceKm,
                })
            .toList();
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'aiml_recommendations',
        body: {
          'query': query,
          'model': model,
          'userProfile': {
            if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
            if (preferences != null) 'preferences': preferences,
            if (userLat != null && userLng != null)
              'location': {'lat': userLat, 'lng': userLng},
          },
          if (eventData != null) 'availableEvents': eventData,
        },
      );

      final data = response.data as Map<String, dynamic>;

      _isLoading = false;
      notifyListeners();

      return AiRecommendationResult(
        text: data['text'] as String? ?? 'No recommendations available.',
        model: data['model'] as String? ?? model,
        success: true,
      );
    } catch (e) {
      debugPrint('AiRecommendationService.getRecommendations error: $e');
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();

      return AiRecommendationResult(
        text: 'Unable to get recommendations. Please try again.',
        model: model,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Parse natural language query into structured search intent
  Future<SearchIntent> parseQuery(String query) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'aiml_recommendations',
        body: {
          'query':
              '''Parse this fitness search query and extract structured data.
Query: "$query"

Respond with JSON only:
{
  "eventType": "running|yoga|hiking|cycling|crossfit|bootcamp|swimming|groupFitness|triathlon|obstacle|other|null",
  "datePreference": "today|this_weekend|next_7_days|next_30_days|null",
  "maxDistanceKm": number or null,
  "keywords": ["list", "of", "keywords"]
}''',
          'model': 'gpt-4o-mini',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final text = data['text'] as String? ?? '{}';

      // Try to parse JSON from response
      return SearchIntent.fromAiResponse(text);
    } catch (e) {
      debugPrint('AiRecommendationService.parseQuery error: $e');
      return SearchIntent();
    }
  }

  /// Get quick fitness tips for a location
  Future<String> getLocationTips({
    required String destination,
    double? lat,
    double? lng,
    String? fitnessLevel,
  }) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'aiml_recommendations',
        body: {
          'query':
              'Give me 3-4 quick fitness tips for staying active while traveling to $destination. Be specific and practical.',
          'model': 'gpt-4o-mini',
          'userProfile': {
            if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
            if (lat != null && lng != null)
              'location': {'lat': lat, 'lng': lng},
          },
        },
      );

      final data = response.data as Map<String, dynamic>;
      return data['text'] as String? ?? 'Stay active and enjoy your trip!';
    } catch (e) {
      debugPrint('AiRecommendationService.getLocationTips error: $e');
      return 'Stay active and enjoy your trip!';
    }
  }
}

/// Result from AI recommendation
class AiRecommendationResult {
  final String text;
  final String model;
  final bool success;
  final String? error;

  AiRecommendationResult({
    required this.text,
    required this.model,
    required this.success,
    this.error,
  });
}

/// Parsed search intent from natural language query
class SearchIntent {
  final String? eventType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxDistanceKm;
  final List<String> keywords;

  SearchIntent({
    this.eventType,
    this.startDate,
    this.endDate,
    this.maxDistanceKm,
    this.keywords = const [],
  });

  factory SearchIntent.fromAiResponse(String jsonText) {
    try {
      // Extract JSON from response (may be wrapped in markdown code blocks)
      String cleanJson = jsonText;
      if (jsonText.contains('```')) {
        final match =
            RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(jsonText);
        if (match != null) {
          cleanJson = match.group(1) ?? jsonText;
        }
      }

      // Simple JSON parsing - in production use dart:convert
      final eventTypeMatch =
          RegExp(r'"eventType"\s*:\s*"([^"]+)"').firstMatch(cleanJson);
      final distanceMatch =
          RegExp(r'"maxDistanceKm"\s*:\s*(\d+)').firstMatch(cleanJson);
      final dateMatch =
          RegExp(r'"datePreference"\s*:\s*"([^"]+)"').firstMatch(cleanJson);

      DateTime? startDate;
      DateTime? endDate;
      final now = DateTime.now();

      if (dateMatch != null) {
        switch (dateMatch.group(1)) {
          case 'today':
            startDate = now;
            endDate = now;
            break;
          case 'this_weekend':
            // Find next Saturday
            final daysUntilSaturday = (6 - now.weekday) % 7;
            startDate = now.add(
                Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday));
            endDate = startDate.add(const Duration(days: 1));
            break;
          case 'next_7_days':
            startDate = now;
            endDate = now.add(const Duration(days: 7));
            break;
          case 'next_30_days':
            startDate = now;
            endDate = now.add(const Duration(days: 30));
            break;
        }
      }

      return SearchIntent(
        eventType: eventTypeMatch?.group(1),
        startDate: startDate,
        endDate: endDate,
        maxDistanceKm: distanceMatch != null
            ? int.tryParse(distanceMatch.group(1)!)
            : null,
      );
    } catch (e) {
      debugPrint('SearchIntent.fromAiResponse parse error: $e');
      return SearchIntent();
    }
  }

  /// Convert to EventCategory if possible
  EventCategory? get eventCategory {
    if (eventType == null) return null;
    return eventCategoryFromString(eventType!);
  }
}
