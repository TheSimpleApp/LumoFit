import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/widgets/empty_state_illustrations.dart';

/// A flexible, reusable empty state widget that displays an optional illustration,
/// title, description, and call-to-action button.
///
/// Follows the dark luxury theme with gold accents and includes smooth
/// entrance animations using flutter_animate.
///
/// Use the preset factory constructors for common scenarios:
/// - [EmptyStateWidget.trips] - For empty trips list
/// - [EmptyStateWidget.activities] - For no activities today
/// - [EmptyStateWidget.challenges] - For completed or no challenges
/// - [EmptyStateWidget.gyms] - For gym discovery
/// - [EmptyStateWidget.food] - For food/restaurant discovery
/// - [EmptyStateWidget.trails] - For trail discovery
/// - [EmptyStateWidget.events] - For events discovery
/// - [EmptyStateWidget.photos] - For photo contributions
/// - [EmptyStateWidget.reviews] - For review contributions
/// - [EmptyStateWidget.savedPlaces] - For saved places
/// - [EmptyStateWidget.search] - For empty search results
class EmptyStateWidget extends StatelessWidget {
  /// The main title text displayed prominently
  final String title;

  /// The description text providing context or guidance
  final String description;

  /// Optional custom illustration widget (e.g., CustomPaint, Icon, or image)
  final Widget? illustration;

  /// Optional CTA button label
  final String? ctaLabel;

  /// Optional CTA button callback
  final VoidCallback? onCtaPressed;

  /// Whether to use a secondary (outlined) style for the CTA button
  final bool useSecondaryCta;

  /// Whether to enable entrance animations
  final bool animate;

  /// Animation delay for staggered effects
  final Duration animationDelay;

  /// Whether to use a compact layout (smaller spacing and font sizes)
  final bool compact;

  /// Optional custom icon to use when no illustration is provided
  final IconData? icon;

  /// Optional icon color override
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.illustration,
    this.ctaLabel,
    this.onCtaPressed,
    this.useSecondaryCta = false,
    this.animate = true,
    this.animationDelay = Duration.zero,
    this.compact = false,
    this.icon,
    this.iconColor,
  });

  /// Creates an empty state for the trips list.
  ///
  /// Shows a globe illustration with encouraging copy about planning
  /// fitness adventures.
  factory EmptyStateWidget.trips({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'No trips yet',
      description: 'Plan your next fitness adventure and discover amazing places to stay active while traveling.',
      illustration: EmptyStateIllustrations.trips(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for today's activities.
  ///
  /// Shows a running figure illustration encouraging users to log
  /// their first activity of the day.
  factory EmptyStateWidget.activities({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
    String? streakMessage,
  }) {
    final description = streakMessage != null
        ? 'No activities yet today. $streakMessage'
        : 'No activities yet today. Get moving to keep your streak alive!';
    return EmptyStateWidget(
      key: key,
      title: 'Ready to move?',
      description: description,
      illustration: EmptyStateIllustrations.activities(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for active challenges.
  ///
  /// Shows a trophy illustration. Can indicate either all challenges
  /// completed or no active challenges available.
  factory EmptyStateWidget.challenges({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
    bool allCompleted = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: allCompleted ? 'All challenges completed!' : 'No active challenges',
      description: allCompleted
          ? 'Amazing work! Check back soon for new challenges to conquer.'
          : 'New challenges are coming soon. Keep pushing your limits!',
      illustration: EmptyStateIllustrations.challenges(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for gym discovery.
  ///
  /// Shows a dumbbell illustration encouraging users to search for
  /// fitness centers nearby.
  factory EmptyStateWidget.gyms({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'Find your gym',
      description: 'Discover top-rated gyms and fitness centers near your destination.',
      illustration: EmptyStateIllustrations.gyms(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for food/restaurant discovery.
  ///
  /// Shows a healthy food illustration encouraging users to find
  /// nutritious dining options.
  factory EmptyStateWidget.food({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'Fuel your fitness',
      description: 'Discover healthy restaurants and nutritious food spots that support your goals.',
      illustration: EmptyStateIllustrations.food(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for trail discovery.
  ///
  /// Shows a mountain trail illustration encouraging users to explore
  /// outdoor adventures.
  factory EmptyStateWidget.trails({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'Explore the outdoors',
      description: 'Find scenic trails for hiking, running, and outdoor adventures.',
      illustration: EmptyStateIllustrations.trails(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for events discovery.
  ///
  /// Shows a calendar illustration encouraging users to find fitness
  /// events in their area.
  factory EmptyStateWidget.events({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
    String? destinationName,
  }) {
    final description = destinationName != null
        ? 'No fitness events found in $destinationName. Try expanding your search.'
        : 'Discover marathons, yoga classes, and fitness meetups near you.';
    return EmptyStateWidget(
      key: key,
      title: 'No events found',
      description: description,
      illustration: EmptyStateIllustrations.events(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for photo contributions.
  ///
  /// Shows a camera illustration encouraging users to capture and
  /// share their fitness journey.
  factory EmptyStateWidget.photos({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'No photos yet',
      description: 'Capture your fitness journey and share the places you discover.',
      illustration: EmptyStateIllustrations.photos(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for review contributions.
  ///
  /// Shows a star/review illustration encouraging users to share
  /// their experiences.
  factory EmptyStateWidget.reviews({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'No reviews yet',
      description: 'Share your experiences and help others find great fitness spots.',
      illustration: EmptyStateIllustrations.reviews(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for saved places.
  ///
  /// Shows a bookmark illustration encouraging users to save their
  /// favorite fitness spots.
  factory EmptyStateWidget.savedPlaces({
    Key? key,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'Nothing saved yet',
      description: 'Bookmark gyms, restaurants, and trails to quickly find them later.',
      illustration: EmptyStateIllustrations.savedPlaces(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  /// Creates an empty state for search results.
  ///
  /// Shows a search illustration indicating no results were found
  /// for the given query.
  factory EmptyStateWidget.search({
    Key? key,
    required String query,
    String? ctaLabel,
    VoidCallback? onCtaPressed,
    bool useSecondaryCta = false,
    bool animate = true,
    Duration animationDelay = Duration.zero,
    bool compact = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: 'No results for "$query"',
      description: 'Try different keywords or check for typos in your search.',
      illustration: EmptyStateIllustrations.search(size: compact ? 80 : 120),
      ctaLabel: ctaLabel,
      onCtaPressed: onCtaPressed,
      useSecondaryCta: useSecondaryCta,
      animate: animate,
      animationDelay: animationDelay,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // Determine spacing based on compact mode
    final verticalSpacing = compact ? AppSpacing.sm : AppSpacing.md;
    final illustrationSpacing = compact ? AppSpacing.md : AppSpacing.lg;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Illustration or fallback icon
        if (illustration != null) ...[
          illustration!,
          SizedBox(height: illustrationSpacing),
        ] else if (icon != null) ...[
          _buildDefaultIcon(colors),
          SizedBox(height: illustrationSpacing),
        ],

        // Title
        Text(
          title,
          style: compact
              ? textStyles.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                )
              : textStyles.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: verticalSpacing),

        // Description
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
          ),
          child: Text(
            description,
            style: compact
                ? textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  )
                : textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            textAlign: TextAlign.center,
          ),
        ),

        // CTA Button
        if (ctaLabel != null && onCtaPressed != null) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _buildCtaButton(context),
        ],
      ],
    );

    // Apply animations if enabled
    if (animate) {
      content = content
          .animate(delay: animationDelay)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut,
          );
    }

    return Center(
      child: Padding(
        padding: compact ? AppSpacing.paddingMd : AppSpacing.paddingLg,
        child: content,
      ),
    );
  }

  Widget _buildDefaultIcon(ColorScheme colors) {
    return Container(
      width: compact ? 56 : 80,
      height: compact ? 56 : 80,
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Icon(
        icon,
        size: compact ? 28 : 40,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    if (useSecondaryCta) {
      return OutlinedButton(
        onPressed: onCtaPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: compact ? AppSpacing.sm : AppSpacing.md,
          ),
        ),
        child: Text(ctaLabel!),
      );
    }

    return ElevatedButton(
      onPressed: onCtaPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.md : AppSpacing.lg,
          vertical: compact ? AppSpacing.sm : AppSpacing.md,
        ),
      ),
      child: Text(ctaLabel!),
    );
  }
}
