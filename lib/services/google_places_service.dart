import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/config/app_config.dart';
import 'package:uuid/uuid.dart';

/// Suggestion model for city autocomplete
/// Contains a friendly description, extracted city, and optional country
class CitySuggestion {
  final String description;
  final String? placeId;
  final String city;
  final String? country;

  CitySuggestion({
    required this.description,
    required this.city,
    this.placeId,
    this.country,
  });
}

/// Service for interacting with Google Places API (New)
class GooglePlacesService {
  static String get _apiKey => AppConfig.googlePlacesApiKey;
  static const String _baseUrl = 'https://places.googleapis.com/v1/places';

  /// Autocomplete destination cities using Google Places Autocomplete API
  /// - Prioritizes locality-level results (cities/towns)
  /// - Returns a lightweight list for UI suggestions
  Future<List<CitySuggestion>> autocompleteCities(String input,
      {String languageCode = 'en', String? regionCode}) async {
    if (input.trim().isEmpty) return [];
    try {
      final uri =
          Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final body = <String, dynamic>{
        'input': input,
        // locality focuses on city-level predictions
        'includedPrimaryTypes': ['locality'],
        'languageCode': languageCode,
      };
      if (regionCode != null && regionCode.isNotEmpty) {
        body['regionCode'] = regionCode;
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          // Ask only for the fields we need to minimize payload
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint(
            'Google Places Autocomplete error: ${response.statusCode} - ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List<dynamic>? ?? []);

      return suggestions.map((raw) {
        final pred = (raw as Map<String, dynamic>)['placePrediction']
            as Map<String, dynamic>?;
        final placeId = pred?['placeId'] as String?;
        // text: { text: 'City, Region, Country' }
        final textObj = pred?['text'] as Map<String, dynamic>?;
        final description = (textObj?['text'] as String?) ?? '';
        // structuredFormat: { mainText: {text: 'City'}, secondaryText: {text: 'Region, Country'} }
        final structured = pred?['structuredFormat'] as Map<String, dynamic>?;
        final mainText = (structured?['mainText']
            as Map<String, dynamic>?)?['text'] as String?;
        final secondaryText = (structured?['secondaryText']
            as Map<String, dynamic>?)?['text'] as String?;

        String city = (mainText ?? description).trim();
        String? country;
        if ((secondaryText ?? description).contains(',')) {
          // Country is generally the last comma-separated part
          final parts = (secondaryText ?? description)
              .split(',')
              .map((e) => e.trim())
              .toList();
          if (parts.isNotEmpty) country = parts.last;
        } else if ((secondaryText ?? '').isNotEmpty) {
          country = secondaryText;
        }

        return CitySuggestion(
          description: description.isEmpty ? city : description,
          placeId: placeId,
          city: city,
          country: country,
        );
      }).toList();
    } catch (e) {
      debugPrint('GooglePlacesService.autocompleteCities error: $e');
      return [];
    }
  }

  /// Search for nearby places by type
  Future<List<PlaceModel>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required PlaceType placeType,
    int radiusMeters = 5000,
  }) async {
    try {
      final includedTypes = _getIncludedTypes(placeType);

      final response = await http.post(
        Uri.parse('$_baseUrl:searchNearby'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.photos,places.websiteUri,places.nationalPhoneNumber',
        },
        body: jsonEncode({
          'includedTypes': includedTypes,
          'maxResultCount': 20,
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': latitude,
                'longitude': longitude,
              },
              'radius': radiusMeters.toDouble(),
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>? ?? [];
        return places.map((p) => _parsePlace(p, placeType)).toList();
      } else {
        debugPrint(
            'Google Places API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('GooglePlacesService.searchNearbyPlaces error: $e');
      return [];
    }
  }

  /// Search places by text query
  Future<List<PlaceModel>> searchPlacesByText({
    required String query,
    required PlaceType placeType,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final includedType = _getIncludedTypes(placeType).first;

      final body = <String, dynamic>{
        'textQuery':
            '$query ${placeType == PlaceType.gym ? 'gym fitness' : 'healthy restaurant'}',
        'includedType': includedType,
        'maxResultCount': 20,
      };

      if (latitude != null && longitude != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 10000.0,
          },
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.photos,places.websiteUri,places.nationalPhoneNumber',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>? ?? [];
        return places.map((p) => _parsePlace(p, placeType)).toList();
      } else {
        debugPrint(
            'Google Places API text search error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('GooglePlacesService.searchPlacesByText error: $e');
      return [];
    }
  }

  /// Get place details by ID
  Future<PlaceModel?> getPlaceDetails(
      String googlePlaceId, PlaceType placeType) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$googlePlaceId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,rating,userRatingCount,priceLevel,currentOpeningHours,photos,websiteUri,nationalPhoneNumber,regularOpeningHours',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parsePlace(data, placeType);
      }
      return null;
    } catch (e) {
      debugPrint('GooglePlacesService.getPlaceDetails error: $e');
      return null;
    }
  }

  /// Get photo URL for a place
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://places.googleapis.com/v1/$photoReference/media?maxWidthPx=$maxWidth&key=$_apiKey';
  }

  /// Geocode a city name to get coordinates
  /// Returns (latitude, longitude) or null if not found
  Future<(double, double)?> geocodeCity(String cityName,
      {String? country}) async {
    try {
      final query = country != null ? '$cityName, $country' : cityName;

      final response = await http.post(
        Uri.parse('$_baseUrl:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.location,places.displayName',
        },
        body: jsonEncode({
          'textQuery': query,
          'includedType': 'locality',
          'maxResultCount': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>? ?? [];
        if (places.isNotEmpty) {
          final location = places.first['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat = (location['latitude'] as num?)?.toDouble();
            final lng = (location['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              debugPrint(
                  'GooglePlacesService.geocodeCity: $query -> ($lat, $lng)');
              return (lat, lng);
            }
          }
        }
      } else {
        debugPrint(
            'Google Places geocode error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('GooglePlacesService.geocodeCity error: $e');
      return null;
    }
  }

  List<String> _getIncludedTypes(PlaceType type) {
    switch (type) {
      case PlaceType.gym:
        // Places v1 supported types: use primary type 'gym' only
        return ['gym'];
      case PlaceType.restaurant:
        // Restrict to supported primary types. Filter healthy via textQuery if needed.
        return ['restaurant', 'cafe'];
      case PlaceType.park:
        return ['park'];
      case PlaceType.trail:
        // 'hiking_area' is not a supported type in Places v1; map to parks.
        return ['park'];
      case PlaceType.other:
        // Use a broad but supported primary type
        return ['tourist_attraction'];
    }
  }

  PlaceModel _parsePlace(Map<String, dynamic> data, PlaceType placeType) {
    final displayName = data['displayName'] as Map<String, dynamic>?;
    final location = data['location'] as Map<String, dynamic>?;
    final openingHours = data['currentOpeningHours'] as Map<String, dynamic>?;
    final regularHours = data['regularOpeningHours'] as Map<String, dynamic>?;
    final photos = data['photos'] as List<dynamic>?;

    List<String> hours = [];
    final weekdayDescriptions = (openingHours?['weekdayDescriptions'] ??
        regularHours?['weekdayDescriptions']) as List<dynamic>?;
    if (weekdayDescriptions != null) {
      hours = weekdayDescriptions.map((e) => e.toString()).toList();
    }

    // Extract multiple photo references (up to 10 photos)
    String? photoRef;
    List<String> photoRefs = [];
    if (photos != null && photos.isNotEmpty) {
      photoRef = photos.first['name'] as String?;
      photoRefs = photos
          .take(10) // Limit to 10 photos for carousel
          .map((p) => p['name'] as String?)
          .whereType<String>()
          .toList();
    }

    String? priceLevel;
    final priceLevelValue = data['priceLevel'] as String?;
    if (priceLevelValue != null) {
      switch (priceLevelValue) {
        case 'PRICE_LEVEL_FREE':
          priceLevel = 'Free';
          break;
        case 'PRICE_LEVEL_INEXPENSIVE':
          priceLevel = '\$';
          break;
        case 'PRICE_LEVEL_MODERATE':
          priceLevel = '\$\$';
          break;
        case 'PRICE_LEVEL_EXPENSIVE':
          priceLevel = '\$\$\$';
          break;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          priceLevel = '\$\$\$\$';
          break;
      }
    }

    return PlaceModel(
      id: const Uuid().v4(),
      googlePlaceId: data['id'] as String?,
      type: placeType,
      name: displayName?['text'] as String? ?? 'Unknown',
      address: data['formattedAddress'] as String?,
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      userRatingsTotal: data['userRatingCount'] as int?,
      photoReference: photoRef,
      photoReferences: photoRefs,
      phoneNumber: data['nationalPhoneNumber'] as String?,
      website: data['websiteUri'] as String?,
      openingHours: hours,
      priceLevel: priceLevel,
    );
  }
}
