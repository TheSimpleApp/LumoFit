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
}
