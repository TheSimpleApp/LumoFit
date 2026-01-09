import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/trip_service.dart';
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

class _CreateTripSheet extends StatelessWidget {
  const _CreateTripSheet();

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}