import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/models/place_model.dart';

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
  bool _filterRating4Plus = false;
  bool _filterHasPhotos = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
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
      });
      return;
    }

    setState(() => _isSearching = true);

    final googlePlaces = GooglePlacesService();
    final placeType = _tabController.index == 0 
        ? PlaceType.gym 
        : _tabController.index == 1 
            ? PlaceType.restaurant 
            : null;

    if (placeType != null) {
      // Search via Google Places API
      final results = await googlePlaces.searchPlacesByText(
        query: query,
        placeType: placeType,
        // Salt Lake City coordinates as default
        latitude: 40.7608,
        longitude: -111.8910,
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
                    'Find gyms & healthy food nearby',
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
                  hintText: 'Search places...',
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
                indicator: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: textStyles.labelLarge,
                tabs: [
                  Tab(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 16),
                      const SizedBox(width: 6),
                      const Text('Gyms'),
                    ],
                  )),
                  Tab(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 16),
                      const SizedBox(width: 6),
                      const Text('Food'),
                    ],
                  )),
                  Tab(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark, size: 16),
                      const SizedBox(width: 6),
                      const Text('Saved'),
                    ],
                  )),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 16),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
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
                  const _SavedPlacesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            Text('No saved places yet', style: textStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Save gyms and restaurants you want to visit',
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
          Text('No ${type == PlaceType.gym ? 'gyms' : 'restaurants'} found', style: textStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try searching for places nearby',
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
      onTap: () => context.push('/place-detail', extra: place),
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
