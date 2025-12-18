import 'package:flutter/foundation.dart';

/// Centralized app configuration
///
/// IMPORTANT: All API keys MUST be provided via --dart-define at build time
///
/// Build command example:
/// flutter build apk \
///   --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY \
///   --dart-define=GEMINI_API_KEY=YOUR_KEY \
///   --dart-define=SUPABASE_URL=YOUR_URL \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
///
/// For local development, create a file at:
/// .vscode/launch.json or use flutter run with --dart-define flags
class AppConfig {
  // Environment variable keys
  static const String _googlePlacesKeyEnv = 'GOOGLE_PLACES_API_KEY';
  static const String _geminiKeyEnv = 'GEMINI_API_KEY';
  static const String _supabaseUrlEnv = 'SUPABASE_URL';
  static const String _supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';
  static const String _supabaseFunctionsUrlEnv = 'SUPABASE_FUNCTIONS_BASE_URL';

  /// Google Places (New) API Key
  static String get googlePlacesApiKey {
    const key = String.fromEnvironment(_googlePlacesKeyEnv);
    if (key.isEmpty && kReleaseMode) {
      throw Exception('GOOGLE_PLACES_API_KEY is required for production builds');
    }
    if (key.isEmpty && kDebugMode) {
      debugPrint('⚠️ WARNING: Using development fallback for Google Places API key');
      return _devGooglePlacesKey; // Development fallback
    }
    return key;
  }

  /// Gemini API Key for AI Cairo Guide
  static String get geminiApiKey {
    const key = String.fromEnvironment(_geminiKeyEnv);
    if (key.isEmpty && kReleaseMode) {
      throw Exception('GEMINI_API_KEY is required for production builds');
    }
    if (key.isEmpty && kDebugMode) {
      debugPrint('⚠️ WARNING: Using development fallback for Gemini API key');
      return _devGeminiKey; // Development fallback
    }
    return key;
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    const url = String.fromEnvironment(_supabaseUrlEnv);
    if (url.isEmpty && kReleaseMode) {
      throw Exception('SUPABASE_URL is required for production builds');
    }
    if (url.isEmpty && kDebugMode) {
      debugPrint('⚠️ WARNING: Using development fallback for Supabase URL');
      return _devSupabaseUrl; // Development fallback
    }
    return url;
  }

  /// Supabase Anonymous Key
  static String get supabaseAnonKey {
    const key = String.fromEnvironment(_supabaseAnonKeyEnv);
    if (key.isEmpty && kReleaseMode) {
      throw Exception('SUPABASE_ANON_KEY is required for production builds');
    }
    if (key.isEmpty && kDebugMode) {
      debugPrint('⚠️ WARNING: Using development fallback for Supabase anon key');
      return _devSupabaseAnonKey; // Development fallback
    }
    return key;
  }

  /// Supabase Edge Functions base URL
  /// Example: https://your-project-ref.functions.supabase.co
  static String get supabaseFunctionsBaseUrl {
    const url = String.fromEnvironment(_supabaseFunctionsUrlEnv);
    if (url.isEmpty && kDebugMode) {
      debugPrint('⚠️ WARNING: Using development fallback for Supabase Functions URL');
      return _devSupabaseFunctionsUrl;
    }
    return url;
  }

  // Development fallback keys - ONLY used in debug mode
  // These are kept in a separate section to make it clear they should never be used in production
  static const String _devGooglePlacesKey = 'AIzaSyBCkxTR7keDd_gXjXOrj8pptvboMUfg-3Q';
  static const String _devGeminiKey = 'AIzaSyBZ9OgP8A0CZhYa1u_XILJihBUXg3Ps-xM';
  static const String _devSupabaseUrl = 'https://lwyuwxqwshflmuefxgay.supabase.co';
  static const String _devSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3eXV3eHF3c2hmbG11ZWZ4Z2F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MzA5MTgsImV4cCI6MjA4MTQwNjkxOH0.Ias3yQUV8p7D825WwBI08Njry4aQ_OiMkrQRGfwl7zw';
  static const String _devSupabaseFunctionsUrl = 'https://lwyuwxqwshflmuefxgay.functions.supabase.co';

  /// Validate all required configuration is present
  static void validate() {
    try {
      // Access all getters to trigger validation
      googlePlacesApiKey;
      geminiApiKey;
      supabaseUrl;
      supabaseAnonKey;

      if (kDebugMode) {
        debugPrint('✅ AppConfig validation passed');
      }
    } catch (e) {
      debugPrint('❌ AppConfig validation failed: $e');
      rethrow;
    }
  }
}
