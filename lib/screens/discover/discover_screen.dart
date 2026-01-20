import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/utils/haptic_utils.dart';
import 'package:fittravel/widgets/polish_widgets.dart';
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
  // Place filters (for Gyms, Food, Trails)
  bool _filterOpenNow = false;
  bool _filterRating45Plus = false;
  bool _filterPlaceHasPhotos = false;
  bool _filterSavedOnly = false;
  // Location (fallback when no trip and GPS fails)
  double _centerLat = 40.7128; // New York
  double _centerLng = -74.0060;
  // Active trip context
  String? _activeTripDestination;
  // Auto-loaded nearby places
  bool _isLoadingNearby = false;
  List<PlaceModel> _nearbyGyms = [];
  List<PlaceModel> _nearbyRestaurants = [];
  List<PlaceModel> _nearbyTrails = [];
  // Store reference for safe disposal
  TripService? _tripService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex: widget.initialTabIndex.clamp(0, 3));
    _initLocation();
    _loadNearbyPlaces();

    // Listen for trip changes to update location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tripService = context.read<TripService>();
      _tripService?.addListener(_onTripChanged);
    });
  }

  void _onTripChanged() {
    // Re-initialize location when active trip changes
    _initLocation();
  }

  @override
  void dispose() {
    _tripService?.removeListener(_onTripChanged);
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Filters (contextual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Place filters for Gyms, Trails tabs
                    if (_tabController.index == 0 ||
                        _tabController.index == 3) ...[
                      _buildSavedOnlyFilter(),
                      const SizedBox(width: 8),
                      _buildOpenNowFilter(),
                      const SizedBox(width: 8),
                      _buildRating45PlusFilter(),
                      const SizedBox(width: 8),
                      _buildPlaceHasPhotosFilter(),
                    ]
                    // Food tab has place filters + dietary
                    else if (_tabController.index == 1) ...[
                      _buildSavedOnlyFilter(),
                      const SizedBox(width: 8),
                      _buildOpenNowFilter(),
                      const SizedBox(width: 8),
                      _buildRating45PlusFilter(),
                      const SizedBox(width: 8),
                      _buildPlaceHasPhotosFilter(),
                      const SizedBox(width: 8),
                      _buildDietaryFilter(),
                    ]
                    // Events tab
                    else if (_tabController.index == 2) ...[
                      _buildEventCategoryFilter(),
                      const SizedBox(width: 8),
                      _buildEventDateFilter(),
                      const SizedBox(width: 8),
                      _buildEventRatingFilter(),
                      const SizedBox(width: 8),
                      _buildEventPhotosFilter(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGymsTab(),
                  _buildFoodTab(),
                  _buildEventsTab(),
                  _buildTrailsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymsTab() {
    if (_searchQuery.isNotEmpty) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      final filteredResults = _filterPlaces(_searchResults);
      if (filteredResults.isEmpty) {
        return EmptyStateWidget(
          title: 'No gyms found',
          description:
              'Try searching with different keywords or adjusting filters',
          ctaLabel: 'Browse nearby',
          onCtaPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _searchResults = [];
            });
          },
        );
      }
      return _buildPlacesList(filteredResults);
    }

    if (_isLoadingNearby) {
      return _buildSkeletonList();
    }

    final filteredGyms = _filterPlaces(_nearbyGyms);
    if (filteredGyms.isEmpty) {
      return EmptyStateWidget(
        title: _filterSavedOnly ? 'No saved gyms' : 'No gyms nearby',
        description: _filterSavedOnly
            ? 'Save gyms by tapping the bookmark icon on place details'
            : _hasActiveFilters()
                ? 'Try adjusting your filters or enable location'
                : 'Start a trip or enable location to discover gyms',
        ctaLabel: _hasActiveFilters() ? 'Clear filters' : 'Enable location',
        onCtaPressed: () {
          if (_hasActiveFilters()) {
            setState(() {
              _filterSavedOnly = false;
              _filterOpenNow = false;
              _filterRating45Plus = false;
              _filterPlaceHasPhotos = false;
            });
          } else {
            _initLocation();
          }
        },
      );
    }

    return _buildPlacesList(filteredGyms);
  }

  Widget _buildFoodTab() {
    if (_searchQuery.isNotEmpty) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      final filteredResults = _filterPlaces(_searchResults);
      if (filteredResults.isEmpty) {
        return EmptyStateWidget(
          title: 'No restaurants found',
          description:
              'Try searching with different keywords or adjusting filters',
          ctaLabel: 'Browse nearby',
          onCtaPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _searchResults = [];
            });
          },
        );
      }
      return _buildPlacesList(filteredResults);
    }

    if (_isLoadingNearby) {
      return _buildSkeletonList();
    }

    final filteredRestaurants = _filterPlaces(_nearbyRestaurants);
    if (filteredRestaurants.isEmpty) {
      return EmptyStateWidget(
        title:
            _filterSavedOnly ? 'No saved restaurants' : 'No restaurants nearby',
        description: _filterSavedOnly
            ? 'Save restaurants by tapping the bookmark icon on place details'
            : _hasActiveFilters()
                ? 'Try adjusting your filters or enable location'
                : 'Start a trip or enable location to discover restaurants',
        ctaLabel: _hasActiveFilters() ? 'Clear filters' : 'Enable location',
        onCtaPressed: () {
          if (_hasActiveFilters()) {
            setState(() {
              _filterSavedOnly = false;
              _filterOpenNow = false;
              _filterRating45Plus = false;
              _filterPlaceHasPhotos = false;
              _selectedDietaryFilters.clear();
            });
          } else {
            _initLocation();
          }
        },
      );
    }

    return _buildPlacesList(filteredRestaurants);
  }

  Widget _buildEventsTab() {
    if (_searchQuery.isNotEmpty) {
      if (_isSearchingEvents) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_eventResults.isEmpty) {
        return EmptyStateWidget(
          title: 'No events found',
          description: 'Try different dates or locations',
          ctaLabel: 'Reset filters',
          onCtaPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _eventResults = [];
              _selectedCategories.clear();
              _dateFilter = 'this_week';
              _filterRating4Plus = false;
              _filterHasPhotos = false;
            });
          },
        );
      }
      return _buildEventsList(_eventResults);
    }

    return EmptyStateWidget(
      title: 'Search for events',
      description: 'Find fitness classes, yoga, sports and more',
      ctaLabel: 'Start searching',
      onCtaPressed: () {
        // Focus is not available on TextEditingController in Flutter 3.38+
        // User can tap search field directly
      },
    );
  }

  Widget _buildTrailsTab() {
    if (_searchQuery.isNotEmpty) {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      final filteredResults = _filterPlaces(_searchResults);
      if (filteredResults.isEmpty) {
        return EmptyStateWidget(
          title: 'No trails found',
          description:
              'Try searching with different keywords or adjusting filters',
          ctaLabel: 'Browse nearby',
          onCtaPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _searchResults = [];
            });
          },
        );
      }
      return _buildPlacesList(filteredResults);
    }

    if (_isLoadingNearby) {
      return _buildSkeletonList();
    }

    final filteredTrails = _filterPlaces(_nearbyTrails);
    if (filteredTrails.isEmpty) {
      return EmptyStateWidget(
        title: _filterSavedOnly ? 'No saved trails' : 'No trails nearby',
        description: _filterSavedOnly
            ? 'Save trails by tapping the bookmark icon on place details'
            : _hasActiveFilters()
                ? 'Try adjusting your filters or enable location'
                : 'Start a trip or enable location to discover trails',
        ctaLabel: _hasActiveFilters() ? 'Clear filters' : 'Enable location',
        onCtaPressed: () {
          if (_hasActiveFilters()) {
            setState(() {
              _filterSavedOnly = false;
              _filterOpenNow = false;
              _filterRating45Plus = false;
              _filterPlaceHasPhotos = false;
            });
          } else {
            _initLocation();
          }
        },
      );
    }

    return _buildPlacesList(filteredTrails);
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const PlaceCardSkeleton(),
        ).animate().fadeIn(
            delay: Duration(milliseconds: 50 * index), duration: 300.ms);
      },
    );
  }

  Widget _buildPlacesList(List<PlaceModel> places) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return _buildPlaceCard(place, index);
      },
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildPlaceCard(PlaceModel place, int index) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final placeService = context.read<PlaceService>();
    final isSaved = placeService.isPlaceSaved(place.googlePlaceId);

    // Get place type icon and color
    IconData typeIcon;
    Color typeColor;
    switch (place.type) {
      case PlaceType.gym:
        typeIcon = Icons.fitness_center;
        typeColor = AppColors.primary;
        break;
      case PlaceType.restaurant:
        typeIcon = Icons.restaurant;
        typeColor = AppColors.success;
        break;
      case PlaceType.trail:
        typeIcon = Icons.terrain;
        typeColor = AppColors.info;
        break;
      default:
        typeIcon = Icons.place;
        typeColor = AppColors.textSecondary;
    }

    return PressableScale(
      onPressed: () {
        HapticUtils.light();
        context.push('/place-detail', extra: place);
      },
      child: Hero(
        tag: 'place_${place.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo carousel (if photos available) with bookmark indicator
                Stack(
                  children: [
                    if (place.photoReferences.isNotEmpty)
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: place.photoReferences.length.clamp(0, 5),
                          itemBuilder: (context, photoIndex) {
                            return Container(
                              width: 200,
                              margin: EdgeInsets.only(
                                right: photoIndex <
                                        place.photoReferences.length - 1
                                    ? 8
                                    : 0,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: CachedNetworkImage(
                                  imageUrl: GooglePlacesService().getPhotoUrl(
                                    place.photoReferences[photoIndex],
                                    maxWidth: 400,
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: AppColors.surface,
                                    highlightColor: AppColors.surfaceLight,
                                    child: Container(color: AppColors.surface),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: typeColor.withValues(alpha: 0.1),
                                    child: Icon(typeIcon,
                                        color: typeColor, size: 48),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Fallback icon when no photos
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Icon(typeIcon, color: typeColor, size: 64),
                        ),
                      ),
                    // Bookmark indicator for saved places
                    if (isSaved)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark,
                              size: 14, color: AppColors.xp),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with distance badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  place.name,
                                  style: textStyles.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Distance badge (if available)
                              if (place.latitude != null &&
                                  place.longitude != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: typeColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${(place.latitude! - 30.2672).abs().toStringAsFixed(1)}mi', // Placeholder distance
                                        style: textStyles.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Address
                          Text(
                            place.address ?? 'No address',
                            style: textStyles.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Rating stars + Open/Closed status
                          Row(
                            children: [
                              // Rating stars visualization
                              if (place.rating != null) ...[
                                ...List.generate(5, (starIndex) {
                                  final rating = place.rating!;
                                  if (starIndex < rating.floor()) {
                                    // Full star
                                    return Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.warning,
                                    );
                                  } else if (starIndex < rating.ceil() &&
                                      rating % 1 != 0) {
                                    // Half star
                                    return Icon(
                                      Icons.star_half,
                                      size: 14,
                                      color: AppColors.warning,
                                    );
                                  } else {
                                    // Empty star
                                    return Icon(
                                      Icons.star_border,
                                      size: 14,
                                      color: colors.onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                    );
                                  }
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: textStyles.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (place.userRatingsTotal != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${place.userRatingsTotal})',
                                    style: textStyles.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                              ],
                              // Open/Closed status indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Open',
                                      style: textStyles.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
            duration: 300.ms)
        .slideX(
            begin: 0.05,
            delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
            duration: 300.ms);
  }

  Widget _buildEventCard(EventModel event) {
    final textStyles = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/event-detail', extra: event),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Add image on left side
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.surface,
                    highlightColor: AppColors.surfaceLight,
                    child: Container(
                      width: 120,
                      height: 120,
                      color: AppColors.surface,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.purple.withValues(alpha: 0.1),
                    child:
                        const Icon(Icons.event, color: Colors.purple, size: 40),
                  ),
                ),
              ),
            // Existing event details in Expanded widget
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: textStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(event.category.toString(),
                        style: textStyles.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(event.start.toString().split(' ')[0],
                            style: textStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCategoryFilter() {
    return FilterChip(
      label: const Text('Category'),
      onSelected: (_) => _showCategoryPicker(),
      selected: _selectedCategories.isNotEmpty,
    );
  }

  Widget _buildEventDateFilter() {
    return FilterChip(
      label: const Text('Date'),
      onSelected: (_) => _showDateFilterPicker(),
      selected: _dateFilter != 'this_week',
    );
  }

  Widget _buildEventRatingFilter() {
    return FilterChip(
      label: const Text('4+ Rating'),
      onSelected: (selected) => setState(() => _filterRating4Plus = selected),
      selected: _filterRating4Plus,
    );
  }

  Widget _buildEventPhotosFilter() {
    return FilterChip(
      label: const Text('Has photos'),
      onSelected: (selected) => setState(() => _filterHasPhotos = selected),
      selected: _filterHasPhotos,
    );
  }

  Widget _buildDietaryFilter() {
    return FilterChip(
      label: const Text('Dietary'),
      onSelected: (_) => _showDietaryFilterPicker(),
      selected: _selectedDietaryFilters.isNotEmpty,
    );
  }

  // Place filter chips
  Widget _buildOpenNowFilter() {
    return FilterChip(
      label: const Text('Open now'),
      onSelected: (selected) {
        setState(() => _filterOpenNow = selected);
        _applyPlaceFilters();
      },
      selected: _filterOpenNow,
    );
  }

  Widget _buildRating45PlusFilter() {
    return FilterChip(
      label: const Text('4.5+ stars'),
      onSelected: (selected) {
        setState(() => _filterRating45Plus = selected);
        _applyPlaceFilters();
      },
      selected: _filterRating45Plus,
    );
  }

  Widget _buildPlaceHasPhotosFilter() {
    return FilterChip(
      label: const Text('Has photos'),
      onSelected: (selected) {
        setState(() => _filterPlaceHasPhotos = selected);
        _applyPlaceFilters();
      },
      selected: _filterPlaceHasPhotos,
    );
  }

  Widget _buildSavedOnlyFilter() {
    return FilterChip(
      avatar: Icon(
        _filterSavedOnly ? Icons.bookmark : Icons.bookmark_outline,
        size: 16,
      ),
      label: const Text('Saved'),
      onSelected: (selected) {
        setState(() => _filterSavedOnly = selected);
        _applyPlaceFilters();
      },
      selected: _filterSavedOnly,
    );
  }

  void _applyPlaceFilters() {
    // Trigger rebuild with filtered results
    setState(() {});
  }

  // Filter places based on active filters
  List<PlaceModel> _filterPlaces(List<PlaceModel> places) {
    var filtered = places;

    // Filter by saved only
    if (_filterSavedOnly) {
      final placeService = context.read<PlaceService>();
      filtered = filtered.where((place) {
        return placeService.isPlaceSaved(place.googlePlaceId);
      }).toList();
    }

    // Filter by open now
    if (_filterOpenNow) {
      filtered = filtered.where((place) {
        // For now, assume all places are open (Google API doesn't always provide opening hours)
        // In production, check place.openingHours or use a more sophisticated check
        return true; // TODO: Implement actual open/closed check when API provides data
      }).toList();
    }

    // Filter by rating 4.5+
    if (_filterRating45Plus) {
      filtered = filtered.where((place) {
        return place.rating != null && place.rating! >= 4.5;
      }).toList();
    }

    // Filter by has photos
    if (_filterPlaceHasPhotos) {
      filtered = filtered.where((place) {
        return place.photoReferences.isNotEmpty;
      }).toList();
    }

    return filtered;
  }

  // Check if any place filters are active
  bool _hasActiveFilters() {
    return _filterSavedOnly ||
        _filterOpenNow ||
        _filterRating45Plus ||
        _filterPlaceHasPhotos ||
        _selectedDietaryFilters.isNotEmpty;
  }

  void _showCategoryPicker() {
    // Implementation for category picker
  }

  void _showDateFilterPicker() {
    // Implementation for date filter picker
  }

  void _showDietaryFilterPicker() {
    // Implementation for dietary filter picker
  }

  (DateTime, DateTime) _currentDateRange() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return (now, now);
      case 'this_week':
        return (now, now.add(const Duration(days: 7)));
      case 'this_month':
        return (now, now.add(const Duration(days: 30)));
      default:
        return (now, now.add(const Duration(days: 7)));
    }
  }
}
