import 'package:flutter/foundation.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Guide Service using Gemini API for Cairo fitness recommendations
class AiGuideService {
  // Using Supabase Edge Function instead of calling Gemini directly from client
  static const String _edgeFunctionName = 'cairo_guide';

  /// Ask the Cairo Guide a question and get AI-powered recommendations
  Future<String> askCairoGuide({
    required String question,
    String? userLocation,
    String? fitnessLevel,
    List<String>? dietaryPreferences,
  }) async {
    try {
      // Build context from user info
      String context = 'User context: ';
      if (userLocation != null) {
        context += 'Currently in $userLocation. ';
      }
      if (fitnessLevel != null) {
        context += 'Fitness level: $fitnessLevel. ';
      }
      if (dietaryPreferences != null && dietaryPreferences.isNotEmpty) {
        context += 'Dietary preferences: ${dietaryPreferences.join(", ")}. ';
      }

      // Call Supabase Edge Function (secured with server-side Gemini key)
      final FunctionsClient functions = SupabaseConfig.client.functions;
      final invokeRes = await functions.invoke(
        _edgeFunctionName,
        body: {
          'question': question,
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
      debugPrint('AiGuideService: Empty or invalid response from edge function: ${invokeRes.data}');
      return 'Sorry, I couldn\'t generate a response. Please try again.';
    } catch (e) {
      debugPrint('AiGuideService.askCairoGuide error: $e');
      return 'Sorry, something went wrong. Please check your connection and try again.';
    }
  }

  /// Get quick suggestion responses for common questions
  List<String> getQuickQuestions() {
    return [
      'Best gyms near Zamalek?',
      'Healthy restaurants with outdoor seating?',
      'Running routes along the Nile?',
      'Yoga studios in Maadi?',
      'Where can I hike near Cairo?',
      'Best time to work out in Cairo?',
    ];
  }
}
