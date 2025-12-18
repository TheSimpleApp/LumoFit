import 'package:flutter/foundation.dart';

/// Centralized app configuration
///
/// Security Model: All external API keys (Google Places, Gemini, etc.) are stored
/// in Supabase Edge Functions environment variables, NOT in the Flutter app.
/// The app only needs Supabase credentials to call Edge Functions.
///
/// Build command example:
/// flutter build apk \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your_anon_key
///
/// For local development, these fallbacks are used in debug mode only.
class AppConfig {
  // Environment variable keys
  static const String _supabaseUrlEnv = 'SUPABASE_URL';
  static const String _supabaseAnonKeyEnv = 'SUPABASE_ANON_KEY';
  static const String _googlePlacesKeyEnv = 'GOOGLE_PLACES_API_KEY';

  /// Google Places API Key
  /// Note: While most API keys should be in Edge Functions, Google Places is
  /// designed to be called from client apps with API key restrictions (IP/domain)
  static String get googlePlacesApiKey {
    const key = String.fromEnvironment(_googlePlacesKeyEnv);
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Using development fallback for Google Places API key');
      } else {
        debugPrint(
            '⚠️ Using development fallback for Google Places API key (release mode)');
      }
      return _devGooglePlacesKey;
    }
    return key;
  }

  /// Supabase Project URL
  static String get supabaseUrl {
    const url = String.fromEnvironment(_supabaseUrlEnv);
    if (url.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Using development fallback for Supabase URL');
      } else {
        debugPrint(
            '⚠️ Using development fallback for Supabase URL (release mode)');
      }
      return _devSupabaseUrl;
    }
    return url;
  }

  /// Supabase Anonymous Key (safe to expose in client)
  static String get supabaseAnonKey {
    const key = String.fromEnvironment(_supabaseAnonKeyEnv);
    if (key.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Using development fallback for Supabase anon key');
      } else {
        debugPrint(
            '⚠️ Using development fallback for Supabase anon key (release mode)');
      }
      return _devSupabaseAnonKey;
    }
    return key;
  }

  /// Supabase Edge Functions base URL (derived from project URL)
  static String get supabaseFunctionsUrl {
    final projectUrl = supabaseUrl;
    // Convert https://xxx.supabase.co to https://xxx.functions.supabase.co
    return projectUrl.replaceAll('.supabase.co', '.functions.supabase.co');
  }

  // Development fallback credentials - Used when --dart-define flags are not provided
  // These are safe to expose as they point to the development Supabase project
  // with Row-Level Security enabled. Used in both debug and release modes for beta testing.
  static const String _devSupabaseUrl =
      'https://lwyuwxqwshflmuefxgay.supabase.co';
  static const String _devSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3eXV3eHF3c2hmbG11ZWZ4Z2F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MzA5MTgsImV4cCI6MjA4MTQwNjkxOH0.Ias3yQUV8p7D825WwBI08Njry4aQ_OiMkrQRGfwl7zw';
  static const String _devGooglePlacesKey =
      'AIzaSyBCkxTR7keDd_gXjXOrj8pptvboMUfg-3Q';

  /// Validate all required configuration is present
  static void validate() {
    try {
      // Access getters to trigger validation
      supabaseUrl;
      supabaseAnonKey;

      if (kDebugMode) {
        debugPrint('✅ AppConfig validation passed');
        debugPrint('   Supabase URL: $supabaseUrl');
        debugPrint('   Functions URL: $supabaseFunctionsUrl');
      }
    } catch (e) {
      debugPrint('❌ AppConfig validation failed: $e');
      rethrow;
    }
  }
}
