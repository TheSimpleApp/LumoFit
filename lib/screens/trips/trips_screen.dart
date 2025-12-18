import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:fittravel/models/trip_model.dart';
import 'package:fittravel/utils/haptic_utils.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final trips = tripService.trips;
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Trips', style: textStyles.headlineMedium)
                            .animate().fadeIn().slideX(begin: -0.1),
                        FilledButton.icon(
                          onPressed: () => _showCreateTripSheet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Trip'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                        ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan and track your fitness travels',
                      style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (tripService.activeTrip != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Trip', style: textStyles.titleMedium),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticUtils.light();
                          context.push('/trip/${tripService.activeTrip!.id}');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: _ActiveTripCard(trip: tripService.activeTrip!),
                      )
                          .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
            // Current trips that are not active
            if (tripService.currentTrips.where((t) => !t.isActive).isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Current Trips', style: textStyles.titleMedium),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final currentNonActive = tripService.currentTrips.where((t) => !t.isActive).toList();
                    final trip = currentNonActive[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _TripCard(
                        trip: trip,
                        onTap: () => context.push('/trip/${trip.id}'),
                      ).animate().fadeIn(delay: ((index + 1) * 100).ms).slideY(begin: 0.1, delay: ((index + 1) * 100).ms),
                    );
                  },
                  childCount: tripService.currentTrips.where((t) => !t.isActive).length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
            if (tripService.upcomingTrips.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Upcoming', style: textStyles.titleMedium),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = tripService.upcomingTrips[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _TripCard(
                          trip: trip,
                          onTap: () => context.push('/trip/${trip.id}'),
                        ).animate().fadeIn(delay: ((index + 1) * 100).ms).slideY(begin: 0.1, delay: ((index + 1) * 100).ms),
                      );
                  },
                  childCount: tripService.upcomingTrips.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
            if (tripService.pastTrips.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Past Trips', style: textStyles.titleMedium),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = tripService.pastTrips[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _TripCard(
                          trip: trip,
                          isPast: true,
                          onTap: () => context.push('/trip/${trip.id}'),
                        ).animate().fadeIn(delay: ((index + 1) * 100).ms).slideY(begin: 0.1, delay: ((index + 1) * 100).ms),
                      );
                  },
                  childCount: tripService.pastTrips.length,
                ),
              ),
            ],
            if (trips.isEmpty)
              SliverFillRemaining(child: _EmptyState(onCreateTrip: () => _showCreateTripSheet(context))),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _showCreateTripSheet(BuildContext context) {
    HapticUtils.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateTripSheet(),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final TripModel trip;

  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldShimmer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Active Now', style: textStyles.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('✈️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destinationCity, style: textStyles.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                    if (trip.destinationCountry != null)
                      Text(trip.destinationCountry!, style: textStyles.bodyMedium?.copyWith(color: Colors.black.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: _StatColumn(value: '${trip.durationDays}', label: 'Days')),
                Container(width: 1, height: 40, color: Colors.black.withValues(alpha: 0.3)),
                Expanded(child: _StatColumn(value: '${trip.savedPlaceIds.length}', label: 'Places')),
                Container(width: 1, height: 40, color: Colors.black.withValues(alpha: 0.3)),
                Expanded(child: _StatColumn(value: dateFormat.format(trip.endDate), label: 'Ends')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textStyles.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        Text(label, style: textStyles.labelSmall?.copyWith(color: Colors.black.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final bool isPast;
  final VoidCallback? onTap;

  const _TripCard({required this.trip, this.isPast = false, this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return AppColors.success;
      case 'Current': return AppColors.primary;
      case 'Upcoming': return AppColors.info;
      case 'Past': return AppColors.muted;
      default: return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isPast ? colors.outline : AppColors.info).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(child: Text(isPast ? '📍' : '✈️', style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destinationCity, style: textStyles.titleSmall?.copyWith(color: isPast ? colors.onSurfaceVariant : null)),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                      style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(trip.status, style: textStyles.labelSmall?.copyWith(color: _getStatusColor(trip.status), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTrip;

  const _EmptyState({required this.onCreateTrip});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text('No trips yet', style: textStyles.titleLarge),
            const SizedBox(height: 8),
            Text('Create your first trip and start planning\nyour fitness adventure', style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onCreateTrip, icon: const Icon(Icons.add), label: const Text('Create Trip')),
          ],
        ),
      ),
    );
  }
}

class _CreateTripSheet extends StatefulWidget {
  const _CreateTripSheet();

  @override
  State<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<_CreateTripSheet> {
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final _places = GooglePlacesService();
  List<CitySuggestion> _suggestions = [];
  bool _loading = false;
  DateTime? _lastQueryAt;

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
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
              const SizedBox(height: 20),
              Text('Plan New Trip', style: textStyles.titleLarge),
              const SizedBox(height: 20),
              // Destination City with Autocomplete
              TextField(
                controller: _cityController,
                onChanged: _onCityChanged,
                decoration: InputDecoration(
                  labelText: 'Destination City',
                  hintText: 'e.g., Salt Lake City',
                  prefixIcon: Icon(Icons.location_city, color: colors.primary),
                  suffixIcon: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
                        )
                      : (_cityController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                              onPressed: () {
                                setState(() {
                                  _cityController.clear();
                                  _suggestions = [];
                                });
                              },
                            )
                          : null),
                ),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: colors.outline.withValues(alpha: 0.08)),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        leading: Icon(Icons.location_on, color: colors.primary),
                        title: Text(s.city, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: s.country == null ? null : Text(s.country!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                        onTap: () {
                          setState(() {
                            _cityController.text = s.city;
                            if ((s.country ?? '').isNotEmpty) {
                              _countryController.text = s.country!;
                            }
                            _suggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country (optional)', hintText: 'e.g., USA')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _DateSelector(label: 'Start Date', date: _startDate, onTap: () => _selectDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateSelector(label: 'End Date', date: _endDate, onTap: () => _selectDate(false))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _createTrip, child: const Text('Create Trip'))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    await HapticUtils.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      await HapticUtils.selection();
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createTrip() async {
    if (_cityController.text.isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a destination city'), behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final city = _cityController.text;
      await context.read<TripService>().createTrip(
            destinationCity: city,
            destinationCountry: _countryController.text.isEmpty ? null : _countryController.text,
            startDate: _startDate,
            endDate: _endDate,
          );
      if (!mounted) return;
      HapticUtils.success();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip created • $city! ✈️'), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.primary),
      );
    } catch (e) {
      if (!mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create trip: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _onCityChanged(String value) async {
    // Debounce: skip very short inputs and avoid flooding API
    setState(() {
      _loading = value.trim().length >= 2;
    });
    _lastQueryAt = DateTime.now();
    final myStamp = _lastQueryAt!;

    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }

    final results = await _places.autocompleteCities(value.trim());
    if (!mounted) return;
    // Ensure we only apply the latest query results
    if (_lastQueryAt == myStamp) {
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    }
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
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Text(dateFormat.format(date), style: textStyles.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
