import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:fittravel/services/event_service.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/screens/map/widgets/map_filter_bar.dart';
import 'package:fittravel/screens/map/widgets/map_place_preview.dart';
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

  // Default to Cairo
  static const LatLng _defaultCenter = LatLng(30.0444, 31.2357);
  LatLng _center = _defaultCenter;

  bool _isLoading = true;

  // Markers
  Set<Marker> _markers = {};
  final Map<String, PlaceModel> _placeMarkers = {};
  final Map<String, EventModel> _eventMarkers = {};

  // Filters
  Set<MapFilterType> _activeFilters = {MapFilterType.all};

  // Selected item for preview
  dynamic _selectedItem; // PlaceModel or EventModel

  // Services
  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  void initState() {
    super.initState();
    _initializeMapCenter();
  }

  Future<void> _initializeMapCenter() async {
    setState(() => _isLoading = true);

    try {
      // Priority 1: Active trip destination
      final tripService = context.read<TripService>();
      final tripCoords = tripService.activeTripCoordinates;

      if (tripCoords != null) {
        _center = LatLng(tripCoords.$1, tripCoords.$2);
        setState(() => _isLoading = false);
        _loadPlacesForCurrentLocation();
        return;
      }

      // Priority 2: Current GPS location
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 10));

          _center = LatLng(position.latitude, position.longitude);
        }
      } catch (e) {
        debugPrint('MapScreen: Could not get GPS location: $e');
        // Keep default Cairo center
      }
    } catch (e) {
      debugPrint('MapScreen: Error initializing map: $e');
    }

    setState(() => _isLoading = false);
    _loadPlacesForCurrentLocation();
  }

  Future<void> _loadPlacesForCurrentLocation() async {
    if (_activeFilters.contains(MapFilterType.all) ||
        _activeFilters.isEmpty) {
      // Load all types
      await Future.wait([
        _loadPlaces(PlaceType.gym),
        _loadPlaces(PlaceType.restaurant),
        _loadPlaces(PlaceType.trail),
        _loadPlaces(PlaceType.park),
        _loadEvents(),
      ]);
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
      await Future.wait(futures);
    }

    _updateMarkers();
  }

  Future<void> _loadPlaces(PlaceType type) async {
    try {
      final places = await _placesService.searchNearbyPlaces(
        latitude: _center.latitude,
        longitude: _center.longitude,
        placeType: type,
        radiusMeters: 10000, // 10km radius
      );

      for (final place in places) {
        if (place.latitude != null && place.longitude != null) {
          _placeMarkers[place.id] = place;
        }
      }
    } catch (e) {
      debugPrint('MapScreen: Error loading $type places: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final eventService = context.read<EventService>();
      final events = await eventService.fetchExternalEvents(
        centerLat: _center.latitude,
        centerLng: _center.longitude,
        radiusKm: 50,
        limit: 30,
      );

      for (final event in events) {
        if (event.latitude != null && event.longitude != null) {
          _eventMarkers[event.id] = event;
        }
      }
    } catch (e) {
      debugPrint('MapScreen: Error loading events: $e');
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add place markers
    for (final entry in _placeMarkers.entries) {
      final place = entry.value;
      if (!_shouldShowPlace(place)) continue;

      markers.add(Marker(
        markerId: MarkerId('place_${entry.key}'),
        position: LatLng(place.latitude!, place.longitude!),
        icon: _getMarkerIcon(place.type),
        infoWindow: InfoWindow(title: place.name),
        onTap: () => _onMarkerTapped(place),
      ));
    }

    // Add event markers
    if (_activeFilters.contains(MapFilterType.all) ||
        _activeFilters.contains(MapFilterType.events)) {
      for (final entry in _eventMarkers.entries) {
        final event = entry.value;

        markers.add(Marker(
          markerId: MarkerId('event_${entry.key}'),
          position: LatLng(event.latitude!, event.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: event.title),
          onTap: () => _onMarkerTapped(event),
        ));
      }
    }

    setState(() => _markers = markers);
  }

  bool _shouldShowPlace(PlaceModel place) {
    if (_activeFilters.contains(MapFilterType.all)) return true;

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

  BitmapDescriptor _getMarkerIcon(PlaceType type) {
    switch (type) {
      case PlaceType.gym:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case PlaceType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case PlaceType.trail:
      case PlaceType.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTapped(dynamic item) {
    setState(() => _selectedItem = item);
  }

  void _onFilterChanged(Set<MapFilterType> filters) {
    setState(() {
      _activeFilters = filters;
      _selectedItem = null;
    });
    _updateMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    // Apply dark map style to match app theme
    const darkStyle = '''
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
    await _mapController?.setMapStyle(darkStyle);
  }

  void _recenterToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _center = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_center, 14),
      );
      _loadPlacesForCurrentLocation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final activeTrip = tripService.activeTrip;
    final colors = context.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Main map
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 13,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

          // Trip context banner
          if (activeTrip != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.flight_takeoff, size: 18, color: colors.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exploring ${activeTrip.destinationCity}',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _recenterToCurrentLocation,
                      child: const Text('My location'),
                    ),
                  ],
                ),
              ),
            ),

          // Filter bar
          Positioned(
            top: activeTrip != null
                ? MediaQuery.of(context).padding.top + 68
                : MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: MapFilterBar(
              activeFilters: _activeFilters,
              onFilterChanged: _onFilterChanged,
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.neighborhood ?? place.type,
          ),
        ));
      }
    }

    if (newMarkers.isNotEmpty) {
      setState(() {
        _markers = {..._markers, ...newMarkers};
      });

      // Optionally zoom to show all suggested places
      if (places.length == 1 && places.first.hasCoordinates) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(places.first.lat!, places.first.lng!),
            15,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
