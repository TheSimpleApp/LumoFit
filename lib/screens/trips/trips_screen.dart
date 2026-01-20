import 'dart:async';
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
              // Current trips that are not active
              if (tripService.currentTrips
                  .where((t) => !t.isActive)
                  .isNotEmpty) ...[
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
                      final currentNonActive = tripService.currentTrips
                          .where((t) => !t.isActive)
                          .toList();
                      final trip = currentNonActive[index];
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
                    childCount: tripService.currentTrips
                        .where((t) => !t.isActive)
                        .length,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Active Now',
                            style: textStyles.labelSmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.black, size: 16),
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
                        Text(trip.destinationCity,
                            style: textStyles.titleLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        if (trip.destinationCountry != null)
                          Text(trip.destinationCountry!,
                              style: textStyles.bodyMedium?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.8))),
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
                    Expanded(
                        child: _StatColumn(
                            value: '${trip.durationDays}', label: 'Days')),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.black.withValues(alpha: 0.3)),
                    Expanded(
                        child: _StatColumn(
                            value: '${trip.savedPlaceIds.length}',
                            label: 'Places')),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.black.withValues(alpha: 0.3)),
                    Expanded(
                        child: _StatColumn(
                            value: dateFormat.format(trip.endDate),
                            label: 'Ends')),
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
        Text(value,
            style: textStyles.titleMedium
                ?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        Text(label,
            style: textStyles.labelSmall
                ?.copyWith(color: Colors.black.withValues(alpha: 0.8))),
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
                  color: (isPast ? colors.outline : AppColors.info)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                    child: Text(isPast ? '📍' : '✈️',
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.destinationCity,
                        style: textStyles.titleSmall?.copyWith(
                            color: isPast ? colors.onSurfaceVariant : null)),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                      style: textStyles.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(trip.status,
                    style: textStyles.labelSmall?.copyWith(
                        color: _getStatusColor(trip.status),
                        fontWeight: FontWeight.w600)),
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

  // Date state variables
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _notesController = TextEditingController();
    _cityFocusNode = FocusNode();

    // Default dates: start tomorrow, end in 7 days
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _endDate = _startDate.add(const Duration(days: 7));
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

  /// Returns true if the form can be submitted (all required fields valid)
  bool get _canSubmit => _isCityValid;

  /// Returns true if dates are logically valid (end >= start)
  bool get _areDatesValid => !_endDate.isBefore(_startDate);

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

    // Validate dates (should already be enforced by date picker, but double-check)
    if (!_areDatesValid) {
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

  Future<void> _pickDate(bool isStart) async {
    HapticUtils.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Adjust end date if it's before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
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

      // Create trip with all form data
      final newTrip = await tripService.createTrip(
        destinationCity: _selectedCity!,
        destinationCountry: _selectedCountry,
        startDate: _startDate,
        endDate: _endDate,
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                // Title
                Text('New Trip', style: textStyles.titleLarge),
                const SizedBox(height: 24),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                                          style:
                                              textStyles.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (suggestion.country != null)
                                          Text(
                                            suggestion.country!,
                                            style:
                                                textStyles.bodySmall?.copyWith(
                                              color: colors.onSurfaceVariant,
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
                const SizedBox(height: 16),
                // Date pickers
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
                    onPressed:
                        (!_canSubmit || _isSubmitting) ? null : _createTrip,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

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
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: textStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
