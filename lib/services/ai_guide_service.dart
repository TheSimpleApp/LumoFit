import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fittravel/config/app_config.dart';

/// AI Guide Service using Gemini API for Cairo fitness recommendations
class AiGuideService {
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

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

      // System prompt
      final systemPrompt = '''You are a Cairo fitness travel expert helping visitors find gyms, healthy restaurants, fitness events, and outdoor activities in Cairo, Egypt.

Your role:
- Provide practical, actionable recommendations with specific place names and neighborhoods
- Focus on real places in Cairo (Zamalek, Maadi, Heliopolis, New Cairo, Downtown, Giza)
- Mention popular spots like Gold's Gym, CrossFit Hustle, Cairo Runners, Wadi Degla, Nile Corniche
- Include helpful details like opening hours, price ranges, what to bring
- Be encouraging and enthusiastic about Cairo's fitness scene
- Keep responses concise (2-3 paragraphs max)

$context

User question: $question''';

      final response = await http.post(
        Uri.parse('$_apiUrl?key=${AppConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract text from Gemini response
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            return candidate['content']['parts'][0]['text'] ??
                   'Sorry, I couldn\'t generate a response. Please try again.';
          }
        }

        return 'Sorry, I couldn\'t generate a response. Please try again.';
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      }
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
