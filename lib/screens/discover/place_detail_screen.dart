import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/services/place_service.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:fittravel/services/google_places_service.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/services/community_photo_service.dart';
import 'package:fittravel/models/community_photo.dart';
import 'package:fittravel/services/review_service.dart';
import 'package:fittravel/models/review_model.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/services/ai_guide_service.dart';
import 'package:fittravel/utils/haptic_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fittravel/openai/openai_config.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/widgets/place_fitness_intelligence_card.dart';
import 'package:fittravel/widgets/place_quick_insights.dart';
import 'package:fittravel/widgets/details_action_bar.dart';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late PlaceModel _place;
  bool _isSaved = false;
  PlaceFitnessIntelligence? _fitnessIntel;
  bool _isLoadingIntel = false;
  PlaceQuickInsights? _quickInsights;
  bool _isLoadingQuickInsights = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _checkIfSaved();
    _loadQuickInsights();
    _loadFitnessIntelligence();
  }

  Future<void> _loadQuickInsights() async {
    setState(() => _isLoadingQuickInsights = true);

    try {
      final aiService = context.read<AiGuideService>();

      final insights = await aiService.generateQuickInsights(
        placeName: _place.name,
        placeType: _place.type.name,
        rating: _place.rating,
        reviewCount: _place.userRatingsTotal,
        googlePlaceId: _place.googlePlaceId,
      );

      if (mounted) {
        setState(() {
          _quickInsights = insights;
          _isLoadingQuickInsights = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load quick insights: $e');
      if (mounted) {
        setState(() => _isLoadingQuickInsights = false);
      }
    }
  }

  Future<void> _loadFitnessIntelligence() async {
    setState(() => _isLoadingIntel = true);

    try {
      final aiService = context.read<AiGuideService>();
      final reviewService = context.read<ReviewService>();

      // Get community reviews for this place
      final reviews = reviewService.getReviewsForPlace(_place.id);
      final reviewsJson = reviews
          .map((r) => {
                'rating': r.rating,
                'text': r.text,
                'createdAt': r.createdAt.toIso8601String(),
              })
          .toList();

      // Get place data
      final placeData = {
        'name': _place.name,
        'type': _place.type.name,
        'rating': _place.rating,
        'userRatingsTotal': _place.userRatingsTotal,
        'priceLevel': _place.priceLevel,
        'openingHours': _place.openingHours,
      };

      final intel = await aiService.analyzePlaceFitness(
        placeId: _place.id,
        placeName: _place.name,
        placeType: _place.type.name,
        reviews: reviewsJson,
        placeData: placeData,
      );

      if (mounted) {
        setState(() {
          _fitnessIntel = intel;
          _isLoadingIntel = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load fitness intelligence: $e');
      if (mounted) {
        setState(() => _isLoadingIntel = false);
      }
    }
  }

  void _checkIfSaved() {
    final placeService = context.read<PlaceService>();
    final savedPlace = placeService.savedPlaces.any(
      (p) => p.googlePlaceId == _place.googlePlaceId || p.id == _place.id,
    );
    setState(() => _isSaved = savedPlace);
  }

  Future<void> _toggleSave() async {
    final placeService = context.read<PlaceService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final primaryColor = Theme.of(context).colorScheme.primary;

    await HapticUtils.medium();

    if (_isSaved) {
      // Find and remove the saved place
      final saved = placeService.savedPlaces.firstWhere(
        (p) => p.googlePlaceId == _place.googlePlaceId || p.id == _place.id,
        orElse: () => _place,
      );
      await placeService.removePlace(saved.id);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Removed from your places'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: surfaceColor,
          ),
        );
      }
    } else {
      await placeService.savePlace(_place);
      await HapticUtils.success();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Saved! 📍'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaved = !_isSaved);
    }
  }

  Future<void> _markVisited() async {
    final placeService = context.read<PlaceService>();
    final userService = context.read<UserService>();
    final gamificationService = context.read<GamificationService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await HapticUtils.medium();

    // First save if not already saved
    if (!_isSaved) {
      await placeService.savePlace(_place);
      if (mounted) {
        setState(() => _isSaved = true);
      }
    }

    // Find the saved place and mark as visited
    final saved = placeService.savedPlaces.firstWhere(
      (p) => p.googlePlaceId == _place.googlePlaceId || p.id == _place.id,
      orElse: () => _place,
    );

    await placeService.markVisited(saved.id);

    // Award XP and check badges
    final xpEarned = _place.type == PlaceType.gym ? 50 : 25;
    await userService.addXp(xpEarned);
    final totalXp = userService.currentUser?.totalXp ?? 0;
    // visits count
    final visitedCount =
        placeService.savedPlaces.where((p) => p.isVisited).length;
    await gamificationService.checkXpBadges(totalXp);
    await gamificationService.checkVisitBadges(visitedCount);

    await HapticUtils.success();
    if (mounted) {
      setState(() {
        _place = _place.copyWith(isVisited: true, visitedAt: DateTime.now());
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('+$xpEarned XP • Visit logged! 🎉'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openMaps() async {
    if (_place.latitude == null || _place.longitude == null) return;
    await HapticUtils.light();

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_place.latitude},${_place.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    if (_place.phoneNumber == null) return;
    await HapticUtils.light();

    final url = Uri.parse('tel:${_place.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWebsite() async {
    if (_place.website == null) return;
    await HapticUtils.light();

    final url = Uri.parse(_place.website!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addToTrip() async {
    // Ensure the place is saved so it has a stable id in PlaceService
    final placeService = context.read<PlaceService>();
    if (!_isSaved) {
      await placeService.savePlace(_place);
      if (mounted) {
        setState(() => _isSaved = true);
      }
    }
    if (!mounted) return;
    // Refresh local reference to get the saved instance id if needed
    final saved = placeService.savedPlaces.firstWhere(
      (p) => p.googlePlaceId == _place.googlePlaceId || p.id == _place.id,
      orElse: () => _place,
    );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TripPickerSheet(placeId: saved.id),
    );
  }

  Color _getPlaceColor() {
    switch (_place.type) {
      case PlaceType.gym:
        return AppColors.primary;
      case PlaceType.restaurant:
        return AppColors.success;
      case PlaceType.park:
        return AppColors.info;
      case PlaceType.trail:
        return AppColors.warning;
      case PlaceType.other:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final placeColor = _getPlaceColor();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
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
                onPressed: _toggleSave,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isSaved ? AppColors.xp : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PlaceHeroImage(
                place: _place,
                placeColor: placeColor,
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_place.name, style: textStyles.headlineSmall)
                                .animate()
                                .fadeIn()
                                .slideX(begin: -0.1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: placeColor.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_place.typeEmoji,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _place.typeLabel,
                                        style: textStyles.labelSmall?.copyWith(
                                          color: placeColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_place.priceLevel != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      _place.priceLevel!,
                                      style: textStyles.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ).animate().fadeIn(delay: 100.ms),
                          ],
                        ),
                      ),
                      if (_place.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.xp.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      size: 20, color: AppColors.xp),
                                  const SizedBox(width: 4),
                                  Text(
                                    _place.rating!.toStringAsFixed(1),
                                    style: textStyles.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_place.userRatingsTotal != null)
                                Text(
                                  '${_place.userRatingsTotal} reviews',
                                  style: textStyles.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).scale(delay: 100.ms),
                    ],
                  ),

                  // Visited Badge
                  if (_place.isVisited) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 20, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'You visited this place',
                            style: textStyles.labelMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_place.visitedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${_formatDate(_place.visitedAt!)}',
                              style: textStyles.labelSmall?.copyWith(
                                color: AppColors.success.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ],

                  const SizedBox(height: 24),

                  // Quick Actions
                  Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: _openMaps,
                      ),
                      const SizedBox(width: 12),
                      if (_place.phoneNumber != null)
                        _QuickActionButton(
                          icon: Icons.phone,
                          label: 'Call',
                          onTap: _callPhone,
                        ),
                      if (_place.website != null) ...[
                        const SizedBox(width: 12),
                        _QuickActionButton(
                          icon: Icons.language,
                          label: 'Website',
                          onTap: _openWebsite,
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),
                  Divider(color: colors.outline.withValues(alpha: 0.1)),
                  const SizedBox(height: 24),

                  // Quick Insights (Fast AI Overview)
                  if (_isLoadingQuickInsights)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Generating quick insights...',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn()
                  else if (_quickInsights != null) ...[
                    PlaceQuickInsightsWidget(insights: _quickInsights!),
                    const SizedBox(height: 24),
                  ],

                  // AI Fitness Intelligence
                  if (_isLoadingIntel)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analyzing fitness insights...',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn()
                  else if (_fitnessIntel != null) ...[
                    PlaceFitnessIntelligenceCard(
                      intelligence: _fitnessIntel!,
                      placeType: _place.type.name,
                    ),
                    const SizedBox(height: 16),

                    // Quick Insights Chips
                    QuickInsightsChips(intelligence: _fitnessIntel!),
                    const SizedBox(height: 24),

                    // Smart Timing
                    if (_fitnessIntel!.bestTimesDetailed.isNotEmpty ||
                        _fitnessIntel!.crowdInsights != null) ...[
                      SmartTimingWidget(
                        bestTimes: _fitnessIntel!.bestTimesDetailed,
                        crowdInsights: _fitnessIntel!.crowdInsights,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // AI Tips
                    if (_fitnessIntel!.tips.isNotEmpty) ...[
                      _AiTipsSection(tips: _fitnessIntel!.tips),
                      const SizedBox(height: 24),
                    ],

                    // What to Bring
                    if (_fitnessIntel!.whatToBring.isNotEmpty) ...[
                      _WhatToBringSection(items: _fitnessIntel!.whatToBring),
                      const SizedBox(height: 24),
                    ],

                    // Common Phrases from Reviews
                    if (_fitnessIntel!.commonPhrases.isNotEmpty) ...[
                      _CommonPhrasesSection(
                          phrases: _fitnessIntel!.commonPhrases),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // Community Photos Section
                  _CommunityPhotosSection(placeId: _place.id)
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const SizedBox(height: 24),

                  // Community Reviews Section
                  _ReviewsSection(placeId: _place.id)
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),

                  // Details Section
                  if (_place.address != null) ...[
                    _DetailSection(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      content: _place.address!,
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 20),
                  ],

                  if (_place.openingHours.isNotEmpty) ...[
                    _OpeningHoursSection(hours: _place.openingHours)
                        .animate()
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: 20),
                  ],

                  if (_place.notes != null) ...[
                    _DetailSection(
                      icon: Icons.info_outline,
                      title: 'Notes',
                      content: _place.notes!,
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DetailsActionBar(
            leading: OutlinedButton(
              onPressed: _toggleSave,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              child: ActionBarLabel(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                text: _isSaved ? 'Saved' : 'Save',
              ),
            ),
            middle: OutlinedButton(
              onPressed: _addToTrip,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              child: const ActionBarLabel(
                icon: Icons.playlist_add,
                text: 'Add to Trip',
              ),
            ),
            primary: ElevatedButton(
              onPressed: _place.isVisited ? null : _markVisited,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                backgroundColor:
                    _place.isVisited ? colors.surfaceContainerHighest : null,
                foregroundColor:
                    _place.isVisited ? colors.onSurfaceVariant : null,
              ),
              child: ActionBarLabel(
                icon: _place.isVisited ? Icons.check : Icons.fitness_center,
                text: _place.isVisited ? 'Visited' : 'Mark Visited',
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}

class _TripPickerSheet extends StatelessWidget {
  final String placeId;
  const _TripPickerSheet({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final tripService = context.watch<TripService>();
    final trips = tripService.trips;

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
              Text('Add to a Trip', style: textStyles.titleLarge),
              const SizedBox(height: 12),
              if (trips.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You don\'t have any trips yet.',
                        style: textStyles.bodyMedium),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.go('/trips'),
                      icon: const Icon(Icons.flight_takeoff),
                      label: const Text('Create a trip'),
                    ),
                  ],
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final t = trips[index];
                      final already = t.savedPlaceIds.contains(placeId);
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
                                        .addPlaceToTrip(t.id, placeId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Added to ${t.destinationCity}'),
                                            behavior:
                                                SnackBarBehavior.floating),
                                      );
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Text('✈️',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t.destinationCity,
                                            style: textStyles.bodyMedium),
                                        Text(
                                          '${DateFormat('MMM d').format(t.startDate)} - ${DateFormat('MMM d, yyyy').format(t.endDate)}',
                                          style: textStyles.labelSmall
                                              ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
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

class _PlaceHeroImage extends StatefulWidget {
  final PlaceModel place;
  final Color placeColor;

  const _PlaceHeroImage({required this.place, required this.placeColor});

  @override
  State<_PlaceHeroImage> createState() => _PlaceHeroImageState();
}

class _PlaceHeroImageState extends State<_PlaceHeroImage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final googlePlacesService = GooglePlacesService();

    // Use photoReferences if available, otherwise fall back to single photoReference
    final photoRefs = widget.place.photoReferences.isNotEmpty
        ? widget.place.photoReferences
        : (widget.place.photoReference != null
            ? [widget.place.photoReference!]
            : <String>[]);

    if (photoRefs.isEmpty) {
      return _PlaceholderImage(
          emoji: widget.place.typeEmoji, color: widget.placeColor);
    }

    return Stack(
      children: [
        // Carousel
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemCount: photoRefs.length,
          itemBuilder: (context, index) {
            final photoUrl = googlePlacesService.getPhotoUrl(photoRefs[index],
                maxWidth: 800);

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.surface.withValues(alpha: 0.3),
                    colors.surface,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _PlaceholderImage(
                  emoji: widget.place.typeEmoji,
                  color: widget.placeColor,
                ),
              ),
            );
          },
        ),

        // Page indicator dots (only show if more than 1 photo)
        if (photoRefs.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photoRefs.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colors.primary
                        : colors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ).animate(interval: 50.ms).fadeIn().scale(),
            ),
          ),

        // Photo counter badge (top right)
        if (photoRefs.length > 1)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentPage + 1}/${photoRefs.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final String emoji;
  final Color color;

  const _PlaceholderImage({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Expanded(
      child: Material(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: textStyles.labelSmall?.copyWith(
                    color: colors.onSurface,
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

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textStyles.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: textStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpeningHoursSection extends StatefulWidget {
  final List<String> hours;

  const _OpeningHoursSection({required this.hours});

  @override
  State<_OpeningHoursSection> createState() => _OpeningHoursSectionState();
}

class _OpeningHoursSectionState extends State<_OpeningHoursSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.access_time, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opening Hours',
                      style: textStyles.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hours.first,
                      style: textStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_isExpanded && widget.hours.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.hours.skip(1).map((hour) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    hour,
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _CommunityPhotosSection extends StatelessWidget {
  final String placeId;
  const _CommunityPhotosSection({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final svc = context.watch<CommunityPhotoService>();
    final photos = svc.getPhotosForPlace(placeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text('Community Photos', style: textStyles.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddPhotoSheet(context),
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No community photos yet — be the first!',
                    style: textStyles.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: photos.length.clamp(0, 9),
            itemBuilder: (context, index) {
              final p = photos[index];
              return Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: () => _openLightbox(context, photos, index),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: _CommunityImage(imageUrl: p.imageUrl),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddPhotoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPhotoSheet(placeId: placeId),
    );
  }

  void _openLightbox(
      BuildContext context, List<CommunityPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) =>
          _PhotoLightbox(photos: photos, initialIndex: initialIndex),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String placeId;
  const _ReviewsSection({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final svc = context.watch<ReviewService>();
    final reviews = svc.getReviewsForPlace(placeId);
    final avg = svc.getAverageRating(placeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rate_review_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text('Community Reviews', style: textStyles.titleMedium),
            const Spacer(),
            if (avg != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.xp),
                    const SizedBox(width: 4),
                    Text(avg.toStringAsFixed(1),
                        style: textStyles.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('(${reviews.length})',
                        style: textStyles.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _showAddReviewSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No reviews yet — share your experience!',
                    style: textStyles.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...reviews.take(3).map((r) => _ReviewTile(review: r)),
              if (reviews.length > 3)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showAllReviews(context, reviews),
                    child: const Text('See all'),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddReviewSheet(placeId: placeId),
    );
  }

  void _showAllReviews(BuildContext context, List<dynamic> reviews) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                Text('All Reviews', style: textStyles.titleLarge),
                const SizedBox(height: 12),
                ...reviews.map((r) => _ReviewTile(review: r)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, size: 16, color: AppColors.xp),
              const SizedBox(width: 4),
              Text('${review.rating}/5',
                  style: textStyles.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(review.createdAt),
                style: textStyles.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          if ((review.text ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.text!, style: textStyles.bodyMedium),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Thanks for the report. We\'ll review this.'),
                      behavior: SnackBarBehavior.floating),
                );
              },
              icon: Icon(Icons.flag_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              label: Text('Report',
                  style: textStyles.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReviewSheet extends StatefulWidget {
  final String placeId;
  const _AddReviewSheet({required this.placeId});

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  int _rating = 5;
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 16),
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
              Text('Add a Review', style: textStyles.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Rating:', style: textStyles.labelLarge),
                  const SizedBox(width: 8),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _rating = i),
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        color: AppColors.xp,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Share your experience',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.onPrimary))
                          : const Icon(Icons.check),
                      label: const Text('Submit Review'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Capture context-dependent values before async operations
    final reviewService = context.read<ReviewService>();
    final userService = context.read<UserService>();
    final gamificationService = context.read<GamificationService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);
    try {
      // AI moderation on text
      final text = _controller.text.trim();
      if (text.isNotEmpty) {
        final openai = OpenAIClient();
        final mod = await openai.moderateText(
            text: text, context: 'FitTravel place review: ${widget.placeId}');
        if (!mod.allowed) {
          if (mounted) {
            await _showModerationRejectSheet(mod);
          }
          return;
        }
      }

      await reviewService.addReview(
        placeId: widget.placeId,
        rating: _rating,
        text: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      );
      // Award XP for contribution and check XP badges
      await userService.addXp(20);
      final totalXp = userService.currentUser?.totalXp ?? 0;
      await gamificationService.checkXpBadges(totalXp);
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Review added!'),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e, st) {
      debugPrint('Add review failed: $e');
      debugPrint(st.toString());
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Something went wrong. Try again.'),
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showModerationRejectSheet(ModerationResult mod) async {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                Row(children: [
                  Icon(Icons.shield, color: colors.error),
                  const SizedBox(width: 8),
                  Text('Content flagged',
                      style:
                          textTheme.titleLarge?.copyWith(color: colors.error)),
                ]),
                const SizedBox(height: 8),
                if ((mod.reason ?? '').isNotEmpty)
                  Text(mod.reason!, style: textTheme.bodyMedium),
                if (mod.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mod.categories
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(c,
                                    style: textTheme.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant)),
                              ))
                          .toList()),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Close'))),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoSheet extends StatefulWidget {
  final String placeId;
  const _AddPhotoSheet({required this.placeId});

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _pickedDataUrl;

  @override
  void dispose() {
    _controller.dispose();
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
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 16,
          ),
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
              Text('Add a Photo', style: textStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                  'Add a photo by pasting a URL or selecting from your device.',
                  style: textStyles.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://.../image.jpg',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_pickedDataUrl == null
                    ? 'Choose from device'
                    : 'Image selected'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.onPrimary))
                          : const Icon(Icons.check),
                      label: const Text('Add Photo'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Capture context-dependent values before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final photoService = context.read<CommunityPhotoService>();
    final userService = context.read<UserService>();
    final gamificationService = context.read<GamificationService>();
    final navigator = Navigator.of(context);

    final url = _controller.text.trim();
    final hasHttpUrl = url.isNotEmpty && url.startsWith('http');
    final hasPicked = _pickedDataUrl != null;
    if (!hasHttpUrl && !hasPicked) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Add a URL or pick an image'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // AI image moderation
      final openai = OpenAIClient();
      final mod = await openai.moderateImage(
        imageUrlOrData: hasPicked ? _pickedDataUrl! : url,
        context: 'FitTravel place photo: ${widget.placeId}',
      );
      if (!mod.allowed) {
        if (mounted) {
          await _showModerationRejectSheet(mod);
        }
        return;
      }

      if (hasHttpUrl) {
        await photoService.addPhotoUrl(placeId: widget.placeId, imageUrl: url);
      } else if (hasPicked) {
        await photoService.addPhotoUrl(
            placeId: widget.placeId, imageUrl: _pickedDataUrl!);
      }
      // Award XP for contribution and check XP badges
      await userService.addXp(10);
      final totalXp = userService.currentUser?.totalXp ?? 0;
      await gamificationService.checkXpBadges(totalXp);
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Photo added!'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e, st) {
      debugPrint('Add photo failed: $e');
      debugPrint(st.toString());
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Something went wrong. Try again.'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showModerationRejectSheet(ModerationResult mod) async {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                Row(children: [
                  Icon(Icons.shield, color: colors.error),
                  const SizedBox(width: 8),
                  Text('Photo rejected',
                      style:
                          textTheme.titleLarge?.copyWith(color: colors.error)),
                ]),
                const SizedBox(height: 8),
                if ((mod.reason ?? '').isNotEmpty)
                  Text(mod.reason!, style: textTheme.bodyMedium),
                if (mod.categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mod.categories
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(c,
                                    style: textTheme.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant)),
                              ))
                          .toList()),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Close'))),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Lazy import to avoid forcing web-specific picker code paths
      // ignore: avoid_dynamic_calls
      final picker = await _loadImagePicker();
      if (picker == null) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(const SnackBar(
              content: Text('Image picker unavailable'),
              behavior: SnackBarBehavior.floating));
        }
        return;
      }
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = _inferMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      if (mounted) {
        setState(() => _pickedDataUrl = dataUrl);
      }
    } catch (e, st) {
      debugPrint('Image pick failed: $e');
      debugPrint(st.toString());
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Failed to pick image'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }
}

class _CommunityImage extends StatelessWidget {
  final String imageUrl;
  const _CommunityImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Container(
          color: colors.surfaceContainerHighest,
          child:
              Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
        );
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        color: colors.surfaceContainerHighest,
        child:
            Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _PhotoLightbox extends StatefulWidget {
  final List<CommunityPhoto> photos;
  final int initialIndex;
  const _PhotoLightbox({required this.photos, required this.initialIndex});

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            itemBuilder: (_, index) {
              final img = widget.photos[index].imageUrl;
              return Center(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _CommunityImage(imageUrl: img),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              tooltip: 'Report',
              icon: Icon(Icons.flag_outlined, color: colors.onInverseSurface),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Thanks for the report. We\'ll review this.'),
                      behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: colors.onInverseSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers for image picking without hard import errors when not used in tests
Future<dynamic> _loadImagePicker() async {
  try {
    // Defer import to runtime
    // ignore: import_of_legacy_library_into_null_safe
    return ImagePicker();
  } catch (_) {
    return null;
  }
}

String _inferMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

/// AI Tips Section
class _AiTipsSection extends StatelessWidget {
  final List<String> tips;

  const _AiTipsSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.xp),
            const SizedBox(width: 8),
            Text('Fitness Tips', style: textStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        ...tips.take(5).map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.xp.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.xp.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: textStyles.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }
}

/// What to Bring Section
class _WhatToBringSection extends StatelessWidget {
  final List<String> items;

  const _WhatToBringSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.backpack_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text('What to Bring', style: textStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          colors.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: textStyles.labelMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

/// Common Phrases Section
class _CommonPhrasesSection extends StatelessWidget {
  final List<String> phrases;

  const _CommonPhrasesSection({required this.phrases});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text('What People Say', style: textStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: phrases
              .take(8)
              .map((phrase) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '"$phrase"',
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }
}
