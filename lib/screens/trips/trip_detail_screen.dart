import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _TripDetailScreenState extends State<TripDetailScreen> {
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

    final dateRange = '${DateFormat('MMM d, yyyy').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}';
    final associatedPlaces = trip.savedPlaceIds
        .map((id) => placeService.getPlaceById(id))
        .whereType<PlaceModel>()
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
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
                    const PopupMenuItem(value: 'activate', child: Text('Set Active Trip')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Trip')),
                ],
                onSelected: (value) async {
                  if (value == 'activate') {
                    await context.read<TripService>().setActiveTrip(trip.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Active trip set'), behavior: SnackBarBehavior.floating),
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
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
                  children: [
                    Row(
                      children: [
                        const Text('✈️', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.destinationCity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        // Let the status pill shrink on tight layouts to avoid overflow
                        Flexible(child: Align(alignment: Alignment.centerRight, child: _StatusPill(status: trip.status))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Use Wrap to avoid horizontal overflow on narrow screens
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _QuickStat(value: '${trip.durationDays}', label: 'Days'),
                        _DividerDot(color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
                        _QuickStat(value: '${associatedPlaces.length}', label: 'Places'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Places', style: textStyles.titleMedium),
                  TextButton.icon(
                    onPressed: () => _showAddPlacesSheet(context, trip),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          if (associatedPlaces.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyPlacesCard(onAdd: () => _showAddPlacesSheet(context, trip)),
              ),
            )
          else
            SliverList.builder(
              itemCount: associatedPlaces.length,
              itemBuilder: (context, index) {
                final p = associatedPlaces[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 12, 20, 0),
                  child: _PlaceRow(
                    place: p,
                    onOpen: () => context.push('/place-detail', extra: p),
                    onRemove: () => context.read<TripService>().removePlaceFromTrip(trip.id, p.id),
                  ).animate().fadeIn(delay: ((index + 1) * 60).ms).slideY(begin: 0.08),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Trip Activity Timeline (read-only)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip Activity', style: textStyles.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Visited places during this trip, grouped by day',
                    style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TimelineList(
                trip: trip,
                allPlaces: context.watch<PlaceService>().savedPlaces,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Itinerary', style: textStyles.titleMedium),
                  const SizedBox(height: 6),
                  Text('Plan your day-by-day schedule', style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ItineraryEditor(trip: trip, associatedPlaces: associatedPlaces),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    if (mounted) setState(() {});
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
      child: Text(status, style: textStyles.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600)),
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
          Text(value, style: textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(label, style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  final Color color;
  const _DividerDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  const _PlaceRow({required this.place, required this.onOpen, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(child: Text(place.typeEmoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: textStyles.titleSmall),
                    if (place.address != null)
                      Text(place.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from trip',
                onPressed: onRemove,
                icon: Icon(Icons.remove_circle_outline, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlacesCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPlacesCard({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No places yet', style: textStyles.titleSmall),
          const SizedBox(height: 6),
          Text('Add gyms and healthy eats you want to visit on this trip.', style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add places')),
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
        .where((p) => !p.visitedAt!.isBefore(trip.startDate) && !p.visitedAt!.isAfter(trip.endDate))
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
            Expanded(child: Text('No activity on this trip yet. Log visits from place details.', style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant))),
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
                          Expanded(child: Text('${p.typeLabel}: ${p.name}', style: textStyles.bodyMedium)),
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
    final tripService = context.watch<TripService>();

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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text('Add places to trip', style: textStyles.titleLarge),
              const SizedBox(height: 12),
              if (places.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You have no saved places yet.', style: textStyles.bodyMedium),
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
                          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: already
                                ? null
                                : () async {
                                    await context.read<TripService>().addPlaceToTrip(trip.id, p.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added ${p.name}'), behavior: SnackBarBehavior.floating),
                                    );
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p.name, style: textStyles.bodyMedium)),
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
    _countryController = TextEditingController(text: widget.trip.destinationCountry ?? '');
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
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Edit Trip', style: textStyles.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Destination City')),
              const SizedBox(height: 12),
              TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country (optional)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _DateSelector(label: 'Start Date', date: _startDate, onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateSelector(label: 'End Date', date: _endDate, onTap: () => _pickDate(false))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)')
              ),
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
          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(days: 1));
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
      destinationCountry: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    await svc.updateTrip(updated);
    if (mounted) Navigator.pop(context);
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateSelector({required this.label, required this.date, required this.onTap});

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
            Text(DateFormat('MMM d, yyyy').format(date), style: textStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ----------------- Itinerary Editor -----------------

class _ItineraryEditor extends StatefulWidget {
  final TripModel trip;
  final List<PlaceModel> associatedPlaces;
  const _ItineraryEditor({required this.trip, required this.associatedPlaces});

  @override
  State<_ItineraryEditor> createState() => _ItineraryEditorState();
}

class _ItineraryEditorState extends State<_ItineraryEditor> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.trip.startDate.year, widget.trip.startDate.month, widget.trip.startDate.day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final svc = context.watch<TripService>();
    final items = svc.getItinerary(widget.trip.id, forDate: _selectedDate);

    final days = List<DateTime>.generate(
      widget.trip.durationDays,
      (i) => DateTime(widget.trip.startDate.year, widget.trip.startDate.month, widget.trip.startDate.day).add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day chips
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final d = days[index];
              final isSel = _isSameDay(d, _selectedDate);
              return ChoiceChip(
                selected: isSel,
                label: Text(DateFormat('MMM d').format(d)),
                onSelected: (_) => setState(() => _selectedDate = d),
                selectedColor: colors.primary.withValues(alpha: 0.15),
                labelStyle: textStyles.labelLarge?.copyWith(
                  color: isSel ? colors.primary : colors.onSurface,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Actions row
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => _showAddItemSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
            const Spacer(),
            Text(DateFormat('EEEE').format(_selectedDate), style: textStyles.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        // Reorderable list inside a sized box
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
          ),
          child: SizedBox(
            height: items.isEmpty ? 76 : (items.length * 70).clamp(180, 480).toDouble(),
            child: items.isEmpty
                ? Center(
                    child: Text('No items yet. Add a place or a custom block.',
                        style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    proxyDecorator: (child, index, animation) => Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: child,
                    ),
                    onReorder: (oldIndex, newIndex) {
                      final list = List<ItineraryItem>.from(items);
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                      context.read<TripService>().reorderItinerary(widget.trip.id, _mergeDay(list));
                    },
                    itemBuilder: (context, index) {
                      final it = items[index];
                      PlaceModel? match;
                      if (it.placeId != null) {
                        try {
                          match = widget.associatedPlaces.firstWhere((p) => p.id == it.placeId);
                        } catch (_) {
                          match = null;
                        }
                      }
                      return _ItineraryTile(
                        key: ValueKey(it.id),
                        item: it,
                        place: match,
                        onEdit: () => _showEditItemSheet(context, it),
                        onDelete: () => context.read<TripService>().removeItineraryItem(widget.trip.id, it.id),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<ItineraryItem> _mergeDay(List<ItineraryItem> dayItems) {
    // Replace only items for the selected day, keep the others
    final svc = context.read<TripService>();
    final all = svc.getItinerary(widget.trip.id);
    final others = all.where((e) => !_isSameDay(e.date, _selectedDate)).toList();
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

  Future<void> _showEditItemSheet(BuildContext context, ItineraryItem item) async {
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

class _ItineraryTile extends StatelessWidget {
  final ItineraryItem item;
  final PlaceModel? place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ItineraryTile({super.key, required this.item, required this.place, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    String timeLabel = item.startTime ?? '--:--';
    final emoji = place?.typeEmoji ?? '📝';
    final subtitle = item.notes;

    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
      title: Row(
        children: [
          Text(timeLabel, style: textStyles.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.titleSmall,
            ),
          ),
        ],
      ),
      subtitle: subtitle == null || subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onEdit, icon: Icon(Icons.edit, color: colors.onSurfaceVariant)),
          IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, color: colors.error)),
          const SizedBox(width: 4),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }
}

class _AddOrEditItinerarySheet extends StatefulWidget {
  final TripModel trip;
  final DateTime date;
  final List<PlaceModel> associatedPlaces;
  final ItineraryItem? existing;
  const _AddOrEditItinerarySheet({required this.trip, required this.date, required this.associatedPlaces, this.existing});

  @override
  State<_AddOrEditItinerarySheet> createState() => _AddOrEditItinerarySheetState();
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
      _selectedPlace = widget.associatedPlaces.isNotEmpty ? widget.associatedPlaces.first : null;
    } else {
      try {
        _selectedPlace = widget.associatedPlaces.firstWhere((p) => p.id == widget.existing!.placeId);
      } catch (_) {
        _selectedPlace = widget.associatedPlaces.isNotEmpty ? widget.associatedPlaces.first : null;
      }
    }
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
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
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(widget.existing == null ? 'Add Itinerary Item' : 'Edit Itinerary Item', style: textStyles.titleLarge),
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
              if (_mode == 'place') _buildPlacePicker(textStyles, colors) else _buildCustomFields(textStyles, colors),
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
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
        child: Text('No places in this trip yet. Add from Saved Places above.', style: textStyles.bodyMedium),
      );
    }
    return DropdownButtonFormField<PlaceModel>(
      value: _selectedPlace,
      items: widget.associatedPlaces
          .map((p) => DropdownMenuItem(value: p, child: Text('${p.typeEmoji}  ${p.name}', overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (p) => setState(() => _selectedPlace = p),
      decoration: const InputDecoration(labelText: 'Select place'),
    );
  }

  Widget _buildCustomFields(TextTheme textStyles, ColorScheme colors) {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Morning Run, Hotel Check-in'),
    );
  }

  Future<void> _pickTime() async {
    final initial = _startTime ?? '09:00';
    final parts = initial.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0),
    );
    if (t != null) setState(() => _startTime = _fmt(t));
  }

  Future<void> _pickDuration() async {
    // Simple chooser using a bottom sheet with common durations
    final options = [30, 45, 60, 90, 120];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
      .toString();

  Future<void> _save() async {
    final svc = context.read<TripService>();
    final date = DateTime(widget.date.year, widget.date.month, widget.date.day);
    if (_mode == 'place') {
      if (_selectedPlace == null) return;
      final item = (widget.existing ?? ItineraryItem(
        id: const Uuid().v4(),
        date: date,
        title: _selectedPlace!.name,
        placeId: _selectedPlace!.id,
      )).copyWith(
        date: date,
        title: _selectedPlace!.name,
        placeId: _selectedPlace!.id,
        startTime: _startTime,
        durationMinutes: _duration,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (widget.existing == null) {
        await svc.addItineraryItem(widget.trip.id, item);
      } else {
        await svc.updateItineraryItem(widget.trip.id, item);
      }
    } else {
      if (_titleController.text.trim().isEmpty && widget.existing == null) return;
      final item = (widget.existing ?? ItineraryItem(
        id: const Uuid().v4(),
        date: date,
        title: _titleController.text.trim(),
      )).copyWith(
        date: date,
        title: _titleController.text.trim().isEmpty ? (widget.existing?.title ?? 'Untitled') : _titleController.text.trim(),
        startTime: _startTime,
        durationMinutes: _duration,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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

