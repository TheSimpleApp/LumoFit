import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';

/// Service to share map context (location, places, radius) between Map and Discover tabs.
/// When the user searches or navigates on the Map, Discover can show the same places as a list view.
class MapContextService extends ChangeNotifier {
  // Current map center
  double _centerLat = 40.7128;
  double _centerLng = -74.0060;

  // Search radius in miles
  int _searchRadiusMiles = 5;

  // Location name (from search or geocoding)
  String? _locationName;

  // Loaded places from map
  List<PlaceModel> _gyms = [];
  List<PlaceModel> _restaurants = [];
  List<PlaceModel> _trails = [];
  List<EventModel> _events = [];

  // Whether the map has loaded data at least once
  bool _hasLoadedData = false;

  // Getters
  double get centerLat => _centerLat;
  double get centerLng => _centerLng;
  int get searchRadiusMiles => _searchRadiusMiles;
  String? get locationName => _locationName;
  bool get hasLoadedData => _hasLoadedData;

  List<PlaceModel> get gyms => _gyms;
  List<PlaceModel> get restaurants => _restaurants;
  List<PlaceModel> get trails => _trails;
  List<EventModel> get events => _events;

  /// Update map center location
  void updateCenter(double lat, double lng, {String? name}) {
    _centerLat = lat;
    _centerLng = lng;
    if (name != null) {
      _locationName = name;
    }
    notifyListeners();
  }

  /// Update search radius
  void updateRadius(int miles) {
    _searchRadiusMiles = miles;
    notifyListeners();
  }

  /// Update loaded places from map
  void updatePlaces({
    List<PlaceModel>? gyms,
    List<PlaceModel>? restaurants,
    List<PlaceModel>? trails,
    List<EventModel>? events,
  }) {
    if (gyms != null) _gyms = gyms;
    if (restaurants != null) _restaurants = restaurants;
    if (trails != null) _trails = trails;
    if (events != null) _events = events;
    _hasLoadedData = true;
    notifyListeners();
  }

  /// Clear all places (when changing location)
  void clearPlaces() {
    _gyms = [];
    _restaurants = [];
    _trails = [];
    _events = [];
    notifyListeners();
  }

  /// Calculate distance from map center to a point in miles
  double distanceInMiles(double lat, double lng) {
    return _haversineDistance(_centerLat, _centerLng, lat, lng) * 0.621371; // km to miles
  }

  /// Calculate distance between two points in km using Haversine formula
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Format distance for display (e.g., "0.5 mi" or "2.3 mi")
  String formatDistance(double? lat, double? lng) {
    if (lat == null || lng == null) return '';
    final miles = distanceInMiles(lat, lng);
    if (miles < 0.1) {
      return '< 0.1 mi';
    } else if (miles < 10) {
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      return '${miles.round()} mi';
    }
  }
}
