import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/utils/haptic_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fittravel/widgets/place_quick_insights.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';

class DiscoverScreen extends StatefulWidget {
  final int initialTabIndex;
  const DiscoverScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<PlaceModel> _searchResults = [];
  // Events state
  bool _isSearchingEvents = false;
  List<EventModel> _eventResults = [];
  // Event filters
  final Set<EventCategory> _selectedCategories = {};
  String _dateFilter = 'this_week';
  bool _filterRating4Plus = false;
  bool _filterHasPhotos = false;
  // Dietary filters for Food tab
  final Set<String> _selectedDietaryFilters = {};
  // Location (fallback when no trip and GPS fails)
  double _centerLat = 40.7128;  // New York
  double _centerLng = -74.0060;
  // Active trip context
  String? _activeTripDestination;
  // Auto-loaded nearby places
  bool _isLoadingNearby = false;
  List<PlaceModel> _nearbyGyms = [];
  List<PlaceModel> _nearbyRestaurants = [];
  List<PlaceModel> _nearbyTrails = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 5,
        vsync: this,
        initialIndex: widget.initialTabIndex.clamp(0, 4));
    _initLocation();
    _loadNearbyPlaces();

    // Listen for trip changes to update location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripService>().addListener(_onTripChanged);
    });
  }

  void _onTripChanged() {
    // Re-initialize location when active trip changes
    _initLocation();
  }

  @override
  void dispose() {
    context.read<TripService>().removeListener(_onTripChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _eventResults = [];
        _isSearchingEvents = false;
      });
      return;
    }

    // Events tab
    if (_tabController.index == 2) {
      setState(() => _isSearchingEvents = true);
      final eventService = context.read<EventService>();
      final range = _currentDateRange();
      try {
        // Prefer external providers via combined edge function
        final results = await eventService.fetchExternalEvents(
          query: query,
          startDate: range.$1,
          endDate: range.$2,
          centerLat: _centerLat,
          centerLng: _centerLng,
          radiusKm: 50,
          limit: 60,
        );

        // Fallback if external API returns empty
        if (results.isEmpty) {
          final local = eventService.search(
            query: query,
            categories: _selectedCategories,
            startDate: range.$1,
            endDate: range.$2,
            centerLat: _centerLat,
            centerLng: _centerLng,
            radiusKm: 50,
          );
          if (mounted) {
            setState(() {
              _eventResults = local;
              _isSearchingEvents = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _eventResults = results;
              _isSearchingEvents = false;
            });
          }
        }
      } catch (_) {
        // Fallback to local search if remote fails
        final local = eventService.search(
          query: query,
          categories: _selectedCategories,
          startDate: range.$1,
          endDate: range.$2,
          centerLat: _centerLat,
          centerLng: _centerLng,
          radiusKm: 50,
        );
        if (mounted) {
          setState(() {
            _eventResults = local;
            _isSearchingEvents = false;
          });
        }
      }
      return;
    }

    setState(() => _isSearching = true);

    final googlePlaces = GooglePlacesService();
    final placeType = _tabController.index == 0
        ? PlaceType.gym
        : _tabController.index == 1
            ? PlaceType.restaurant
            : _tabController.index == 3
                ? PlaceType.trail
                : null;

    if (placeType != null) {
      // Search via Google Places API
      final results = await googlePlaces.searchPlacesByText(
        query: query,
        placeType: placeType,
        // Use current location if available
        latitude: _centerLat,
        longitude: _centerLng,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } else {
      // Search saved places
      final placeService = context.read<PlaceService>();
      final results = placeService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _initLocation() async {
    // Priority 1: Active trip destination
    final tripService = context.read<TripService>();
    final tripCoords = tripService.activeTripCoordinates;
    final activeTrip = tripService.activeTrip;

    if (tripCoords != null) {
      setState(() {
        _centerLat = tripCoords.$1;
        _centerLng = tripCoords.$2;
        _activeTripDestination = activeTrip?.destinationCity;
      });
      _loadNearbyPlaces();
      return;
    }

    // Priority 2: GPS location
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _centerLat = pos.latitude;
        _centerLng = pos.longitude;
        _activeTripDestination = null;
      });
      // Reload nearby places with updated location
      _loadNearbyPlaces();
    } catch (e) {
      // Non-fatal: keep defaults
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_isLoadingNearby) return;
    setState(() => _isLoadingNearby = true);

    final googlePlaces = GooglePlacesService();

    try {
      // Load nearby places for each type in parallel
      final results = await Future.wait([
        googlePlaces.searchNearbyPlaces(
          latitude: _centerLat,
          longitude: _centerLng,
          placeType: PlaceType.gym,
          radiusMeters: 5000,
        ),
        googlePlaces.searchNearbyPlaces(
          latitude: _centerLat,
          longitude: _centerLng,
          placeType: PlaceType.restaurant,
          radiusMeters: 5000,
        ),
        googlePlaces.searchNearbyPlaces(
          latitude: _centerLat,
          longitude: _centerLng,
          placeType: PlaceType.trail,
          radiusMeters: 5000,
        ),
      ]);

      if (mounted) {
        setState(() {
          _nearbyGyms = results[0];
          _nearbyRestaurants = results[1];
          _nearbyTrails = results[2];
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby places: $e');
      if (mounted) {
        setState(() => _isLoadingNearby = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    final placeService = context.read<PlaceService>();

    await Future.wait([
      _loadNearbyPlaces(),
      placeService.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: textStyles.headlineMedium)
                      .animate()
                      .fadeIn()
                      .slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                    _activeTripDestination != null
                        ? 'Exploring $_activeTripDestination'
                        : 'Find gyms, food & events nearby',
                    style: textStyles.bodyMedium?.copyWith(
                      color: _activeTripDestination != null
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: _activeTripDestination != null
                          ? FontWeight.w500
                          : null,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _performSearch(value);
                },
                decoration: InputDecoration(
                  hintText: _tabController.index == 2
                      ? 'Search events...'
                      : _tabController.index == 3
                          ? 'Search trails...'
                          : 'Search places...',
                  prefixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        )
                      : Icon(Icons.search, color: colors.onSurfaceVariant),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              Icon(Icons.clear, color: colors.onSurfaceVariant),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                              _eventResults = [];
                            });
                          },
                        )
                      : null,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) {
                  // Re-search when tab changes
                  if (_searchQuery.isNotEmpty) {
                    _performSearch(_searchQuery);
                  }
                },
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: textStyles.labelMedium,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                tabs: [
                  Tab(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, size: 16),
                      const SizedBox(width: 6),
                      const Text('Gyms', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant, size: 16),
                      const SizedBox(width: 6),
                      const Text('Food', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 16),
                      const SizedBox(width: 6),
                      const Text('Events', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terrain, size: 16),
                      const SizedBox(width: 6),
                      const Text('Trails', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark, size: 16),
                      const SizedBox(width: 6),
                      const Text('Saved', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Filter