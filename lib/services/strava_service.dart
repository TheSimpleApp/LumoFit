import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fittravel/supabase/supabase_config.dart';

/// Service for Strava OAuth and API integration
class StravaService extends ChangeNotifier {
  static const String clientId = '192036';
  static const String _redirectUri = 'http://localhost/strava/callback';
  static const String _scope = 'read,activity:read,read_all';

  final _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  int? _expiresAt;
  StravaAthlete? _athlete;
  bool _isLoading = false;

  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  StravaAthlete? get athlete => _athlete;

  /// Initialize service - load stored tokens
  Future<void> initialize() async {
    try {
      _accessToken = await _storage.read(key: 'strava_access_token');
      _refreshToken = await _storage.read(key: 'strava_refresh_token');
      final expiresAtStr = await _storage.read(key: 'strava_expires_at');
      _expiresAt = expiresAtStr != null ? int.tryParse(expiresAtStr) : null;

      if (_accessToken != null) {
        await _refreshTokenIfNeeded();
        await _fetchAthlete();
      }
    } catch (e) {
      debugPrint('StravaService.initialize error: $e');
    }
    notifyListeners();
  }

  /// Start OAuth flow - opens Strava login in browser
  Future<void> authenticate() async {
    final authUrl = Uri.parse(
      'https://www.strava.com/oauth/authorize'
      '?client_id=$clientId'
      '&redirect_uri=$_redirectUri'
      '&response_type=code'
      '&scope=$_scope',
    );

    try {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('StravaService.authenticate error: $e');
    }
  }

  /// Handle OAuth callback - call this when app receives callback URL
  Future<bool> handleCallback(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'strava_api',
        body: {'action': 'token_exchange', 'code': code},
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('access_token')) {
        await _saveTokens(
          data['access_token'] as String,
          data['refresh_token'] as String,
          data['expires_at'] as int,
        );

        await _fetchAthlete();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Strava token exchange failed: ${data['message']}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('StravaService.handleCallback error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    if (_expiresAt == null || _refreshToken == null) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_expiresAt! < now + 300) {
      // Refresh 5 min before expiry
      try {
        final response = await SupabaseConfig.client.functions.invoke(
          'strava_api',
          body: {'action': 'refresh_token', 'refreshToken': _refreshToken},
        );

        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('access_token')) {
          await _saveTokens(
            data['access_token'] as String,
            data['refresh_token'] as String,
            data['expires_at'] as int,
          );
        }
      } catch (e) {
        debugPrint('StravaService._refreshTokenIfNeeded error: $e');
      }
    }
  }

  Future<void> _saveTokens(String access, String refresh, int expiresAt) async {
    _accessToken = access;
    _refreshToken = refresh;
    _expiresAt = expiresAt;

    await _storage.write(key: 'strava_access_token', value: access);
    await _storage.write(key: 'strava_refresh_token', value: refresh);
    await _storage.write(key: 'strava_expires_at', value: expiresAt.toString());
  }

  Future<void> _fetchAthlete() async {
    if (_accessToken == null) return;

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'strava_api',
        body: {'action': 'get_athlete', 'accessToken': _accessToken},
      );

      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('id')) {
        _athlete = StravaAthlete.fromJson(data);
      }
    } catch (e) {
      debugPrint('StravaService._fetchAthlete error: $e');
    }
  }

  /// Explore running/cycling segments in an area
  Future<List<StravaSegment>> exploreSegments({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    String activityType = 'running',
  }) async {
    await _refreshTokenIfNeeded();
    if (_accessToken == null) return [];

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'strava_api',
        body: {
          'action': 'explore_segments',
          'accessToken': _accessToken,
          'activityType': activityType,
          'bounds': {
            'swLat': swLat,
            'swLng': swLng,
            'neLat': neLat,
            'neLng': neLng,
          },
        },
      );

      final data = response.data as Map<String, dynamic>;
      final segments = (data['segments'] as List?) ?? [];
      return segments
          .map((s) => StravaSegment.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('StravaService.exploreSegments error: $e');
      return [];
    }
  }

  /// Get user's clubs
  Future<List<StravaClub>> getClubs() async {
    await _refreshTokenIfNeeded();
    if (_accessToken == null) return [];

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'strava_api',
        body: {'action': 'get_clubs', 'accessToken': _accessToken},
      );

      final clubs = (response.data as List?) ?? [];
      return clubs
          .map((c) => StravaClub.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('StravaService.getClubs error: $e');
      return [];
    }
  }

  /// Disconnect Strava account
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _athlete = null;

    await _storage.delete(key: 'strava_access_token');
    await _storage.delete(key: 'strava_refresh_token');
    await _storage.delete(key: 'strava_expires_at');

    notifyListeners();
  }
}

/// Strava athlete profile
class StravaAthlete {
  final int id;
  final String firstname;
  final String lastname;
  final String? profileMedium;
  final String? city;
  final String? country;

  StravaAthlete({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.profileMedium,
    this.city,
    this.country,
  });

  String get fullName => '$firstname $lastname';

  factory StravaAthlete.fromJson(Map<String, dynamic> json) {
    return StravaAthlete(
      id: json['id'] as int,
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      profileMedium: json['profile_medium'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
}

/// Strava segment (popular route)
class StravaSegment {
  final int id;
  final String name;
  final double distance;
  final double avgGrade;
  final double elevHigh;
  final double elevLow;
  final List<List<double>> points; // lat/lng pairs for polyline

  StravaSegment({
    required this.id,
    required this.name,
    required this.distance,
    required this.avgGrade,
    required this.elevHigh,
    required this.elevLow,
    required this.points,
  });

  /// Distance formatted as string
  String get distanceFormatted {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    }
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }

  factory StravaSegment.fromJson(Map<String, dynamic> json) {
    return StravaSegment(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      avgGrade: (json['avg_grade'] as num?)?.toDouble() ?? 0,
      elevHigh: (json['elev_high'] as num?)?.toDouble() ?? 0,
      elevLow: (json['elev_low'] as num?)?.toDouble() ?? 0,
      points: _decodePolyline(json['points'] as String? ?? ''),
    );
  }

  /// Decode Google polyline format to lat/lng pairs
  static List<List<double>> _decodePolyline(String encoded) {
    List<List<double>> points = [];
    if (encoded.isEmpty) return points;

    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add([lat / 1E5, lng / 1E5]);
    }
    return points;
  }
}

/// Strava club
class StravaClub {
  final int id;
  final String name;
  final String? profileMedium;
  final String? city;
  final String? country;
  final int memberCount;
  final String sportType;

  StravaClub({
    required this.id,
    required this.name,
    this.profileMedium,
    this.city,
    this.country,
    required this.memberCount,
    required this.sportType,
  });

  factory StravaClub.fromJson(Map<String, dynamic> json) {
    return StravaClub(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      profileMedium: json['profile_medium'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      sportType: json['sport_type'] as String? ?? 'other',
    );
  }
}
