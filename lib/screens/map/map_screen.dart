import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/place_service.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:fittravel/services/event_service.dart';
import 'package:fittravel/services/strava_service.dart';
import 'package:fittravel/services/map_context_service.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/screens/map/widgets/map_filter_bar.dart';
import 'package:fittravel/screens/map/widgets/map_place_preview.dart';
import 'package:fittravel/screens/map/widgets/location_search_bar.dart';
import 'package:fittravel/widgets/ai_map_concierge.dart';
import 'package:fittravel/models/ai_models.dart';

/// Main map discovery screen with fitness places and events
class MapScreen extends StatefulWidget {
  final String? initialFilter;

  const MapScreen({super.key, this.initialFilter});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  // Default fallback location (used only if no trip and GPS fails)
  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060); // New York
  LatLng _center = _defaultCenter;

  bool _isLoading = true;

  // Dark map style JSON
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
]
''';

  // Markers and polylines
  Set<Marker> _markers = {};
  Set<Polyline> _stravaPolylines = {};
  final Map<String, PlaceModel> _placeMarkers = {};
  final Map<String, EventModel> _eventMarkers = {};

  // Filters
  Set<MapFilterType> _activeFilters = {MapFilterType.all};

  // PlaceService listener
  void Function()? _placeServiceListener;

  // Search radius in miles
  int _searchRadiusMiles = 5;
  static const List<int> _radiusOptions = [1, 5, 10, 25];
  static const double _milesToKm = 1.60934;

  // "Search this area" button
  bool _showSearchAreaButton = false;
  LatLng? _lastSearchCenter;
  CameraPosition? _currentCameraPosition;

  // Selected item for preview
  dynamic _selectedItem; // PlaceModel or EventModel

  // Services
  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  void initState() {
    super.initState();
    _initializeMapCenter();
    _setupPlaceServiceListener();
  }

  void _setupPlaceServiceListener() {
    // Listen to PlaceService changes to update markers when places are saved/removed
    _placeServiceListener = () {
      if (mounted) {
        _updateMarkersFromItems();
      }
    };

    // Add listener after first frame to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlaceService>().addListener(_placeServiceListener!);
      }
    });
  }

  Future<void> _initializeMapCenter() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // First, check if we have a persisted location in MapContextService
      final mapContext = context.read<MapContextService>();
      final hasPersistedLocation = mapContext.locationName != null;

      if (hasPersistedLocation) {
        // Use the persisted location from previous session
        _center = LatLng(mapContext.centerLat, mapContext.centerLng);
        _searchRadiusMiles = mapContext.searchRadiusMiles;
        debugPrint(
            'MapScreen: Using persisted location: ${mapContext.locationName}');
      } else {
        // No persisted location, try GPS
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            ).timeout(const Duration(seconds: 10));

            if (!mounted) return;
            _center = LatLng(position.latitude, position.longitude);
          }
        } catch (e) {
          debugPrint('MapScreen: Could not get GPS location: $e');
          // Keep default fallback center
        }
      }
    } catch (e, st) {
      debugPrint('MapScreen: Error initializing map: $e');
      debugPrint(st.toString());
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _loadPlacesForCurrentLocation();
  }

  Future<void> _loadPlacesForCurrentLocation() async {
    // Update MapContextService with current center
    final mapContext = context.read<MapContextService>();
    mapContext.updateCenter(_center.latitude, _center.longitude);
    mapContext.updateRadius(_searchRadiusMiles);

    // If "Saved" filter is active, load from saved places only
    if (_activeFilters.contains(MapFilterType.saved)) {
      _loadSavedPlaces();
      return;
    }

    if (_activeFilters.contains(MapFilterType.all) || _activeFilters.isEmpty) {
      // Load all types
      await Future.wait([
        _loadPlaces(PlaceType.gym),
        _loadPlaces(PlaceType.restaurant),
        _loadPlaces(PlaceType.trail),
        _loadPlaces(PlaceType.park),
        _loadEvents(),
      ]);
      // Clear Strava polylines when showing all (unless specifically requested)
      setState(() => _stravaPolylines = {});
    } else {
      final futures = <Future>[];
      if (_activeFilters.contains(MapFilterType.gyms)) {
        futures.add(_loadPlaces(PlaceType.gym));
      }
      if (_activeFilters.contains(MapFilterType.food)) {
        futures.add(_loadPlaces(PlaceType.restaurant));
      }
      if (_activeFilters.contains(MapFilterType.trails)) {
        futures.add(_loadPlaces(PlaceType.trail));
        futures.add(_loadPlaces(PlaceType.park));
      }
      if (_activeFilters.contains(MapFilterType.events)) {
        futures.add(_loadEvents());
      }
      if (_activeFilters.contains(MapFilterType.strava)) {
        futures.add(_loadStravaSegments());
      } else {
        // Clear Strava polylines if not in filter
        setState(() => _stravaPolylines = {});
      }
      await Future.wait(futures);
    }

    _updateMarkersFromItems();

    // Update MapContextService with loaded places
    _syncPlacesToMapContext();
  }

  void _syncPlacesToMapContext() {
    final mapContext = context.read<MapContextService>();

    // Separate places by type
    final gyms = <PlaceModel>[];
    final restaurants = <PlaceModel>[];
    final trails = <PlaceModel>[];

    for (final place in _placeMarkers.values) {
      switch (place.type) {
        case PlaceType.gym:
          gyms.add(place);
          break;
        case PlaceType.restaurant:
          restaurants.add(place);
          break;
        case PlaceType.trail:
        case PlaceType.park:
          trails.add(place);
          break;
        default:
          break;
      }
    }

    mapContext.updatePlaces(
      gyms: gyms,
      restaurants: restaurants,
      trails: trails,
      events: _eventMarkers.values.toList(),
    );
  }

  void _loadSavedPlaces() {
    final placeService = context.read<PlaceService>();
    final savedPlaces = placeService.savedPlaces;
    final markers = <String, PlaceModel>{};

    for (final place in savedPlaces) {
      if (place.googlePlaceId != null) {
        markers[place.googlePlaceId!] = place;
      } else {
        markers[place.id] = place;
      }
    }

    setState(() {
      _placeMarkers.clear();
      _placeMarkers.addAll(markers);
      _eventMarkers.clear();
    });

    _updateMarkersFromItems();
  }

  Future<void> _loadPlaces(PlaceType type) async {
    try {
      final places = await _placesService.searchNearbyPlaces(
        latitude: _center.latitude,
        longitude: _center.longitude,
        placeType: type,
        radiusMeters: (_searchRadiusMiles * _milesToKm * 1000)
            .round(), // Convert miles to meters
      );

      for (final place in places) {
        if (place.latitude != null && place.longitude != null) {
          _placeMarkers[place.id] = place;
        }
      }
    } catch (e, st) {
      debugPrint('MapScreen: Error loading $type places: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> _loadEvents() async {
    try {
      final eventService = context.read<EventService>();
      final events = await eventService.fetchExternalEvents(
        centerLat: _center.latitude,
        centerLng: _center.longitude,
        radiusKm: _searchRadiusMiles * _milesToKm, // Convert miles to km
        limit: 30,
      );

      for (final event in events) {
        if (event.latitude != null && event.longitude != null) {
          _eventMarkers[event.id] = event;
        }
      }
    } catch (e, st) {
      debugPrint('MapScreen: Error loading events: $e');
      debugPrint(st.toString());
    }
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() => _markers = markers);
  }

  void _updateMarkersFromItems() {
    final markers = <Marker>{};
    final placeService = context.read<PlaceService>();
    final savedPlaceIds =
        placeService.savedPlaces.map((p) => p.googlePlaceId ?? p.id).toSet();

    // Add place markers
    for (final entry in _placeMarkers.entries) {
      final place = entry.value;
      if (!_shouldShowPlace(place)) continue;

      final placeId = place.googlePlaceId ?? place.id;
      final isSaved = savedPlaceIds.contains(placeId);

      markers.add(Marker(
        markerId: MarkerId('place_${entry.key}'),
        position: LatLng(place.latitude ?? 0.0, place.longitude ?? 0.0),
        icon: _getMarkerIcon(place.type, isSaved: isSaved),
        alpha: isSaved ? 1.0 : 0.85, // Saved places are more prominent
        onTap: () => _onMarkerTapped(place),
      ));
    }

    // Add event markers (Royal Purple from premium theme)
    if (_activeFilters.contains(MapFilterType.all) ||
        _activeFilters.contains(MapFilterType.events)) {
      for (final entry in _eventMarkers.entries) {
        final event = entry.value;
        if (event.latitude != null && event.longitude != null) {
          markers.add(Marker(
            markerId: MarkerId('event_${entry.key}'),
            position: LatLng(event.latitude!, event.longitude!),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(AppColors.markerHueEvent),
            onTap: () => _onMarkerTapped(event),
          ));
        }
      }
    }

    _updateMarkers(markers);
  }

  bool _shouldShowPlace(PlaceModel place) {
    if (_activeFilters.contains(MapFilterType.all)) return true;
    if (_activeFilters.contains(MapFilterType.saved)) return true;

    switch (place.type) {
      case PlaceType.gym:
        return _activeFilters.contains(MapFilterType.gyms);
      case PlaceType.restaurant:
        return _activeFilters.contains(MapFilterType.food);
      case PlaceType.trail:
      case PlaceType.park:
        return _activeFilters.contains(MapFilterType.trails);
      default:
        return false;
    }
  }

  BitmapDescriptor _getMarkerIcon(PlaceType type, {bool isSaved = false}) {
    // Saved places get a gold marker to stand out (matches premium theme)
    if (isSaved) {
      return BitmapDescriptor.defaultMarkerWithHue(AppColors.markerHueSaved);
    }

    // Category-specific colors from premium theme palette
    switch (type) {
      case PlaceType.gym:
        return BitmapDescriptor.defaultMarkerWithHue(AppColors.markerHueGym);
      case PlaceType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(AppColors.markerHueFood);
      case PlaceType.trail:
      case PlaceType.park:
        return BitmapDescriptor.defaultMarkerWithHue(AppColors.markerHueTrail);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTapped(dynamic item) {
    setState(() => _selectedItem = item);
  }

  void _onFilterChanged(Set<MapFilterType> filters) {
    final previousFilters = _activeFilters;
    setState(() {
      _activeFilters = filters;
      _selectedItem = null;
    });

    // If Saved filter or Strava filter was toggled, reload data
    final savedWasActive = previousFilters.contains(MapFilterType.saved);
    final savedIsActive = filters.contains(MapFilterType.saved);
    final stravaWasActive = previousFilters.contains(MapFilterType.strava);
    final stravaIsActive = filters.contains(MapFilterType.strava);

    if (savedWasActive != savedIsActive || stravaWasActive != stravaIsActive) {
      _loadPlacesForCurrentLocation();
    } else {
      _updateMarkersFromItems();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _lastSearchCenter = _center;
  }

  void _onCameraMove(CameraPosition position) {
    _currentCameraPosition = position;

    // Show "Search this area" button if user has panned significantly
    if (_lastSearchCenter != null) {
      final distance = _haversineDistance(
        _lastSearchCenter!.latitude,
        _lastSearchCenter!.longitude,
        position.target.latitude,
        position.target.longitude,
      );
      if (distance > 2.0 && !_showSearchAreaButton) {
        setState(() => _showSearchAreaButton = true);
      }
    }
  }

  void _searchThisArea() {
    if (_currentCameraPosition != null) {
      _center = _currentCameraPosition!.target;
      _lastSearchCenter = _center;
      _placeMarkers.clear();
      _eventMarkers.clear();
      _loadPlacesForCurrentLocation();
    }
    setState(() => _showSearchAreaButton = false);
  }

  void _onLocationSearchSelected(double lat, double lng, String locationName) {
    _center = LatLng(lat, lng);
    _lastSearchCenter = _center;

    // Update MapContextService with location name
    final mapContext = context.read<MapContextService>();
    mapContext.updateCenter(lat, lng, name: locationName);

    // Animate to the new location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_center, 13),
    );

    // Clear existing markers and load places for new location
    _placeMarkers.clear();
    _eventMarkers.clear();
    _loadPlacesForCurrentLocation();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing places near $locationName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _discoverEventsForCurrentLocation() async {
    if (!mounted) return;

    final mapContext = context.read<MapContextService>();
    final eventService = context.read<EventService>();
    final locationName = mapContext.locationName ?? 'this area';

    try {
      await eventService.discoverEventsForLocation(
        locationName: locationName,
        latitude: _center.latitude,
        longitude: _center.longitude,
      );

      if (!mounted) return;

      // Check for errors
      if (eventService.lastDiscoveryError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eventService.lastDiscoveryError!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Success - reload events and update markers
      _eventMarkers.clear();
      await _loadEvents();
      _updateMarkersFromItems();

      // Sync to map context
      _syncPlacesToMapContext();

      if (!mounted) return;

      // Count new events
      final eventCount = _eventMarkers.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found $eventCount events in $locationName!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Switch to Events filter to show the new events
              setState(() {
                _activeFilters = {MapFilterType.events};
                _updateMarkersFromItems();
              });
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to discover events: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Calculate distance between two points in km using Haversine formula
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
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

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  Future<void> _loadStravaSegments() async {
    final stravaService = context.read<StravaService>();
    if (!stravaService.isAuthenticated) return;

    try {
      final bounds = await _mapController?.getVisibleRegion();
      if (bounds == null || !mounted) return;

      final segments = await stravaService.exploreSegments(
        swLat: bounds.southwest.latitude,
        swLng: bounds.southwest.longitude,
        neLat: bounds.northeast.latitude,
        neLng: bounds.northeast.longitude,
      );

      if (!mounted) return;
      setState(() {
        _stravaPolylines = segments
            .map((seg) => Polyline(
                  polylineId: PolylineId('strava_${seg.id}'),
                  points: seg.points.map((p) => LatLng(p[0], p[1])).toList(),
                  color: Colors.orange,
                  width: 4,
                ))
            .toSet();
      });
    } catch (e) {
      debugPrint('MapScreen: Error loading Strava segments: $e');
    }
  }

  void _recenterToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      _center = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_center, 14),
      );
      _loadPlacesForCurrentLocation();
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location')),
        );
      }
      debugPrint('MapScreen: recenter error: $e');
      debugPrint(st.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final activeTrip = tripService.activeTrip;
    final colors = context.colorScheme;
    final mapContext = context.watch<MapContextService>();

    return Scaffold(
      body: Stack(
        children: [
          // Main map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 13,
              ),
              markers: _markers,
              polylines: _stravaPolylines,
              style: _darkMapStyle,
              // myLocation is not supported on web by google_maps_flutter_web
              myLocationEnabled: !kIsWeb,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

          // Search bar, filter bar, and radius selector
          // Active trip banner removed - use search bar for location exploration
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location search bar
                LocationSearchBar(
                  onLocationSelected: _onLocationSearchSelected,
                  initialLocation: mapContext.locationName,
                ),
                const SizedBox(height: 8),
                Consumer<StravaService>(
                  builder: (context, stravaService, _) => MapFilterBar(
                    activeFilters: _activeFilters,
                    onFilterChanged: _onFilterChanged,
                    isStravaAuthenticated: stravaService.isAuthenticated,
                  ),
                ),
                const SizedBox(height: 8),
                // Radius selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar,
                            size: 16,
                            color: colors.onSurface.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _searchRadiusMiles,
                            isDense: true,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                            dropdownColor: colors.surface,
                            items: _radiusOptions
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text('${r}mi'),
                                    ))
                                .toList(),
                            onChanged: (r) {
                              if (r != null && r != _searchRadiusMiles) {
                                setState(() => _searchRadiusMiles = r);
                                context
                                    .read<MapContextService>()
                                    .updateRadius(r);
                                _loadPlacesForCurrentLocation();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // "Search this area" button
          if (_showSearchAreaButton)
            Positioned(
              top: activeTrip != null
                  ? MediaQuery.of(context).padding.top + 220
                  : MediaQuery.of(context).padding.top + 160,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _searchThisArea,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              size: 18, color: colors.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Search this area',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Event discovery button
          Positioned(
            left: 0,
            right: 0,
            bottom: _selectedItem != null ? 220 : 100,
            child: Center(
              child: Consumer<EventService>(
                builder: (context, eventService, _) {
                  if (eventService.isDiscoveringEvents) {
                    // Show loading indicator
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Discovering events...',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _discoverEventsForCurrentLocation,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.categoryEvent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                size: 20, color: colors.onPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'Find Events Here',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: _selectedItem != null ? 220 : 100,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _recenterToCurrentLocation,
              backgroundColor: colors.surface,
              child: Icon(Icons.my_location, color: colors.primary),
            ),
          ),

          // Place preview bottom sheet
          if (_selectedItem != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MapPlacePreview(
                item: _selectedItem,
                onClose: () => setState(() => _selectedItem = null),
              ),
            ),

          // AI Map Concierge (floating chat)
          AiMapConcierge(
            destination: activeTrip?.destinationCity,
            userLat: _center.latitude,
            userLng: _center.longitude,
            onPlacesSuggested: _onAiPlacesSuggested,
            onPlaceTapped: _onAiPlaceTapped,
            isBottomSheetOpen: _selectedItem != null,
          ),
        ],
      ),
    );
  }

  void _onAiPlacesSuggested(List<SuggestedPlace> places) {
    // Add suggested places as markers on the map
    final newMarkers = <Marker>{};

    for (final place in places) {
      if (place.hasCoordinates) {
        newMarkers.add(Marker(
          markerId: MarkerId('ai_${place.name}'),
          position: LatLng(place.lat!, place.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              AppColors.markerHueEvent), // AI suggestions use event color
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.neighborhood ?? place.type,
          ),
          onTap: () => _onAiPlaceTapped(place),
        ));
      }
    }

    if (newMarkers.isNotEmpty) {
      setState(() {
        _markers = {..._markers, ...newMarkers};
      });

      // Zoom to show all suggested places if multiple
      if (places.length > 1) {
        final bounds = _calculateBounds(places
            .where((p) => p.hasCoordinates)
            .map((p) => LatLng(p.lat!, p.lng!))
            .toList());
        if (bounds != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      } else if (places.length == 1 && places.first.hasCoordinates) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(places.first.lat!, places.first.lng!),
            15,
          ),
        );
      }
    }
  }

  void _onAiPlaceTapped(SuggestedPlace place) async {
    // If place has coordinates, show it on the map
    if (place.hasCoordinates) {
      // Zoom to the place
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.lat!, place.lng!),
          16,
        ),
      );

      // Try to fetch full place details from Google Places
      if (place.googlePlaceId != null) {
        final placesService = GooglePlacesService();
        final placeType = _parsePlaceType(place.type);
        final fullPlace = await placesService.getPlaceDetails(
          place.googlePlaceId!,
          placeType,
        );

        if (!mounted) return;
        if (fullPlace != null) {
          setState(() {
            _selectedItem = fullPlace;
          });
          return;
        }
      }

      // Fallback: Create a temporary PlaceModel from SuggestedPlace
      final tempPlace = PlaceModel(
        id: place.googlePlaceId ?? 'temp_${place.name.hashCode}',
        googlePlaceId: place.googlePlaceId,
        type: _parsePlaceType(place.type),
        name: place.name,
        address: place.neighborhood,
        latitude: place.lat,
        longitude: place.lng,
        rating: 0,
        userRatingsTotal: 0,
        isVisited: false,
      );

      if (!mounted) return;
      setState(() {
        _selectedItem = tempPlace;
      });
    }
  }

  PlaceType _parsePlaceType(String type) {
    switch (type.toLowerCase()) {
      case 'gym':
        return PlaceType.gym;
      case 'restaurant':
      case 'food':
        return PlaceType.restaurant;
      case 'park':
        return PlaceType.park;
      case 'trail':
        return PlaceType.trail;
      default:
        return PlaceType.gym;
    }
  }

  LatLngBounds? _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    // Remove PlaceService listener
    if (_placeServiceListener != null) {
      try {
        context.read<PlaceService>().removeListener(_placeServiceListener!);
      } catch (e) {
        debugPrint('MapScreen: Error removing PlaceService listener: $e');
      }
    }
    _mapController?.dispose();
    super.dispose();
  }
}
