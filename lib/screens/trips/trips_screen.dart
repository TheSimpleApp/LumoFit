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
import 'package:fittravel/widgets/empty_state_widget.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Future<void> _onRefresh() async {
    final tripService = context.read<TripService>();
    await tripService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final tripService = context.watch<TripService>();
    final trips = tripService.trips;
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
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
                        _ActiveTripCard(
                          trip: tripService.activeTrip!,
                          onTap: () {
                            HapticUtils.light();
                            context.push('/trip/${tripService.activeTrip!.id}');
                          },
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
                SliverFillRemaining(
                  child: EmptyStateWidget.trips(
                    ctaLabel: 'Plan Your First Trip',
                    onCtaPressed: () => _showCreateTripSheet(context),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
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
  final VoidCallback? onTap;

  const _ActiveTripCard({required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d');

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
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
        ),
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

class _CreateTripSheet extends StatefulWidget {
  const _CreateTripSheet();

  @override
  State<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<_CreateTripSheet> {
  final _destinationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  GooglePlace? _selectedPlace;
  bool _isLoading = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Plan Your Trip', style: textStyles.headlineSmall),
                const SizedBox(height: 24),
                _DestinationSearchField(
                  controller: _destinationController,
                  onPlaceSelected: (place) => setState(() => _selectedPlace = place),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Start Date',
                        controller: _startDateController,
                        onDateSelected: (date) => setState(() => _startDate = date),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'End Date',
                        controller: _endDateController,
                        onDateSelected: (date) => setState(() => _endDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading || _selectedPlace == null || _startDate == null || _endDate == null
                        ? null
                        : _createTrip,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create Trip'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTrip() async {
    if (_selectedPlace == null || _startDate == null || _endDate == null) return;

    setState(() => _isLoading = true);

    try {
      final tripService = context.read<TripService>();
      await tripService.addTrip(
        destination: _selectedPlace!.description ?? _selectedPlace!.mainText ?? '',
        startDate: _startDate!,
        endDate: _endDate!,
        place: _selectedPlace!,
      );

      if (mounted) {
        Navigator.pop(context);
        HapticUtils.success();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating trip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DestinationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(GooglePlace) onPlaceSelected;

  const _DestinationSearchField({
    required this.controller,
    required this.onPlaceSelected,
  });

  @override
  State<_DestinationSearchField> createState() => _DestinationSearchFieldState();
}

class _DestinationSearchFieldState extends State<_DestinationSearchField> {
  List<GooglePlace> _predictions = [];
  bool _isSearching = false;
  final _debounce = Debounce();

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: 'Search destination',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() => _predictions = []);
              return;
            }

            _isSearching = true;
            _debounce.run(() async {
              try {
                final googlePlacesService = context.read<GooglePlacesService>();
                final predictions = await googlePlacesService.searchPlaces(value);
                if (mounted) {
                  setState(() {
                    _predictions = predictions;
                    _isSearching = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isSearching = false);
                }
              }
            });
          },
        ),
        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  title: Text(prediction.mainText ?? ''),
                  subtitle: Text(prediction.secondaryText ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    widget.controller.text = prediction.description ?? prediction.mainText ?? '';
                    widget.onPlaceSelected(prediction);
                    setState(() => _predictions = []);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(DateTime) onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.controller,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly:true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          controller.text = DateFormat('MMM d, yyyy').format(date);
          onDateSelected(date);
        }
      },
    );
  }
}

class Debounce {
  Timer? _timer;

  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), callback);
  }

  void cancel() => _timer?.cancel();
}