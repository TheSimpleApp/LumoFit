import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    await HapticUtils.success();
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
                              .animate()
                              .fadeIn()
                              .slideX(begin: -0.1),
                          FilledButton.icon(
                            onPressed: () => _showCreateTripSheet(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New Trip'),
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10)),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .scale(delay: 200.ms),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plan and track your fitness travels',
                        style: textStyles.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
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
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              // Note: "Current trips" section removed - trips are now automatically active based on dates.
              // The activeTrip getter returns the trip where today falls within start/end dates.
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
                        )
                            .animate()
                            .fadeIn(delay: ((index + 1) * 100).ms)
                            .slideY(begin: 0.1, delay: ((index + 1) * 100).ms),
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
                        )
                            .animate()
                            .fadeIn(delay: ((index + 1) * 100).ms)
                            .slideY(begin: 0.1, delay: ((index + 1) * 100).ms),
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
    final hasImage = trip.imageUrl != null && trip.imageUrl!.isNotEmpty;

    return Hero(
      tag: 'trip_image_${trip.id}',
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or gradient
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: trip.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldShimmer,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldShimmer,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.goldShimmer,
                      ),
                    ),
                  // Cinematic overlay - darker, more sophisticated
                  if (hasImage) ...[
                    // Base darkening
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    // Vignette effect
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    // Subtle warm tint
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4AF37).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row - status badge and arrow
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: hasImage
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasImage
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4ADE80)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Now',
                                    style: textStyles.labelSmall?.copyWith(
                                      color: hasImage
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasImage
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: hasImage
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.6),
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Destination info
                        Text(
                          trip.destinationCity,
                          style: textStyles.headlineSmall?.copyWith(
                            color: hasImage ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        if (trip.destinationCountry != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            trip.destinationCountry!,
                            style: textStyles.bodyMedium?.copyWith(
                              color: hasImage
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.black.withValues(alpha: 0.7),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        // Stats row - cleaner design
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: hasImage
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasImage
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _StatItem(
                                value: '${trip.durationDays}',
                                label: 'days',
                                lightText: hasImage,
                              ),
                              _StatDivider(lightText: hasImage),
                              _StatItem(
                                value: '${trip.savedPlaceIds.length}',
                                label: 'places',
                                lightText: hasImage,
                              ),
                              _StatDivider(lightText: hasImage),
                              _StatItem(
                                value: dateFormat.format(trip.endDate),
                                label: 'ends',
                                lightText: hasImage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool lightText;

  const _StatItem({
    required this.value,
    required this.label,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: textStyles.titleMedium?.copyWith(
              color: lightText ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textStyles.labelSmall?.copyWith(
              color: lightText
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool lightText;

  const _StatDivider({this.lightText = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            lightText
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
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
      case 'Active':
        return AppColors.success;
      case 'Current':
        return AppColors.primary;
      case 'Upcoming':
        return AppColors.info;
      case 'Past':
        return AppColors.muted;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d');
    final hasImage = trip.imageUrl != null && trip.imageUrl!.isNotEmpty;

    return Hero(
      tag: 'trip_image_${trip.id}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colors.surface,
            ),
            child: Stack(
              children: [
                // Full-width subtle background image
                if (hasImage)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: trip.imageUrl!,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: isPast ? 0.7 : 0.5),
                        colorBlendMode: BlendMode.darken,
                        placeholder: (_, __) => Container(
                          color: colors.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colors.surface,
                        ),
                      ),
                    ),
                  ),
                // Gradient overlay for depth
                if (hasImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.15)
                              : (isPast ? colors.outline : AppColors.info)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: hasImage
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isPast ? '📍' : '✈️',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.destinationCity,
                              style: textStyles.titleMedium?.copyWith(
                                color: hasImage
                                    ? Colors.white
                                    : (isPast
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface),
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}, ${trip.endDate.year}',
                              style: textStyles.bodySmall?.copyWith(
                                color: hasImage
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? _getStatusColor(trip.status)
                                  .withValues(alpha: 0.25)
                              : _getStatusColor(trip.status)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: hasImage
                              ? Border.all(
                                  color: _getStatusColor(trip.status)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Text(
                          trip.status,
                          style: textStyles.labelSmall?.copyWith(
                            color: hasImage
                                ? Colors.white
                                : _getStatusColor(trip.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  // Form controllers
  late TextEditingController _cityController;
  late TextEditingController _notesController;

  // City autocomplete state
  late FocusNode _cityFocusNode;
  List<CitySuggestion> _citySuggestions = [];
  Timer? _debounceTimer;
  bool _isLoadingSuggestions = false;
  String? _selectedCity;
  String? _selectedCountry;

  // Validation state
  String? _cityError;

  // Submission state
  bool _isSubmitting = false;

  // Date state variables - nullable for range picker
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _notesController = TextEditingController();
    _cityFocusNode = FocusNode();

    // Start with no dates selected (user will pick)
    _startDate = null;
    _endDate = null;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _notesController.dispose();
    _cityFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Returns true if the city field has a valid selection
  bool get _isCityValid => _selectedCity != null && _selectedCity!.isNotEmpty;

  /// Returns true if dates have been selected
  bool get _areDatesSelected => _startDate != null && _endDate != null;

  /// Returns true if the form can be submitted (all required fields valid)
  bool get _canSubmit => _isCityValid && _areDatesSelected;

  /// Returns true if dates are logically valid (end >= start)
  bool get _areDatesValid =>
      _startDate != null &&
      _endDate != null &&
      !_endDate!.isBefore(_startDate!);

  /// Validates the form and shows errors if invalid
  /// Returns true if the form is valid and ready to submit
  bool _validateForm() {
    setState(() {
      _cityError = null;
    });

    bool isValid = true;

    // Validate city
    if (!_isCityValid) {
      setState(() {
        _cityError = 'Please select a destination city';
      });
      isValid = false;
    }

    // Validate dates are selected
    if (!_areDatesSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your trip dates'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      isValid = false;
    } else if (!_areDatesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End date must be on or after start date'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  void _onCityChanged(String value) {
    // Clear selected city and validation error when user types
    if (_selectedCity != null || _cityError != null) {
      setState(() {
        _selectedCity = null;
        _selectedCountry = null;
        _cityError = null;
      });
    }

    // Debounce API calls
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _citySuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final placesService = GooglePlacesService();
      final suggestions = await placesService.autocompleteCities(value);
      if (mounted) {
        setState(() {
          _citySuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _onSuggestionSelected(CitySuggestion suggestion) {
    HapticUtils.light();
    _cityController.text = suggestion.city;
    setState(() {
      _selectedCity = suggestion.city;
      _selectedCountry = suggestion.country;
      _citySuggestions = [];
    });
    // Dismiss keyboard
    _cityFocusNode.unfocus();
  }

  /// Handles date selection in the inline range picker
  /// Airline-style: tap once for start, tap again for end (or same day)
  void _onDateTapped(DateTime date) {
    HapticUtils.light();
    setState(() {
      if (_startDate == null) {
        // First tap: set start date
        _startDate = date;
        _endDate = null;
      } else if (_endDate == null) {
        // Second tap: set end date
        if (date.isBefore(_startDate!)) {
          // If tapped date is before start, make it the new start
          _endDate = _startDate;
          _startDate = date;
        } else {
          // Normal case: set as end date (same day is valid for day trips)
          _endDate = date;
        }
      } else {
        // Both dates set: start over with new start date
        _startDate = date;
        _endDate = null;
      }
    });
  }

  /// Clears the date selection
  void _clearDates() {
    HapticUtils.light();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  /// Gets unique recent destinations from previous trips
  List<_RecentDestination> _getRecentDestinations(TripService tripService) {
    final seen = <String>{};
    final destinations = <_RecentDestination>[];

    // Get all trips sorted by most recent first
    final allTrips = [...tripService.trips]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    for (final trip in allTrips) {
      final key = trip.destinationCity.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        destinations.add(_RecentDestination(
          city: trip.destinationCity,
          country: trip.destinationCountry,
          // Check if it's a US state
          state: trip.destinationCountry == 'USA' ? null : null,
        ));
      }
      // Limit to 5 recent destinations
      if (destinations.length >= 5) break;
    }

    return destinations;
  }

  /// Selects a recent destination
  void _selectRecentDestination(_RecentDestination dest) {
    HapticUtils.light();
    _cityController.text = dest.city;
    setState(() {
      _selectedCity = dest.city;
      _selectedCountry = dest.country;
      _citySuggestions = [];
      _cityError = null;
    });
    _cityFocusNode.unfocus();
  }

  Future<void> _createTrip() async {
    // Validate form first
    if (!_validateForm()) {
      HapticUtils.error();
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tripService = context.read<TripService>();

      // Create trip with all form data (dates validated as non-null in _validateForm)
      final newTrip = await tripService.createTrip(
        destinationCity: _selectedCity!,
        destinationCountry: _selectedCountry,
        startDate: _startDate!,
        endDate: _endDate!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Success haptic feedback
      HapticUtils.success();

      if (mounted) {
        // Dismiss the bottom sheet
        Navigator.of(context).pop();

        // Show success confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip to ${newTrip.destinationCity} created!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to the new trip detail screen
        context.push('/trip/${newTrip.id}');
      }
    } catch (e) {
      // Error haptic feedback
      HapticUtils.error();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create trip: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.85;

    return Container(
      // Constrain max height to 85% of screen to prevent overflow
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('New Trip', style: textStyles.titleLarge),
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
            Flexible(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    mediaQuery.viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Previous destinations quick select
                      Builder(
                        builder: (context) {
                          final tripService = context.watch<TripService>();
                          final recentDestinations =
                              _getRecentDestinations(tripService);
                          if (recentDestinations.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Destinations',
                                style: textStyles.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: recentDestinations
                                    .map((_RecentDestination dest) {
                                  final isSelected = _selectedCity == dest.city;
                                  return FilterChip(
                                    selected: isSelected,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('✈️ '),
                                        Text(dest.city),
                                        if (dest.state != null)
                                          Text(
                                            ', ${dest.state}',
                                            style:
                                                textStyles.bodySmall?.copyWith(
                                              color: isSelected
                                                  ? colors.onPrimaryContainer
                                                  : colors.onSurfaceVariant,
                                            ),
                                          )
                                        else if (dest.country != null &&
                                            dest.country != 'USA')
                                          Text(
                                            ', ${dest.country}',
                                            style:
                                                textStyles.bodySmall?.copyWith(
                                              color: isSelected
                                                  ? colors.onPrimaryContainer
                                                  : colors.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onSelected: (_) =>
                                        _selectRecentDestination(dest),
                                    selectedColor: colors.primaryContainer,
                                    checkmarkColor: colors.primary,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      // City input field
                      TextField(
                        controller: _cityController,
                        focusNode: _cityFocusNode,
                        onChanged: _onCityChanged,
                        decoration: InputDecoration(
                          labelText: 'Where are you going?',
                          hintText: 'Enter a city',
                          errorText: _cityError,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: _isLoadingSuggestions
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _cityController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        HapticUtils.light();
                                        _cityController.clear();
                                        setState(() {
                                          _citySuggestions = [];
                                          _selectedCity = null;
                                          _selectedCountry = null;
                                          _cityError = null;
                                        });
                                      },
                                    )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      // Autocomplete suggestions dropdown
                      if (_citySuggestions.isNotEmpty && _selectedCity == null)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _citySuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _citySuggestions[index];
                                return InkWell(
                                  onTap: () => _onSuggestionSelected(suggestion),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 20,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                suggestion.city,
                                                style: textStyles.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              // Show state for US, country for others
                                              if (suggestion.subtitle != null)
                                                Text(
                                                  suggestion.subtitle!,
                                                  style: textStyles.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Inline Date Range Picker (airline-style)
                      _InlineDateRangePicker(
                        startDate: _startDate,
                        endDate: _endDate,
                        onDateTapped: _onDateTapped,
                        onClear: _clearDates,
                      ),
                      const SizedBox(height: 20),
                      // Notes field
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'Add any travel notes, reminders, or plans...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.notes_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Create Trip button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (!_canSubmit || _isSubmitting)
                              ? null
                              : _createTrip,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Create Trip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Airline-style inline date range picker
/// Tap once for start date, tap again for end date (or same day for single-day trips)
class _InlineDateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onDateTapped;
  final VoidCallback onClear;

  const _InlineDateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onDateTapped,
    required this.onClear,
  });

  @override
  State<_InlineDateRangePicker> createState() => _InlineDateRangePickerState();
}

class _InlineDateRangePickerState extends State<_InlineDateRangePicker> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    // Start with current month or the month of start date
    _displayedMonth = widget.startDate ?? DateTime.now();
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime date) {
    if (widget.startDate == null || widget.endDate == null) return false;
    return date.isAfter(widget.startDate!) && date.isBefore(widget.endDate!);
  }

  bool _isStartDate(DateTime date) =>
      widget.startDate != null && _isSameDay(date, widget.startDate!);

  bool _isEndDate(DateTime date) =>
      widget.endDate != null && _isSameDay(date, widget.endDate!);

  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with instructions
        Row(
          children: [
            Icon(Icons.date_range, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Select Dates',
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.startDate != null)
              TextButton.icon(
                onPressed: widget.onClear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Instructions based on state
        Text(
          _getInstructionText(),
          style: textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // Selected range display
        if (widget.startDate != null) ...[
          _buildSelectedRangeDisplay(colors, textStyles),
          const SizedBox(height: 12),
        ],
        // Calendar container
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Month navigation header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_displayedMonth),
                      style: textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              // Day of week headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((d) => SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(
                                d,
                                style: textStyles.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              // Calendar grid
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: _buildCalendarGrid(colors, textStyles, today),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (widget.startDate == null) {
      return 'Tap a date to set your departure';
    } else if (widget.endDate == null) {
      return 'Tap another date for return, or same date for a day trip';
    } else {
      return 'Tap any date to start over';
    }
  }

  Widget _buildSelectedRangeDisplay(ColorScheme colors, TextTheme textStyles) {
    final dateFormat = DateFormat('EEE, MMM d');
    final isSameDay = widget.endDate != null &&
        _isSameDay(widget.startDate!, widget.endDate!);
    final tripDays = widget.endDate != null
        ? widget.endDate!.difference(widget.startDate!).inDays + 1
        : 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withValues(alpha: 0.5),
            colors.primaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Start date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPART',
                  style: textStyles.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(widget.startDate!),
                  style: textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Arrow or day indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: widget.endDate == null
                ? Icon(Icons.arrow_forward, size: 16, color: colors.primary)
                : Text(
                    isSameDay ? '1 day' : '$tripDays days',
                    style: textStyles.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          // End date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RETURN',
                  style: textStyles.labelSmall?.copyWith(
                    color: widget.endDate != null
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.endDate != null
                      ? dateFormat.format(widget.endDate!)
                      : 'Select date',
                  style: textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.endDate != null
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
      ColorScheme colors, TextTheme textStyles, DateTime today) {
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final days = <Widget>[];

    // Add empty cells for days before the first of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox(width: 36, height: 36));
    }

    // Add day cells
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isPast = date.isBefore(today);
      final isStart = _isStartDate(date);
      final isEnd = _isEndDate(date);
      final isInRange = _isInRange(date);
      final isTodayDate = _isToday(date);

      days.add(
        GestureDetector(
          onTap: isPast ? null : () => widget.onDateTapped(date),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStart || isEnd
                  ? colors.primary
                  : isInRange
                      ? colors.primary.withValues(alpha: 0.15)
                      : null,
              borderRadius: BorderRadius.horizontal(
                left: isStart || (!isInRange && !isEnd)
                    ? const Radius.circular(18)
                    : Radius.zero,
                right: isEnd || (!isInRange && !isStart)
                    ? const Radius.circular(18)
                    : Radius.zero,
              ),
              border: isTodayDate && !isStart && !isEnd
                  ? Border.all(color: colors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: textStyles.bodyMedium?.copyWith(
                  color: isPast
                      ? colors.onSurface.withValues(alpha: 0.3)
                      : isStart || isEnd
                          ? colors.onPrimary
                          : colors.onSurface,
                  fontWeight:
                      isStart || isEnd || isTodayDate ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      children: days,
    );
  }
}

/// Simple model for recent destination quick select
class _RecentDestination {
  final String city;
  final String? state;
  final String? country;

  const _RecentDestination({
    required this.city,
    this.state,
    this.country,
  });
}
