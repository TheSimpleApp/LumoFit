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
        '${DateFormat('MMM d, yyyy').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}';

    // Sort saved places based on the order in trip.savedPlaceIds
    final associatedPlaces = trip.savedPlaceIds
        .map((id) => placeService.getPlaceById(id))
        .whereType<PlaceModel>()
        .toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: colors.onSurface),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Edit trip',
                  onPressed: () => _showEditTripSheet(context, trip),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, color: colors.onSurface),
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    if (!trip.isActive)
                      const PopupMenuItem(
                          value: 'activate', child: Text('Set Active Trip')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete Trip')),
                  ],
                  onSelected: (value) async {
                    if (value == 'activate') {
                      await context.read<TripService>().setActiveTrip(trip.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Active trip set'),
                              behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Trip?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await context.read<TripService>().deleteTrip(trip.id);
                        if (mounted) context.pop();
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        colors.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text('✈️', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trip.destinationCity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyles.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateRange,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyles.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(status: trip.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          _QuickStat(
                              value: '${trip.durationDays}', label: 'Days'),
                          _QuickStat(
                              value: '${associatedPlaces.length}',
                              label: 'Places'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _ItineraryTab(trip: trip, associatedPlaces: associatedPlaces),
            _BucketListTab(trip: trip, associatedPlaces: associatedPlaces),
            _ActivityTab(trip: trip, allPlaces: placeService.savedPlaces),
          ],
        ),
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

    return Column(
      children: [
        // Day Picker pinned at top of tab
        Container(
          color: colors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final d = days[index];
                final isSel = _isSameDay(d, _selectedDate);
                return ChoiceChip(
                  showCheckmark: false,
                  selected: isSel,
                  label: Text(DateFormat('EEE, MMM d').format(d)),
                  onSelected: (_) => setState(() => _selectedDate = d),
                  selectedColor: colors.primaryContainer,
                  labelStyle: textStyles.labelMedium?.copyWith(
                    color: isSel ? colors.onPrimaryContainer : colors.onSurface,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                );
              },
            ),
          ),
        ),

        // Add Button & Date Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

        // Itinerary List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        'Tap "Add Item" to start planning.',
                        style: textStyles.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ItineraryTile(
                        item: it,
                        place: match,
                        onEdit: () => _showEditItemSheet(context, it),
                        onDelete: () => context
                            .read<TripService>()
                            .removeItineraryItem(widget.trip.id, it.id),
                      ),
                    );
                  },
                ),
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

class _ItineraryTile extends StatelessWidget {
  final ItineraryItem item;
  final PlaceModel? place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ItineraryTile(
      {required this.item,
      required this.place,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    String timeLabel = item.startTime ?? '--:--';
    final emoji = place?.typeEmoji ?? '📝';
    final subtitle = item.notes;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(timeLabel,
                  style: textStyles.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: subtitle == null || subtitle.isEmpty
            ? null
            : Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyles.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: onEdit,
                icon:
                    Icon(Icons.edit, size: 20, color: colors.onSurfaceVariant)),
            IconButton(
                onPressed: onDelete,
                icon:
                    Icon(Icons.delete_outline, size: 20, color: colors.error)),
            ReorderableDragStartListener(
              index:
                  0, // Not used by listener, but required by parent? No, standard usage is automatic in list
              child: Icon(Icons.drag_indicator, color: colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketListTile extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onToggleVisited;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _BucketListTile(
      {required this.place,
      required this.onToggleVisited,
      required this.onDelete,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: place.isVisited
            ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: place.isVisited
                ? colors.secondary.withValues(alpha: 0.1)
                : colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
              child:
                  Text(place.typeEmoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          place.name,
          style: textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: place.isVisited ? TextDecoration.lineThrough : null,
            color: place.isVisited ? colors.onSurfaceVariant : colors.onSurface,
          ),
        ),
        subtitle: Text(
          place.typeLabel,
          style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: place.isVisited,
              onChanged: (_) => onToggleVisited(),
              activeColor: AppColors.success,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: 0,
              child: Icon(Icons.drag_indicator, color: colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse existing components with minor updates if needed
// _StatusPill, _QuickStat, _DividerDot, _TimelineList, _AddPlacesSheet, _EditTripSheet, _DateSelector, _AddOrEditItinerarySheet
// I will copy them back in to ensure the file is complete.

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _colorFor(String s) {
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final c = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(status,
          style: textStyles.labelSmall
              ?.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  const _QuickStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: textStyles.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(label,
              style: textStyles.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text('Add places to trip', style: textStyles.titleLarge),
              const SizedBox(height: 12),
              if (places.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You have no saved places yet.',
                          style: textStyles.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.go('/discover'),
                        icon: const Icon(Icons.explore),
                        label: const Text('Discover places'),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final p = places[index];
                      final already = trip.savedPlaceIds.contains(p.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: already
                                ? null
                                : () async {
                                    await context
                                        .read<TripService>()
                                        .addPlaceToTrip(trip.id, p.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Added ${p.name}'),
                                            behavior:
                                                SnackBarBehavior.floating),
                                      );
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: colors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Center(child: Text(p.typeEmoji)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(p.name,
                                          style: textStyles.bodyMedium)),
                                  if (already)
                                    Icon(Icons.check, color: AppColors.success)
                                  else
                                    Icon(Icons.add, color: colors.primary),
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
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Edit Trip', style: textStyles.titleLarge),
              const SizedBox(height: 16),
              TextField(
                  controller: _cityController,
                  decoration:
                      const InputDecoration(labelText: 'Destination City')),
              const SizedBox(height: 12),
              TextField(
                  controller: _countryController,
                  decoration:
                      const InputDecoration(labelText: 'Country (optional)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _DateSelector(
                          label: 'Start Date',
                          date: _startDate,
                          onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _DateSelector(
                          label: 'End Date',
                          date: _endDate,
                          onTap: () => _pickDate(false))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
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
          if (_endDate.isBefore(_startDate))
            _endDate = _startDate.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_cityController.text.trim().isEmpty) return;
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
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _AddOrEditItinerarySheet extends StatefulWidget {
  final TripModel trip;
  final DateTime date;
  final List<PlaceModel> associatedPlaces;
  final ItineraryItem? existing;
  const _AddOrEditItinerarySheet(
      {required this.trip,
      required this.date,
      required this.associatedPlaces,
      this.existing});

  @override
  State<_AddOrEditItinerarySheet> createState() =>
      _AddOrEditItinerarySheetState();
}

class _AddOrEditItinerarySheetState extends State<_AddOrEditItinerarySheet> {
  String _mode = 'place'; // 'place' or 'custom'
  PlaceModel? _selectedPlace;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  String? _startTime; // HH:mm
  int? _duration;

  @override
  void initState() {
    super.initState();
    _mode = widget.existing?.placeId == null ? 'custom' : 'place';
    if (widget.existing == null) {
      _selectedPlace = widget.associatedPlaces.isNotEmpty
          ? widget.associatedPlaces.first
          : null;
    } else {
      try {
        _selectedPlace = widget.associatedPlaces
            .firstWhere((p) => p.id == widget.existing!.placeId);
      } catch (_) {
        _selectedPlace = widget.associatedPlaces.isNotEmpty
            ? widget.associatedPlaces.first
            : null;
      }
    }
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _notesController =
        TextEditingController(text: widget.existing?.notes ?? '');
    _startTime = widget.existing?.startTime;
    _duration = widget.existing?.durationMinutes ?? 60;
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(
                  widget.existing == null
                      ? 'Add Itinerary Item'
                      : 'Edit Itinerary Item',
                  style: textStyles.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  ChoiceChip(
                    selected: _mode == 'place',
                    label: const Text('From places'),
                    onSelected: (_) => setState(() => _mode = 'place'),
                    selectedColor: colors.primary.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    selected: _mode == 'custom',
                    label: const Text('Custom'),
                    onSelected: (_) => setState(() => _mode = 'custom'),
                    selectedColor: colors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_mode == 'place')
                _buildPlacePicker(textStyles, colors)
              else
                _buildCustomFields(textStyles, colors),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(_startTime ?? 'Start time'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDuration,
                      icon: const Icon(Icons.timelapse),
                      label: Text('${_duration ?? 60} min'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(widget.existing == null ? 'Add' : 'Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacePicker(TextTheme textStyles, ColorScheme colors) {
    if (widget.associatedPlaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text('No places in this trip yet. Add from Bucket List tab.',
            style: textStyles.bodyMedium),
      );
    }
    return DropdownButtonFormField<PlaceModel>(
      value: _selectedPlace,
      items: widget.associatedPlaces
          .map((p) => DropdownMenuItem(
              value: p,
              child: Text('${p.typeEmoji}  ${p.name}',
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (p) => setState(() => _selectedPlace = p),
      decoration: const InputDecoration(labelText: 'Select place'),
    );
  }

  Widget _buildCustomFields(TextTheme textStyles, ColorScheme colors) {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
          labelText: 'Title', hintText: 'e.g., Morning Run, Hotel Check-in'),
    );
  }

  Future<void> _pickTime() async {
    final initial = _startTime ?? '09:00';
    final parts = initial.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0),
    );
    if (t != null) setState(() => _startTime = _fmt(t));
  }

  Future<void> _pickDuration() async {
    final options = [30, 45, 60, 90, 120];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: options
                  .map((m) => ListTile(
                        title: Text('$m minutes'),
                        onTap: () => Navigator.pop(context, m),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _duration = picked);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
          .toString();

  Future<void> _save() async {
    final svc = context.read<TripService>();
    final date = DateTime(widget.date.year, widget.date.month, widget.date.day);
    if (_mode == 'place') {
      if (_selectedPlace == null) return;
      final item = (widget.existing ??
              ItineraryItem(
                id: const Uuid().v4(),
                date: date,
                title: _selectedPlace!.name,
                placeId: _selectedPlace!.id,
              ))
          .copyWith(
        date: date,
        title: _selectedPlace!.name,
        placeId: _selectedPlace!.id,
        startTime: _startTime,
        durationMinutes: _duration,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (widget.existing == null) {
        await svc.addItineraryItem(widget.trip.id, item);
      } else {
        await svc.updateItineraryItem(widget.trip.id, item);
      }
    } else {
      if (_titleController.text.trim().isEmpty && widget.existing == null)
        return;
      final item = (widget.existing ??
              ItineraryItem(
                id: const Uuid().v4(),
                date: date,
                title: _titleController.text.trim(),
              ))
          .copyWith(
        date: date,
        title: _titleController.text.trim().isEmpty
            ? (widget.existing?.title ?? 'Untitled')
            : _titleController.text.trim(),
        startTime: _startTime,
        durationMinutes: _duration,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        placeId: null,
      );
      if (widget.existing == null) {
        await svc.addItineraryItem(widget.trip.id, item);
      } else {
        await svc.updateItineraryItem(widget.trip.id, item);
      }
    }
    if (mounted) Navigator.pop(context);
  }
}
