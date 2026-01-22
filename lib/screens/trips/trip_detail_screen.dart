import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/place_service.dart';
import 'package:uuid/uuid.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final placeService = context.watch<PlaceService>();
    final trip = tripService.getTripById(widget.tripId);
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Trip'),
        ),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final dateRange =
        '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}';

    // Sort saved places based on the order in trip.savedPlaceIds
    final associatedPlaces = trip.savedPlaceIds
        .map((id) => placeService.getPlaceById(id))
        .whereType<PlaceModel>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.destinationCity,
              style: textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dateRange,
              style: textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit trip',
            onPressed: () => _showEditTripSheet(context, trip),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              if (!trip.isActive)
                const PopupMenuItem(
                    value: 'activate', child: Text('Set Active Trip')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Trip')),
            ],
            onSelected: (value) async {
              final tripService = context.read<TripService>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              if (value == 'activate') {
                await tripService.setActiveTrip(trip.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Active trip set'),
                        behavior: SnackBarBehavior.floating),
                  );
                }
              } else if (value == 'delete') {
                if (!mounted) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Trip?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await tripService.deleteTrip(trip.id);
                  if (mounted) router.pop();
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Itinerary'),
            Tab(text: 'Bucket List'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Trip info header
          _TripInfoHeader(
            trip: trip,
            placesCount: associatedPlaces.length,
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItineraryTab(trip: trip, associatedPlaces: associatedPlaces),
                _BucketListTab(trip: trip, associatedPlaces: associatedPlaces),
                _ActivityTab(trip: trip, allPlaces: placeService.savedPlaces),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTripSheet(BuildContext context, TripModel trip) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTripSheet(trip: trip),
    );
  }
}

// ----------------- Tabs -----------------

class _ItineraryTab extends StatefulWidget {
  final TripModel trip;
  final List<PlaceModel> associatedPlaces;
  const _ItineraryTab({required this.trip, required this.associatedPlaces});

  @override
  State<_ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<_ItineraryTab> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.trip.startDate.year,
        widget.trip.startDate.month, widget.trip.startDate.day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final svc = context.watch<TripService>();
    final items = svc.getItinerary(widget.trip.id, forDate: _selectedDate);

    final days = List<DateTime>.generate(
      widget.trip.durationDays,
      (i) => DateTime(widget.trip.startDate.year, widget.trip.startDate.month,
              widget.trip.startDate.day)
          .add(Duration(days: i)),
    );

    return CustomScrollView(
      slivers: [
        // Pinned Day Picker Header
        SliverPersistentHeader(
          pinned: true,
          delegate: _DayPickerHeaderDelegate(
            days: days,
            selectedDate: _selectedDate,
            onDateSelected: (d) => setState(() => _selectedDate = d),
            colors: colors,
            textStyles: textStyles,
          ),
        ),

        // Date Header & Add Button
        SliverToBoxAdapter(
          child: Container(
            color: colors.surface,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('EEEE, MMMM d').format(_selectedDate),
                    style: textStyles.titleMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
                FilledButton.icon(
                  onPressed: () => _showAddItemSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Itinerary Content
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Empty state header
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_note,
                            size: 48,
                            color: colors.outline.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No plans for this day',
                          style: textStyles.titleMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add activities to build your itinerary',
                          style: textStyles.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Quick Add Section
                  Text('Quick Add',
                      style: textStyles.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickAddChip(
                        emoji: '🏋️',
                        label: 'Gym Session',
                        onTap: () =>
                            _quickAddItem(context, 'Gym Session', '🏋️'),
                      ),
                      _QuickAddChip(
                        emoji: '🥗',
                        label: 'Healthy Meal',
                        onTap: () =>
                            _quickAddItem(context, 'Healthy Meal', '🥗'),
                      ),
                      _QuickAddChip(
                        emoji: '🏃',
                        label: 'Morning Run',
                        onTap: () =>
                            _quickAddItem(context, 'Morning Run', '🏃'),
                      ),
                      _QuickAddChip(
                        emoji: '🧘',
                        label: 'Yoga Class',
                        onTap: () => _quickAddItem(context, 'Yoga Class', '🧘'),
                      ),
                      _QuickAddChip(
                        emoji: '🍳',
                        label: 'Breakfast',
                        onTap: () => _quickAddItem(context, 'Breakfast', '🍳'),
                      ),
                      _QuickAddChip(
                        emoji: '☕',
                        label: 'Coffee Break',
                        onTap: () =>
                            _quickAddItem(context, 'Coffee Break', '☕'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // AI Suggestions
                  Text('Suggestions for ${widget.trip.destinationCity}',
                      style: textStyles.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology,
                                color: colors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'AI-Powered Suggestions',
                              style: textStyles.titleSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Get personalized fitness recommendations for your trip to ${widget.trip.destinationCity}.',
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.push('/fitness-guide'),
                          child: const Text('Get Recommendations'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Saved Places Section
                  if (widget.associatedPlaces.isNotEmpty) ...[
                    Text('Add from Saved Places',
                        style: textStyles.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...widget.associatedPlaces.take(3).map((place) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Center(
                                child: Text(place.typeEmoji,
                                    style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            title: Text(place.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(place.type.name,
                                style:
                                    TextStyle(color: colors.onSurfaceVariant)),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  _addPlaceToItinerary(context, place),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              side: BorderSide(
                                  color: colors.outline.withValues(alpha: 0.1)),
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          )
        else
          SliverReorderableList(
            itemCount: items.length,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: child,
            ),
            onReorder: (oldIndex, newIndex) {
              final list = List<ItineraryItem>.from(items);
              if (newIndex > oldIndex) newIndex -= 1;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              context
                  .read<TripService>()
                  .reorderItinerary(widget.trip.id, _mergeDay(list));
            },
            itemBuilder: (context, index) {
              final it = items[index];
              PlaceModel? match;
              if (it.placeId != null) {
                try {
                  match = widget.associatedPlaces
                      .firstWhere((p) => p.id == it.placeId);
                } catch (_) {
                  match = null;
                }
              }
              return Padding(
                key: ValueKey(it.id),
                padding: EdgeInsets.fromLTRB(
                    12, index == 0 ? 8 : 0, 16, index == items.length - 1 ? 80 : 0),
                child: _ItineraryTile(
                  item: it,
                  place: match,
                  index: index,
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                  onEdit: () => _showEditItemSheet(context, it),
                  onDelete: () => context
                      .read<TripService>()
                      .removeItineraryItem(widget.trip.id, it.id),
                ),
              );
            },
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ItineraryItem> _mergeDay(List<ItineraryItem> dayItems) {
    final svc = context.read<TripService>();
    final all = svc.getItinerary(widget.trip.id);
    final others =
        all.where((e) => !_isSameDay(e.date, _selectedDate)).toList();
    return [...others, ...dayItems];
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOrEditItinerarySheet(
        trip: widget.trip,
        date: _selectedDate,
        associatedPlaces: widget.associatedPlaces,
      ),
    );
  }

  Future<void> _showEditItemSheet(
      BuildContext context, ItineraryItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOrEditItinerarySheet(
        trip: widget.trip,
        date: item.date,
        associatedPlaces: widget.associatedPlaces,
        existing: item,
      ),
    );
  }

  void _quickAddItem(BuildContext context, String title, String emoji) {
    final item = ItineraryItem(
      id: const Uuid().v4(),
      date: _selectedDate,
      title: '$emoji $title',
    );
    context.read<TripService>().addItineraryItem(widget.trip.id, item);
  }

  void _addPlaceToItinerary(BuildContext context, PlaceModel place) {
    final item = ItineraryItem(
      id: const Uuid().v4(),
      date: _selectedDate,
      title: place.name,
      placeId: place.id,
    );
    context.read<TripService>().addItineraryItem(widget.trip.id, item);
  }
}

/// Sliver persistent header delegate for pinned day picker
class _DayPickerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ColorScheme colors;
  final TextTheme textStyles;

  _DayPickerHeaderDelegate({
    required this.days,
    required this.selectedDate,
    required this.onDateSelected,
    required this.colors,
    required this.textStyles,
  });

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final now = DateTime.now();
    final todayIndex = days.indexWhere((d) => _isSameDay(d, now));
    final selectedIndex = days.indexWhere((d) => _isSameDay(d, selectedDate));

    return Container(
      color: colors.surface,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Today button (if today is within trip dates)
                if (todayIndex >= 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onDateSelected(days[todayIndex]),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: textStyles.labelMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Day picker
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(todayIndex >= 0 ? 8 : 16, 8, 16, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final d = days[index];
                      final isSel = index == selectedIndex;
                      final isToday = _isSameDay(d, now);

                      return GestureDetector(
                        onTap: () => onDateSelected(d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? colors.primary
                                : isToday
                                    ? colors.primaryContainer.withValues(alpha: 0.5)
                                    : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: isToday && !isSel
                                ? Border.all(color: colors.primary, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(d),
                                style: textStyles.labelSmall?.copyWith(
                                  color: isSel ? colors.onPrimary.withValues(alpha: 0.9) : colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.day}',
                                style: textStyles.titleMedium?.copyWith(
                                  color: isSel ? colors.onPrimary : colors.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(d),
                                style: textStyles.labelSmall?.copyWith(
                                  color: isSel ? colors.onPrimary.withValues(alpha: 0.8) : colors.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.outline.withValues(alpha: 0.1)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  bool shouldRebuild(covariant _DayPickerHeaderDelegate oldDelegate) {
    return days != oldDelegate.days ||
        selectedDate != oldDelegate.selectedDate ||
        colors != oldDelegate.colors;
  }
}

class _BucketListTab extends StatelessWidget {
  final TripModel trip;
  final List<PlaceModel> associatedPlaces;
  const _BucketListTab({required this.trip, required this.associatedPlaces});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final tripService = context.watch<TripService>();
    final placeService = context.watch<PlaceService>();

    if (associatedPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border,
                  size: 48, color: colors.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Your Bucket List is empty',
                style: textStyles.titleMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Add places you want to visit to build your trip backlog.',
                textAlign: TextAlign.center,
                style: textStyles.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showAddPlacesSheet(context, trip),
                icon: const Icon(Icons.add),
                label: const Text('Add Places'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Want to go', style: textStyles.titleMedium),
              TextButton.icon(
                onPressed: () => _showAddPlacesSheet(context, trip),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            itemCount: associatedPlaces.length,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: child,
            ),
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final itemToMove = associatedPlaces[oldIndex];

              // Construct mutable copy of IDs
              final ids = List<String>.from(trip.savedPlaceIds);

              // Remove the ID
              ids.remove(itemToMove.id);

              // Determine insertion index in the full 'ids' list
              // The visual list (minus moved item)
              final visibleIds = associatedPlaces.map((p) => p.id).toList();
              visibleIds.removeAt(oldIndex);

              if (newIndex >= visibleIds.length) {
                // Appending to the end of the visual list -> end of ids
                ids.add(itemToMove.id);
              } else {
                // Inserting before an existing visible item
                final nextVisibleId = visibleIds[newIndex];
                final indexInIds = ids.indexOf(nextVisibleId);
                if (indexInIds >= 0) {
                  ids.insert(indexInIds, itemToMove.id);
                } else {
                  ids.add(itemToMove.id);
                }
              }

              final updatedTrip = trip.copyWith(savedPlaceIds: ids);
              await tripService.updateTrip(updatedTrip);
            },
            itemBuilder: (context, index) {
              final place = associatedPlaces[index];
              return Padding(
                key: ValueKey(place.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _BucketListTile(
                  place: place,
                  index: index,
                  onToggleVisited: () {
                    final updated = place.copyWith(
                      isVisited: !place.isVisited,
                      visitedAt: !place.isVisited ? DateTime.now() : null,
                    );
                    placeService.updatePlace(updated);
                  },
                  onDelete: () =>
                      tripService.removePlaceFromTrip(trip.id, place.id),
                  onOpen: () => context.push('/place-detail', extra: place),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddPlacesSheet(BuildContext context, TripModel trip) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPlacesSheet(trip: trip),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final TripModel trip;
  final List<PlaceModel> allPlaces;
  const _ActivityTab({required this.trip, required this.allPlaces});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _TimelineList(trip: trip, allPlaces: allPlaces),
    );
  }
}

// ----------------- Components -----------------

class _TripInfoHeader extends StatelessWidget {
  final TripModel trip;
  final int placesCount;

  const _TripInfoHeader({
    required this.trip,
    required this.placesCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status pill
          _buildStatusChip(context, trip.status),
          const SizedBox(width: 12),
          // Stats
          _buildStat(context, '${trip.durationDays}', 'days'),
          const SizedBox(width: 12),
          _buildStat(context, '$placesCount', 'places'),
          const Spacer(),
          // Active indicator
          if (trip.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Active',
                    style: textStyles.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final textStyles = Theme.of(context).textTheme;
    final color = _colorForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status,
        style: textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: textStyles.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Current':
        return AppColors.primary;
      case 'Upcoming':
        return AppColors.info;
      case 'Past':
      default:
        return AppColors.muted;
    }
  }
}

class _ItineraryTile extends StatelessWidget {
  final ItineraryItem item;
  final PlaceModel? place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _ItineraryTile({
    required this.item,
    required this.place,
    required this.onEdit,
    required this.onDelete,
    required this.index,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    String timeLabel = item.startTime ?? '--:--';
    final emoji = place?.typeEmoji ?? '📝';
    final subtitle = item.notes;
    final typeColor = _getTypeColor(place?.type, colors);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 60,
          child: Column(
            children: [
              // Time label
              Text(
                timeLabel,
                style: textStyles.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              // Timeline dot and line
              SizedBox(
                height: 60,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                typeColor,
                                typeColor.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Card content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Icon(Icons.drag_indicator,
                        color: colors.outline, size: 20),
                  ),
                ),
                // Leading emoji
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyles.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (item.durationMinutes != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 14, color: colors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${item.durationMinutes} min',
                                style: textStyles.labelSmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 20, color: colors.error),
                          const SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: colors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(PlaceType? type, ColorScheme colors) {
    switch (type) {
      case PlaceType.gym:
        return Colors.blue;
      case PlaceType.restaurant:
        return Colors.orange;
      case PlaceType.trail:
      case PlaceType.park:
        return Colors.green;
      default:
        return colors.primary;
    }
  }
}

class _BucketListTile extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onToggleVisited;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final int index;

  const _BucketListTile({
    required this.place,
    required this.onToggleVisited,
    required this.onDelete,
    required this.onOpen,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: place.isVisited
                ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Icon(Icons.drag_indicator,
                      color: colors.outline, size: 20),
                ),
              ),
              // Leading emoji
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: place.isVisited
                      ? colors.secondary.withValues(alpha: 0.1)
                      : colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                    child: Text(place.typeEmoji,
                        style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: place.isVisited
                              ? TextDecoration.lineThrough
                              : null,
                          color: place.isVisited
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.typeLabel,
                        style: textStyles.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              // Visited checkbox
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: place.isVisited,
                  onChanged: (_) => onToggleVisited(),
                  activeColor: AppColors.success,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              // Delete action
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: colors.onSurfaceVariant, size: 20),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: colors.error),
                        const SizedBox(width: 12),
                        Text('Remove', style: TextStyle(color: colors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  final TripModel trip;
  final List<PlaceModel> allPlaces;
  const _TimelineList({required this.trip, required this.allPlaces});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final visited = allPlaces
        .where((p) => p.isVisited && p.visitedAt != null)
        .where((p) =>
            !p.visitedAt!.isBefore(trip.startDate) &&
            !p.visitedAt!.isAfter(trip.endDate))
        .toList()
      ..sort((a, b) => a.visitedAt!.compareTo(b.visitedAt!));

    if (visited.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    'No activity on this trip yet. Mark places as visited in your Bucket List.',
                    style: textStyles.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant))),
          ],
        ),
      );
    }

    final groups = <String, List<PlaceModel>>{};
    for (final p in visited) {
      final key = DateFormat('EEE, MMM d').format(p.visitedAt!);
      groups.putIfAbsent(key, () => []).add(p);
    }

    return Column(
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: textStyles.labelLarge),
                const SizedBox(height: 8),
                ...entry.value.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(
                              child: Text('${p.typeLabel}: ${p.name}',
                                  style: textStyles.bodyMedium)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddPlacesSheet extends StatelessWidget {
  final TripModel trip;
  const _AddPlacesSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final places = context.watch<PlaceService>().savedPlaces;
    final tripPlaceIds = context.watch<TripService>().getTripById(trip.id)?.savedPlaceIds ?? trip.savedPlaceIds;
    final addedCount = tripPlaceIds.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Places', style: textStyles.titleLarge),
                        Text(
                          '$addedCount places in trip',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
            // Content
            if (places.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.bookmark_border, size: 48, color: colors.outline),
                    const SizedBox(height: 16),
                    Text('No saved places yet', style: textStyles.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Discover and save places first, then add them to your trip.',
                      textAlign: TextAlign.center,
                      style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/discover');
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Discover Places'),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final p = places[index];
                    final isAdded = tripPlaceIds.contains(p.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isAdded
                            ? colors.primaryContainer.withValues(alpha: 0.3)
                            : colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () async {
                            final tripService = context.read<TripService>();
                            if (isAdded) {
                              await tripService.removePlaceFromTrip(trip.id, p.id);
                            } else {
                              await tripService.addPlaceToTrip(trip.id, p.id);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Center(child: Text(p.typeEmoji)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: textStyles.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        p.typeLabel,
                                        style: textStyles.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isAdded ? Icons.check_circle : Icons.add_circle_outline,
                                  color: isAdded ? AppColors.success : colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditTripSheet extends StatefulWidget {
  final TripModel trip;
  const _EditTripSheet({required this.trip});

  @override
  State<_EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends State<_EditTripSheet> {
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.trip.destinationCity);
    _countryController =
        TextEditingController(text: widget.trip.destinationCountry ?? '');
    _notesController = TextEditingController(text: widget.trip.notes ?? '');
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Edit Trip', style: textStyles.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20, 16, 20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'Destination City',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country (optional)',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DateSelector(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateSelector(
                            label: 'End Date',
                            date: _endDate,
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Changes'),
                      ),
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

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_cityController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final svc = context.read<TripService>();
      final updated = widget.trip.copyWith(
        destinationCity: _cityController.text.trim(),
        destinationCountry: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await svc.updateTrip(updated);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateSelector(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(DateFormat('MMM d, yyyy').format(date),
                  style: textStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOrEditItinerarySheet extends StatefulWidget {
  final TripModel trip;
  final DateTime date;
  final List<PlaceModel> associatedPlaces;
  final ItineraryItem? existing;
  const _AddOrEditItinerarySheet({
    required this.trip,
    required this.date,
    required this.associatedPlaces,
    this.existing,
  });

  @override
  State<_AddOrEditItinerarySheet> createState() =>
      _AddOrEditItinerarySheetState();
}

class _AddOrEditItinerarySheetState extends State<_AddOrEditItinerarySheet> {
  PlaceModel? _selectedPlace;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  String? _startTime;
  int _duration = 60;

  static const List<int> _durationOptions = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    // Initialize from existing item if editing
    if (widget.existing != null) {
      _titleController = TextEditingController(text: widget.existing!.title);
      _notesController = TextEditingController(text: widget.existing?.notes ?? '');
      _startTime = widget.existing?.startTime;
      _duration = widget.existing?.durationMinutes ?? 60;
      // Find matching place if exists
      if (widget.existing!.placeId != null) {
        try {
          _selectedPlace = widget.associatedPlaces
              .firstWhere((p) => p.id == widget.existing!.placeId);
        } catch (_) {}
      }
    } else {
      _titleController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final isEditing = widget.existing != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Activity' : 'Add Activity',
                      style: textStyles.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close_activity_sheet'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20, 16, 20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Activity name',
                        hintText: 'e.g., Morning Run, Gym Session',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        // Clear place selection when typing custom title
                        if (_selectedPlace != null) {
                          setState(() => _selectedPlace = null);
                        }
                      },
                    ),
                    // Place selector (if places available)
                    if (widget.associatedPlaces.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Or select from your saved places:',
                        style: textStyles.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.associatedPlaces.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final place = widget.associatedPlaces[index];
                            final isSelected = _selectedPlace?.id == place.id;
                            return FilterChip(
                              selected: isSelected,
                              label: Text(
                                '${place.typeEmoji} ${place.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedPlace = place;
                                    _titleController.text = place.name;
                                  } else {
                                    _selectedPlace = null;
                                  }
                                });
                              },
                              selectedColor: colors.primaryContainer,
                              checkmarkColor: colors.primary,
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Time picker
                    Text('Time', style: textStyles.labelLarge),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: colors.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _startTime ?? 'Set start time',
                              style: textStyles.bodyLarge?.copyWith(
                                color: _startTime != null ? colors.onSurface : colors.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: colors.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Duration picker (inline chips)
                    Text('Duration', style: textStyles.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _durationOptions.map((mins) {
                        final isSelected = _duration == mins;
                        final label = mins >= 60
                            ? '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}'
                            : '${mins}m';
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(label),
                          onSelected: (_) => setState(() => _duration = mins),
                          selectedColor: colors.primaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any details...',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: Text(isEditing ? 'Save Changes' : 'Add to Itinerary'),
                      ),
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

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickTime() async {
    final initial = _startTime ?? '09:00';
    final parts = initial.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      ),
    );
    if (t != null) {
      setState(() {
        _startTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final svc = context.read<TripService>();
    final date = DateTime(widget.date.year, widget.date.month, widget.date.day);

    final item = (widget.existing ?? ItineraryItem(
      id: const Uuid().v4(),
      date: date,
      title: _titleController.text.trim(),
    )).copyWith(
      date: date,
      title: _titleController.text.trim(),
      placeId: _selectedPlace?.id,
      startTime: _startTime,
      durationMinutes: _duration,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (widget.existing == null) {
      await svc.addItineraryItem(widget.trip.id, item);
    } else {
      await svc.updateItineraryItem(widget.trip.id, item);
    }

    if (mounted) Navigator.pop(context);
  }
}

/// Quick add chip for common itinerary items
class _QuickAddChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
