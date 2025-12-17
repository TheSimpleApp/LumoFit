import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/utils/haptic_utils.dart';
import 'package:geolocator/geolocator.dart';

class DiscoverScreen extends StatefulWidget {
  final int initialTabIndex;
  const DiscoverScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
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
    // Location (defaults to SLC center)
    double _centerLat = 40.7608;
    double _centerLng = -111.8910;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 4));
      _initLocation();
  }

  @override
  void dispose() {
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
        if (mounted) {
          setState(() {
            _eventResults = results;
            _isSearchingEvents = false;
          });
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
    try {
      // Avoid prompting repeatedly; ask once when screen mounts
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
      });
    } catch (e) {
      // Non-fatal: keep defaults
    }
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
                      .animate().fadeIn().slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                    'Find gyms, food & events nearby',
                    style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
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
                          icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
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
                overlayColor: const MaterialStatePropertyAll(Colors.transparent),
                tabs: [
                  Tab(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, size: 16),
                      const SizedBox(width: 6),
                      const Text('Gyms', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant, size: 16),
                      const SizedBox(width: 6),
                      const Text('Food', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 16),
                      const SizedBox(width: 6),
                      const Text('Events', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terrain, size: 16),
                      const SizedBox(width: 6),
                      const Text('Trails', overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Tab(child: Row(
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

            // Filters (contextual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_tabController.index == 2) ...[
                      ChoiceChip(
                        selected: _dateFilter == 'this_week',
                        onSelected: (_) => setState(() => _dateFilter = 'this_week'),
                        label: const Text('This week'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        selected: _dateFilter == 'weekend',
                        onSelected: (_) => setState(() => _dateFilter = 'weekend'),
                        label: const Text('Weekend'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        selected: _dateFilter == '30d',
                        onSelected: (_) => setState(() => _dateFilter = '30d'),
                        label: const Text('Next 30 days'),
                      ),
                      const SizedBox(width: 12),
                      _CategoryChip(
                        icon: Icons.directions_run,
                        label: 'Running',
                        category: EventCategory.running,
                        selected: _selectedCategories.contains(EventCategory.running),
                        onTap: () => setState(() => _toggleCategory(EventCategory.running)),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        icon: Icons.self_improvement,
                        label: 'Yoga',
                        category: EventCategory.yoga,
                        selected: _selectedCategories.contains(EventCategory.yoga),
                        onTap: () => setState(() => _toggleCategory(EventCategory.yoga)),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        icon: Icons.terrain,
                        label: 'Hiking',
                        category: EventCategory.hiking,
                        selected: _selectedCategories.contains(EventCategory.hiking),
                        onTap: () => setState(() => _toggleCategory(EventCategory.hiking)),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        icon: Icons.pedal_bike,
                        label: 'Cycling',
                        category: EventCategory.cycling,
                        selected: _selectedCategories.contains(EventCategory.cycling),
                        onTap: () => setState(() => _toggleCategory(EventCategory.cycling)),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        icon: Icons.fitness_center,
                        label: 'CrossFit',
                        category: EventCategory.crossfit,
                        selected: _selectedCategories.contains(EventCategory.crossfit),
                        onTap: () => setState(() => _toggleCategory(EventCategory.crossfit)),
                      ),
                    ] else ...[
                      FilterChip(
                        selected: _filterRating4Plus,
                        onSelected: (v) => setState(() => _filterRating4Plus = v),
                        label: const Text('Rating 4.0+'),
                        avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _filterHasPhotos,
                        onSelected: (v) => setState(() => _filterHasPhotos = v),
                        label: const Text('With photos'),
                        avatar: const Icon(Icons.photo_library_outlined, size: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PlacesList(
                    type: PlaceType.gym,
                    searchQuery: _searchQuery,
                    searchResults: _searchResults,
                    isSearching: _isSearching,
                    filterRating4Plus: _filterRating4Plus,
                    filterHasPhotos: _filterHasPhotos,
                  ),
                  _PlacesList(
                    type: PlaceType.restaurant,
                    searchQuery: _searchQuery,
                    searchResults: _searchResults,
                    isSearching: _isSearching,
                    filterRating4Plus: _filterRating4Plus,
                    filterHasPhotos: _filterHasPhotos,
                  ),
                  _EventsList(
                    searchQuery: _searchQuery,
                    isSearching: _isSearchingEvents,
                    categories: _selectedCategories,
                    dateFilter: _dateFilter,
                    eventResults: _eventResults,
                  ),
                  _PlacesList(
                    type: PlaceType.trail,
                    searchQuery: _searchQuery,
                    searchResults: _searchResults,
                    isSearching: _isSearching,
                    filterRating4Plus: _filterRating4Plus,
                    filterHasPhotos: _filterHasPhotos,
                  ),
                  const _SavedPlacesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCategory(EventCategory c) {
    if (_selectedCategories.contains(c)) {
      _selectedCategories.remove(c);
    } else {
      _selectedCategories.add(c);
    }
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    } else {
      setState(() {});
    }
  }

  // Returns a tuple (start, end) based on UI selection
  (DateTime, DateTime) _currentDateRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    switch (_dateFilter) {
      case 'weekend':
        // Next Sat-Sun
        final nextSat = now.add(Duration(days: (6 - now.weekday + 7) % 7));
        final nextSun = nextSat.add(const Duration(days: 1));
        return (DateTime(nextSat.year, nextSat.month, nextSat.day), DateTime(nextSun.year, nextSun.month, nextSun.day, 23, 59));
      case '30d':
        final end = now.add(const Duration(days: 30));
        return (DateTime(now.year, now.month, now.day), DateTime(end.year, end.month, end.day, 23, 59));
      case 'this_week':
      default:
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return (DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59));
    }
  }
}

class _PlacesList extends StatelessWidget {
  final PlaceType type;
  final String searchQuery;
  final List<PlaceModel> searchResults;
  final bool isSearching;
  final bool filterRating4Plus;
  final bool filterHasPhotos;

  const _PlacesList({
    required this.type,
    required this.searchQuery,
    required this.searchResults,
    required this.isSearching,
    required this.filterRating4Plus,
    required this.filterHasPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final placeService = context.watch<PlaceService>();
    final reviewService = context.watch<ReviewService>();
    final photoService = context.watch<CommunityPhotoService>();
    
    // If searching, show search results filtered by type
    if (searchQuery.isNotEmpty) {
      final filtered = searchResults.where((p) => p.type == type).toList();
      
      if (isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (filtered.isEmpty) {
        return _EmptySearchState(type: type, query: searchQuery);
      }
      
      // Apply filters to search results
      final filtered2 = _applyFilters(filtered, reviewService, photoService);
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered2.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlaceCard(place: filtered2[index])
              .animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, delay: (index * 50).ms),
        ),
      );
    }
    
    // Show local saved places
    var places = placeService.getPlacesByType(type);
    places = _applyFilters(places, reviewService, photoService);
    
    if (places.isEmpty) return _EmptyState(type: type);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: places.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PlaceCard(place: places[index])
            .animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, delay: (index * 100).ms),
      ),
    );
  }

  List<PlaceModel> _applyFilters(List<PlaceModel> input, ReviewService reviewService, CommunityPhotoService photoService) {
    var out = input;
    if (filterRating4Plus) {
      out = out.where((p) {
        final avg = reviewService.getAverageRating(p.id);
        return (avg ?? 0) >= 4.0;
      }).toList();
    }
    if (filterHasPhotos) {
      out = out.where((p) => photoService.getPhotosForPlace(p.id).isNotEmpty).toList();
    }
    // Sort by community signal: avg rating desc, then photo count desc
    out.sort((a, b) {
      final avgA = reviewService.getAverageRating(a.id) ?? 0;
      final avgB = reviewService.getAverageRating(b.id) ?? 0;
      final cmp = avgB.compareTo(avgA);
      if (cmp != 0) return cmp;
      final pcA = photoService.getPhotosForPlace(a.id).length;
      final pcB = photoService.getPhotosForPlace(b.id).length;
      return pcB.compareTo(pcA);
    });
    return out;
  }
}

class _EventsList extends StatelessWidget {
  final String searchQuery;
  final bool isSearching;
  final Set<EventCategory> categories;
  final String dateFilter;
  final List<EventModel> eventResults;

  const _EventsList({
    required this.searchQuery,
    required this.isSearching,
    required this.categories,
    required this.dateFilter,
    required this.eventResults,
  });

  @override
  Widget build(BuildContext context) {
    final eventService = context.watch<EventService>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // If searching, use provided results; otherwise compute from filters
    List<EventModel> data;
    if (searchQuery.isNotEmpty) {
      data = eventResults;
    } else {
      final now = DateTime.now();
      DateTime start;
      DateTime end;
      switch (dateFilter) {
        case 'weekend':
          final nextSat = now.add(Duration(days: (6 - now.weekday + 7) % 7));
          final nextSun = nextSat.add(const Duration(days: 1));
          start = DateTime(nextSat.year, nextSat.month, nextSat.day);
          end = DateTime(nextSun.year, nextSun.month, nextSun.day, 23, 59);
          break;
        case '30d':
          final endTmp = now.add(const Duration(days: 30));
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(endTmp.year, endTmp.month, endTmp.day, 23, 59);
          break;
        case 'this_week':
        default:
          final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59);
      }
      data = eventService.search(
        query: '',
        categories: categories,
        startDate: start,
        endDate: end,
        centerLat: 40.7608,
        centerLng: -111.8910,
        radiusKm: 50,
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No events found', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('Try a different date window or category', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: data.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: EventCard(event: data[index])
            .animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.06, delay: (index * 60).ms),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? colors.primary : colors.outline.withValues(alpha: 0.7), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? colors.primary : colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: text.labelMedium?.copyWith(color: selected ? colors.primary : colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        HapticUtils.light();
        context.push('/event-detail', extra: event);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            child: Center(child: Text(eventCategoryEmoji(event.category), style: const TextStyle(fontSize: 28))),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.event, size: 14, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${event.shortDate} • ${event.shortTime}', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                      ]),
                      if (event.venueName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.place, size: 14, color: colors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event.venueName, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
            if ((event.source ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      (event.source!).toUpperCase(),
                      style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedPlacesList extends StatelessWidget {
  const _SavedPlacesList();

  @override
  Widget build(BuildContext context) {
    final placeService = context.watch<PlaceService>();
    final places = placeService.savedPlaces;
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Nothing saved yet', style: textStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Discover places in the tabs above and\nsave your favorites to see them here',
              style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group by type
    final gyms = places.where((p) => p.type == PlaceType.gym).toList();
    final restaurants = places.where((p) => p.type == PlaceType.restaurant).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (gyms.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.fitness_center,
            title: 'Gyms',
            count: gyms.length,
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          ...gyms.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlaceCard(place: entry.value, showSaveButton: true)
                .animate().fadeIn(delay: (entry.key * 50).ms),
          )),
        ],
        if (restaurants.isNotEmpty) ...[
          if (gyms.isNotEmpty) const SizedBox(height: 8),
          _SectionHeader(
            icon: Icons.restaurant,
            title: 'Restaurants',
            count: restaurants.length,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...restaurants.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlaceCard(place: entry.value, showSaveButton: true)
                .animate().fadeIn(delay: ((gyms.length + entry.key) * 50).ms),
          )),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(title, style: textStyles.titleMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: textStyles.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final PlaceType type;

  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(type == PlaceType.gym ? '🏋️' : '🥗', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No ${type == PlaceType.gym ? 'gyms' : 'food spots'} saved yet', style: textStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Search above to discover places nearby',
            style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final PlaceType type;
  final String query;

  const _EmptySearchState({required this.type, required this.query});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No results for "$query"', style: textStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Reusable Place Card widget
class PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final bool showSaveButton;

  const PlaceCard({
    super.key,
    required this.place,
    this.showSaveButton = false,
  });

  Color _getPlaceColor(PlaceType type) {
    switch (type) {
      case PlaceType.gym: return AppColors.primary;
      case PlaceType.restaurant: return AppColors.success;
      case PlaceType.park: return AppColors.info;
      case PlaceType.trail: return AppColors.warning;
      case PlaceType.other: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        HapticUtils.light();
        context.push('/place-detail', extra: place);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getPlaceColor(place.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(child: Text(place.typeEmoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: textStyles.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (place.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.address!,
                          style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showSaveButton)
                  _SaveButton(place: place),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (place.rating != null) ...[
                  Icon(Icons.star, size: 16, color: AppColors.xp),
                  const SizedBox(width: 4),
                  Text(place.rating!.toStringAsFixed(1), style: textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (place.userRatingsTotal != null) ...[
                    const SizedBox(width: 4),
                    Text('(${place.userRatingsTotal})', style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ],
                if (place.priceLevel != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(place.priceLevel!, style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                ],
                const Spacer(),
                if (place.isVisited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('Visited', style: textStyles.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final PlaceModel place;

  const _SaveButton({required this.place});

  @override
  Widget build(BuildContext context) {
    final placeService = context.watch<PlaceService>();
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () async {
        await HapticUtils.medium();
        await placeService.removePlace(place.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Removed from saved places'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          );
        }
      },
      icon: Icon(Icons.bookmark, color: AppColors.xp),
      tooltip: 'Remove from saved',
    );
  }
}
