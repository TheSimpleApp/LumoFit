import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/models/ai_models.dart';

/// AI-powered fitness intelligence card for place details
class PlaceFitnessIntelligenceCard extends StatelessWidget {
  final PlaceFitnessIntelligence intelligence;
  final String placeType;

  const PlaceFitnessIntelligenceCard({
    super.key,
    required this.intelligence,
    required this.placeType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.1),
            colors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Fitness Intelligence',
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'Analyzed ${intelligence.reviewsAnalyzed} reviews',
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (intelligence.fitnessScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(intelligence.fitnessScore!),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intelligence.fitnessScore!.toStringAsFixed(1),
                        style: textStyles.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary
          Text(
            intelligence.summary,
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
          ),

          if (intelligence.sentiment != null) ...[
            const SizedBox(height: 12),
            _SentimentChip(sentiment: intelligence.sentiment!),
          ],

          // Type-specific sections
          if (intelligence.gymInsights != null) ...[
            const SizedBox(height: 16),
            _GymInsightsSection(insights: intelligence.gymInsights!),
          ],

          if (intelligence.restaurantInsights != null) ...[
            const SizedBox(height: 16),
            _RestaurantInsightsSection(
                insights: intelligence.restaurantInsights!),
          ],

          if (intelligence.trailInsights != null) ...[
            const SizedBox(height: 16),
            _TrailInsightsSection(insights: intelligence.trailInsights!),
          ],

          // Pros & Cons
          if (intelligence.pros.isNotEmpty || intelligence.cons.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ProsConsSection(
              pros: intelligence.pros,
              cons: intelligence.cons,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return AppColors.success;
    if (score >= 6.0) return AppColors.primary;
    if (score >= 4.0) return AppColors.warning;
    return Colors.orange;
  }
}

class _SentimentChip extends StatelessWidget {
  final ReviewSentiment sentiment;

  const _SentimentChip({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    final sentimentColor = sentiment.overall >= 0.5
        ? AppColors.success
        : sentiment.overall >= 0
            ? colors.primary
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sentimentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: sentimentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sentiment.overall >= 0.5
                ? Icons.sentiment_very_satisfied
                : sentiment.overall >= 0
                    ? Icons.sentiment_satisfied
                    : Icons.sentiment_neutral,
            size: 16,
            color: sentimentColor,
          ),
          const SizedBox(width: 6),
          Text(
            sentiment.label,
            style: textStyles.labelMedium?.copyWith(
              color: sentimentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GymInsightsSection extends StatelessWidget {
  final GymIntelligence insights;

  const _GymInsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center, size: 18, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'Gym Details',
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (insights.equipment.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.sports_gymnastics,
            label: 'Equipment',
            value: insights.equipment.take(3).join(', '),
          ),
          const SizedBox(height: 8),
        ],
        if (insights.amenities.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.local_laundry_service_outlined,
            label: 'Amenities',
            value: insights.amenities.take(3).join(', '),
          ),
          const SizedBox(height: 8),
        ],
        if (insights.cleanlinessRating != null) ...[
          _InfoRow(
            icon: Icons.cleaning_services_outlined,
            label: 'Cleanliness',
            value: insights.cleanlinessRating!,
          ),
          const SizedBox(height: 8),
        ],
        if (insights.beginnerFriendly != null)
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Beginner Friendly',
            value: insights.beginnerFriendly! ? 'Yes' : 'No',
          ),
      ],
    );
  }
}

class _RestaurantInsightsSection extends StatelessWidget {
  final RestaurantIntelligence insights;

  const _RestaurantInsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant, size: 18, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              'Nutrition Details',
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (insights.healthyOptions.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.eco_outlined,
            label: 'Healthy Options',
            value: insights.healthyOptions.take(3).join(', '),
          ),
          const SizedBox(height: 8),
        ],
        if (insights.dietaryAccommodations.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.local_dining_outlined,
            label: 'Dietary',
            value: insights.dietaryAccommodations.take(3).join(', '),
          ),
          const SizedBox(height: 8),
        ],
        if (insights.proteinScore != null) ...[
          Row(
            children: [
              Icon(Icons.egg_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Protein Score: ',
                style: textStyles.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: insights.proteinScore! / 10,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${insights.proteinScore!.toStringAsFixed(1)}/10',
                style: textStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (insights.postWorkoutFriendly != null)
          _InfoRow(
            icon: Icons.run_circle_outlined,
            label: 'Post-Workout',
            value: insights.postWorkoutFriendly! ? 'Recommended' : 'Not ideal',
          ),
      ],
    );
  }
}

class _TrailInsightsSection extends StatelessWidget {
  final TrailIntelligence insights;

  const _TrailInsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.terrain, size: 18, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              'Trail Details',
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (insights.difficulty != null) ...[
          _InfoRow(
            icon: Icons.show_chart,
            label: 'Difficulty',
            value: insights.difficulty!,
          ),
          const SizedBox(height: 8),
        ],
        if (insights.terrain != null) ...[
          _InfoRow(
            icon: Icons.landscape_outlined,
            label: 'Terrain',
            value: insights.terrain!,
          ),
          const SizedBox(height: 8),
        ],
        if (insights.distanceKm != null) ...[
          _InfoRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${insights.distanceKm!.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 8),
        ],
        if (insights.scenicHighlights.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.camera_alt_outlined,
            label: 'Highlights',
            value: insights.scenicHighlights.take(2).join(', '),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (insights.dogFriendly == true)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('🐕 Dog Friendly'),
                  labelStyle: textStyles.labelSmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (insights.bikeAccessible == true)
              Chip(
                label: Text('🚴 Bike OK'),
                labelStyle: textStyles.labelSmall,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: textStyles.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProsConsSection extends StatelessWidget {
  final List<String> pros;
  final List<String> cons;

  const _ProsConsSection({
    required this.pros,
    required this.cons,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      children: [
        if (pros.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.thumb_up_outlined, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pros
                      .take(3)
                      .map((pro) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: textStyles.bodySmall),
                                Expanded(
                                  child: Text(
                                    pro,
                                    style: textStyles.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        if (pros.isNotEmpty && cons.isNotEmpty) const SizedBox(height: 12),
        if (cons.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.thumb_down_outlined, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cons
                      .take(3)
                      .map((con) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: textStyles.bodySmall),
                                Expanded(
                                  child: Text(
                                    con,
                                    style: textStyles.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Quick insights chips showing key highlights
class QuickInsightsChips extends StatelessWidget {
  final PlaceFitnessIntelligence intelligence;

  const QuickInsightsChips({
    super.key,
    required this.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    // Best time chip
    if (intelligence.bestTimesDetailed.isNotEmpty) {
      final bestTime = intelligence.bestTimesDetailed.entries.first;
      chips.add(_InsightChip(
        icon: Icons.access_time,
        label: bestTime.value.split('-').first.trim(),
        color: AppColors.primary,
      ));
    }

    // Crowd insight
    if (intelligence.crowdInsights != null &&
        intelligence.crowdInsights!.toLowerCase().contains('quiet')) {
      chips.add(_InsightChip(
        icon: Icons.people_outline,
        label: 'Usually Quiet',
        color: AppColors.success,
      ));
    } else if (intelligence.crowdInsights != null &&
        intelligence.crowdInsights!.toLowerCase().contains('busy')) {
      chips.add(_InsightChip(
        icon: Icons.people,
        label: 'Often Busy',
        color: Colors.orange,
      ));
    }

    // Type-specific chips
    if (intelligence.gymInsights?.beginnerFriendly == true) {
      chips.add(_InsightChip(
        icon: Icons.person_outline,
        label: 'Beginner OK',
        color: AppColors.info,
      ));
    }

    if (intelligence.restaurantInsights?.postWorkoutFriendly == true) {
      chips.add(_InsightChip(
        icon: Icons.run_circle,
        label: 'Post-Workout',
        color: AppColors.success,
      ));
    }

    if (intelligence.trailInsights?.dogFriendly == true) {
      chips.add(_InsightChip(
        icon: Icons.pets,
        label: 'Dog Friendly',
        color: AppColors.info,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyles.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart timing insights widget
class SmartTimingWidget extends StatelessWidget {
  final Map<String, String> bestTimes;
  final String? crowdInsights;

  const SmartTimingWidget({
    super.key,
    required this.bestTimes,
    this.crowdInsights,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    if (bestTimes.isEmpty && crowdInsights == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Text('Best Times to Visit', style: textStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        if (bestTimes.isNotEmpty)
          ...bestTimes.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: textStyles.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: textStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        if (crowdInsights != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    crowdInsights!,
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}
