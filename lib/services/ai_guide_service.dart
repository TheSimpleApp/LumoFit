import 'package:flutter/foundation.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// We stick to Gemini via Supabase Edge Functions. No OpenAI fallback.

/// AI Guide Service for fitness recommendations worldwide
///
/// Provides AI-powered features:
/// - Global fitness guide (location-aware recommendations)
/// - Fitness itinerary generation
/// - Place insights with caching
/// - AIML-powered smart recommendations
class AiGuideService {
  // Edge function names
  static const String _cairoGuideFn = 'cairo_guide';
  static const String _egyptGuideFn = 'egypt_fitness_guide';
  static const String _itineraryFn = 'generate_fitness_itinerary';
  static const String _insightsFn = 'get_place_insights';
  static const String _fitnessIntelFn = 'analyze_place_fitness';
  static const String _quickInsightsFn = 'generate_quick_insights';

  // Conversation history for context-aware responses
  final List<AiChatMessage> _conversationHistory = [];

  /// Get current conversation history
  List<AiChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Ask the Cairo Guide a question and get AI-powered recommendations
  Future<String> askCairoGuide({
    required String question,
    String? userLocation,
    String? fitnessLevel,
    List<String>? dietaryPreferences,
  }) async {
    try {
      // Call Supabase Edge Function (secured with server-side Gemini key)
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _cairoGuideFn,
        body: {
          'question': question,
          // Prefer Gemini 2.5 Flash if the function supports model override
          'model': 'gemini-2.5-flash',
          if (userLocation != null) 'userLocation': userLocation,
          if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
          if (dietaryPreferences != null && dietaryPreferences.isNotEmpty)
            'dietaryPreferences': dietaryPreferences,
        },
      );

      // The edge function returns JSON { text: string }
      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        final text = data['text'] as String?;
        if (text != null && text.trim().isNotEmpty) return text;
      }

      // If we reach here, either parsing failed or text is empty
      debugPrint(
          'AiGuideService: Empty or invalid response from edge function: ${invokeRes.data}');
      return 'Sorry, I couldn\'t get a response right now. Please try again in a moment.';
    } catch (e) {
      debugPrint('AiGuideService.askCairoGuide error: $e');
      return 'Sorry, something went wrong. Please check your connection and try again.';
    }
  }

  // OpenAI fallback removed per product decision – Gemini only.

  /// Get quick suggestion responses for common questions
  List<String> getQuickQuestions() {
    return [
      'Best gyms near me?',
      'Healthy restaurants nearby?',
      'Running routes in the area?',
      'Parks for outdoor workouts?',
      'What\'s good for a quick workout?',
    ];
  }

  /// Check if the message indicates a guided search start
  bool _isGuidedSearchRequest(String message) {
    final lower = message.toLowerCase();
    return lower.contains('start guided') ||
        lower.contains('guided search') ||
        lower.contains('help me find') ||
        lower.contains('what should i do');
  }

  // ========================================
  // Global Fitness AI Guide Methods
  // ========================================

  /// Ask the fitness guide a question with full context
  /// Works globally with any destination
  ///
  /// Returns structured response with text and suggested places
  Future<FitnessGuideResponse> askFitnessGuide({
    required String question,
    String? destination,
    double? userLat,
    double? userLng,
    Map<String, double>? mapBounds,
    String? fitnessLevel,
    List<String>? dietaryPreferences,
  }) =>
      // ignore: deprecated_member_use_from_same_package
      askEgyptGuide(
        question: question,
        destination: destination,
        userLat: userLat,
        userLng: userLng,
        mapBounds: mapBounds,
        fitnessLevel: fitnessLevel,
        dietaryPreferences: dietaryPreferences,
      );

  /// Legacy method - use askFitnessGuide instead
  /// Kept for backward compatibility
  @Deprecated('Use askFitnessGuide instead')
  Future<EgyptGuideResponse> askEgyptGuide({
    required String question,
    String? destination,
    double? userLat,
    double? userLng,
    Map<String, double>? mapBounds,
    String? fitnessLevel,
    List<String>? dietaryPreferences,
  }) async {
    try {
      // Add user message to history
      _conversationHistory.add(AiChatMessage.user(question));

      // Build conversation history for context
      final historyForApi = _conversationHistory
          .take(10) // Limit history to last 10 messages
          .map((m) =>
              {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
          .toList();

      // Enhance question for guided search
      String enhancedQuestion = question;
      if (_isGuidedSearchRequest(question) &&
          _conversationHistory.length <= 2) {
        enhancedQuestion = '''
I want to start a guided search for fitness places. Please ask me questions to understand:
1. What type of place I'm looking for (gym, restaurant, park, trail, etc.)
2. How much time I have available
3. Any specific preferences (budget, amenities, location)
4. My fitness goals or dietary preferences

Start by asking the first question to begin the guided conversation.
''';
      }

      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _egyptGuideFn,
        body: {
          'question': enhancedQuestion,
          if (destination != null) 'destination': destination,
          if (userLat != null && userLng != null)
            'userLocation': {'lat': userLat, 'lng': userLng},
          if (mapBounds != null) 'mapBounds': mapBounds,
          if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
          if (dietaryPreferences != null && dietaryPreferences.isNotEmpty)
            'dietaryPreferences': dietaryPreferences,
          'conversationHistory': historyForApi,
          'isGuidedSearch': _isGuidedSearchRequest(question),
        },
      );

      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        final response = EgyptGuideResponse.fromJson(data);

        // Add assistant response to history
        _conversationHistory.add(AiChatMessage.assistant(
          response.text,
          suggestedPlaces: response.suggestedPlaces,
        ));

        return response;
      }

      debugPrint(
          'AiGuideService: Invalid response from egypt_fitness_guide: ${invokeRes.data}');
      return const EgyptGuideResponse(
        text:
            'Sorry, I couldn\'t get a response right now. Please try again shortly.',
      );
    } catch (e) {
      debugPrint('AiGuideService.askEgyptGuide error: $e');
      return const EgyptGuideResponse(
        text:
            'Sorry, something went wrong. Please check your connection and try again.',
      );
    }
  }

  /// Generate a fitness itinerary for a destination
  Future<ItineraryResponse?> generateItinerary({
    required String destination,
    required DateTime date,
    String? fitnessLevel,
    List<String>? focusAreas,
  }) async {
    try {
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _itineraryFn,
        body: {
          'destination': destination,
          'date': date.toIso8601String().split('T').first,
          if (fitnessLevel != null) 'fitnessLevel': fitnessLevel,
          if (focusAreas != null && focusAreas.isNotEmpty)
            'focusAreas': focusAreas,
        },
      );

      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        return ItineraryResponse.fromJson(data);
      }

      debugPrint(
          'AiGuideService: Invalid response from generate_fitness_itinerary: ${invokeRes.data}');
      return null;
    } catch (e) {
      debugPrint('AiGuideService.generateItinerary error: $e');
      return null;
    }
  }

  /// Get AI-generated insights for a specific place
  ///
  /// Results are cached server-side for 7 days
  Future<PlaceInsights?> getPlaceInsights({
    required String placeName,
    required String placeType,
    required String destination,
    String? googlePlaceId,
  }) async {
    try {
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _insightsFn,
        body: {
          'placeName': placeName,
          'placeType': placeType,
          'destination': destination,
          if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
        },
      );

      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        final insights = data['insights'] as Map<String, dynamic>?;
        if (insights != null) {
          return PlaceInsights.fromJson(insights);
        }
      }

      debugPrint(
          'AiGuideService: Invalid response from get_place_insights: ${invokeRes.data}');
      return null;
    } catch (e) {
      debugPrint('AiGuideService.getPlaceInsights error: $e');
      return null;
    }
  }

  /// Get quick questions for a specific Egypt destination
  List<String> getQuickQuestionsForDestination(String destination) {
    switch (destination.toLowerCase()) {
      case 'cairo':
        return [
          'Best gyms near Zamalek?',
          'Healthy restaurants with outdoor seating?',
          'Running routes along the Nile?',
          'Yoga studios in Maadi?',
        ];
      case 'luxor':
        return [
          'Best time to run near the temples?',
          'Gyms in Luxor with day passes?',
          'Healthy breakfast spots on East Bank?',
          'Cycling routes near Valley of the Kings?',
        ];
      case 'aswan':
        return [
          'Swimming spots near Elephantine Island?',
          'Running routes along the Nile?',
          'Yoga retreats in Nubian villages?',
          'Best healthy food in Aswan?',
        ];
      case 'hurghada':
        return [
          'Best beach yoga classes?',
          'Gyms with sea views?',
          'Diving fitness requirements?',
          'Healthy restaurants in El Gouna?',
        ];
      case 'sharm el sheikh':
        return [
          'Best resort gyms with day passes?',
          'Hiking trails in Sinai?',
          'Snorkeling fitness spots?',
          'Healthy eating in Naama Bay?',
        ];
      case 'alexandria':
        return [
          'Running routes on the Corniche?',
          'Best gyms in Alexandria?',
          'Mediterranean swimming spots?',
          'Healthy seafood restaurants?',
        ];
      case 'dahab':
        return [
          'Freediving schools and fitness?',
          'Desert yoga retreats?',
          'Kitesurfing lessons?',
          'Healthy cafes in Dahab?',
        ];
      case 'siwa':
        return [
          'Desert cycling routes?',
          'Hot springs for recovery?',
          'Sunrise yoga spots?',
          'Organic food in Siwa?',
        ];
      default:
        return getQuickQuestions();
    }
  }

  /// Analyze a place for fitness intelligence using AI
  ///
  /// Extracts fitness/health insights from place data and community reviews
  /// Results are cached server-side for 24 hours
  Future<PlaceFitnessIntelligence?> analyzePlaceFitness({
    required String placeId,
    required String placeName,
    required String placeType,
    List<Map<String, dynamic>>? reviews,
    Map<String, dynamic>? placeData,
  }) async {
    try {
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _fitnessIntelFn,
        body: {
          'placeId': placeId,
          'placeName': placeName,
          'placeType': placeType,
          if (reviews != null && reviews.isNotEmpty) 'reviews': reviews,
          if (placeData != null) 'placeData': placeData,
        },
      );

      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        final intelligence = data['intelligence'] as Map<String, dynamic>?;
        if (intelligence != null) {
          return PlaceFitnessIntelligence.fromJson(intelligence);
        }
      }

      debugPrint(
          'AiGuideService: Invalid response from analyze_place_fitness: ${invokeRes.data}');
      return null;
    } catch (e) {
      debugPrint('AiGuideService.analyzePlaceFitness error: $e');
      return null;
    }
  }

  /// Generate quick insights for a place using a lighter AI model
  ///
  /// This provides fast, lightweight overview tags from Google reviews
  /// to help users quickly understand a place while browsing
  /// Uses Gemini 2.5 Flash for speed. Results are cached for 7 days.
  Future<PlaceQuickInsights?> generateQuickInsights({
    required String placeName,
    required String placeType,
    required double? rating,
    required int? reviewCount,
    String? googlePlaceId,
  }) async {
    try {
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _quickInsightsFn,
        body: {
          'placeName': placeName,
          'placeType': placeType,
          'rating': rating,
          'reviewCount': reviewCount,
          if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
          // Request lightweight model for speed
          'model': 'gemini-2.0-flash-exp',
        },
      );

      if (invokeRes.data is Map) {
        final data = (invokeRes.data as Map).cast<String, dynamic>();
        final insights = data['insights'] as Map<String, dynamic>?;
        if (insights != null) {
          return PlaceQuickInsights.fromJson(insights);
        }
      }

      debugPrint(
          'AiGuideService: Invalid response from generate_quick_insights: ${invokeRes.data}');
      return null;
    } catch (e) {
      // Suppress 404 errors (function not deployed) to avoid log spam
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        debugPrint(
            'AiGuideService: generate_quick_insights function not deployed, skipping insights.');
      } else {
        debugPrint('AiGuideService.generateQuickInsights error: $e');
      }
      return null;
    }
  }
}
