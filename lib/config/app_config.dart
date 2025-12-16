/// Centralized app configuration
/// IMPORTANT: For production, pass GOOGLE_PLACES_API_KEY via --dart-define
/// and remove any hardcoded defaults below.
class AppConfig {
  // Temporary default for development to unblock progress.
  // Replace at build time using: --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY
  static const String _devFallbackPlacesKey =
      'AIzaSyBCkxTR7keDd_gXjXOrj8pptvboMUfg-3Q';

  /// Google Places (New) API Key
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: _devFallbackPlacesKey,
  );

  /// Supabase Edge Functions base URL, e.g.
  /// https://<project-ref>.functions.supabase.co
  /// Provide via: --dart-define=SUPABASE_FUNCTIONS_BASE_URL=...
  static const String supabaseFunctionsBaseUrl = String.fromEnvironment(
    'SUPABASE_FUNCTIONS_BASE_URL',
    defaultValue: '',
  );

  /// Optional: If your edge functions require Authorization header, provide
  /// the anon key at build time. If functions are public (verify_jwt=false),
  /// this can be left empty.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
