import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';

/// A skeleton placeholder version of _ProfileCard that matches the exact layout
/// and uses the goldShimmer gradient background.
///
/// Shows shimmer placeholders for:
/// - 72x72 circular avatar
/// - Name and location text lines
/// - Level and fitness badges
/// - XP progress bar
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldShimmer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar placeholder - 72x72 circle
              _SkeletonCircleDark(size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name placeholder
                    _SkeletonBoxDark(width: 140, height: 20),
                    const SizedBox(height: 8),
                    // Location placeholder (icon + text)
                    Row(
                      children: [
                        _SkeletonBoxDark(width: 14, height: 14),
                        const SizedBox(width: 4),
                        _SkeletonBoxDark(width: 80, height: 12),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Badges row
                    Row(
                      children: [
                        // Level badge placeholder
                        _SkeletonBoxDark(
                          width: 70,
                          height: 24,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        const SizedBox(width: 8),
                        // Fitness level badge placeholder
                        _SkeletonBoxDark(
                          width: 70,
                          height: 24,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // XP progress section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Current XP placeholder
                  _SkeletonBoxDark(width: 60, height: 14),
                  // XP to next level placeholder
                  _SkeletonBoxDark(width: 120, height: 12),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _SkeletonBoxDark(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A dark skeleton box for use on gold/light backgrounds.
/// Uses semi-transparent black for the shimmer effect to match the
/// real ProfileCard which has black text on gold background.
class _SkeletonBoxDark extends StatelessWidget {
  const _SkeletonBoxDark({
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xs),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(milliseconds: 1500),
      color: Colors.black.withValues(alpha: 0.1),
    );
  }
}

/// A dark skeleton circle for use on gold/light backgrounds.
/// Uses semi-transparent black for the shimmer effect.
class _SkeletonCircleDark extends StatelessWidget {
  const _SkeletonCircleDark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(milliseconds: 1500),
      color: Colors.black.withValues(alpha: 0.1),
    );
  }
}

/// A skeleton placeholder version of _StatsSection that matches the exact layout
/// showing 4 stat cards in a 2x2 grid.
///
/// Shows shimmer placeholders for:
/// - Section title "Your Stats"
/// - 4 stat cards with icon, value, and label placeholders
class StatsSectionSkeleton extends StatelessWidget {
  const StatsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder - matches "Your Stats" text
        _SkeletonBox(width: 80, height: 18),
        const SizedBox(height: 12),
        // First row of stat cards
        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        // Second row of stat cards
        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),
      ],
    );
  }
}

/// A skeleton placeholder for a single stat card.
/// Matches the layout of _StatCard with icon, value, and label.
class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          // Icon placeholder - 40x40 box
          _SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Value placeholder - titleLarge equivalent
                _SkeletonBox(width: 50, height: 20),
                const SizedBox(height: 4),
                // Label placeholder - labelSmall equivalent
                _SkeletonBox(width: 70, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton placeholder version of _BadgesSection that matches the exact layout
/// showing a horizontal scrollable list of badge placeholders.
///
/// Shows shimmer placeholders for:
/// - Section header with title and count
/// - 5 badge items in horizontal scroll (80px width each)
class BadgesSectionSkeleton extends StatelessWidget {
  const BadgesSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - matches "Badges" title and "X/Y" count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Badges" title placeholder
            _SkeletonBox(width: 60, height: 18),
            // Badge count "X/Y" placeholder
            _SkeletonBox(width: 40, height: 16),
          ],
        ),
        const SizedBox(height: 12),
        // Horizontal scrollable badge list - matches SizedBox height: 100
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 4 ? 12 : 0),
                child: const _BadgeItemSkeleton(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A skeleton placeholder for a single badge item.
/// Matches the layout of _BadgeItem with icon and name.
class _BadgeItemSkeleton extends StatelessWidget {
  const _BadgeItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon placeholder - 48x48 box matching _BadgeItem icon container
          _SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(height: 8),
          // Badge name placeholder - matches labelSmall text
          _SkeletonBox(width: 56, height: 12),
        ],
      ),
    );
  }
}

/// A skeleton placeholder version of _QuickAddedPhotosSection that matches the
/// expected layout showing a horizontal row of 3 photo placeholders.
///
/// Shows shimmer placeholders for:
/// - Section title "Quick Added Photos"
/// - 3 photo thumbnails in horizontal row
class QuickAddedPhotosSectionSkeleton extends StatelessWidget {
  const QuickAddedPhotosSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder - matches "Quick Added Photos" text
        _SkeletonBox(width: 140, height: 18),
        const SizedBox(height: 12),
        // Horizontal row of 3 photo placeholders
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: _SkeletonBox(
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A skeleton placeholder version of _ContributionsSection that matches the
/// expected layout showing a list of contribution items with icons.
///
/// Shows shimmer placeholders for:
/// - Section title "Contributions"
/// - 3 contribution list items (photos, reviews, tips)
class ContributionsSectionSkeleton extends StatelessWidget {
  const ContributionsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder - matches "Contributions" text
        _SkeletonBox(width: 110, height: 18),
        const SizedBox(height: 12),
        // Contribution list container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            children: [
              // Contribution item 1 - Photos
              const _ContributionItemSkeleton(),
              const SizedBox(height: 16),
              // Contribution item 2 - Reviews
              const _ContributionItemSkeleton(),
              const SizedBox(height: 16),
              // Contribution item 3 - Tips
              const _ContributionItemSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A skeleton placeholder for a single contribution item.
/// Matches the layout with icon, label, and count.
class _ContributionItemSkeleton extends StatelessWidget {
  const _ContributionItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon placeholder
        _SkeletonBox(
          width: 32,
          height: 32,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        const SizedBox(width: 12),
        // Label placeholder
        _SkeletonBox(width: 80, height: 14),
        const Spacer(),
        // Count placeholder
        _SkeletonBox(width: 30, height: 16),
      ],
    );
  }
}

/// A skeleton placeholder version of _StravaSection that matches the
/// expected layout showing a Strava integration card.
///
/// Shows shimmer placeholders for:
/// - Strava icon placeholder
/// - Title and subtitle text
/// - Connect/status button
class StravaSectionSkeleton extends StatelessWidget {
  const StravaSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder - matches "Strava" text
        _SkeletonBox(width: 60, height: 18),
        const SizedBox(height: 12),
        // Integration card container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
          ),
          child: Row(
            children: [
              // Strava logo/icon placeholder
              _SkeletonBox(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 100, height: 16),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 140, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Connect button placeholder
              _SkeletonBox(
                width: 80,
                height: 36,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A skeleton placeholder version of _QuickSettings that matches the
/// expected layout showing a list of settings items.
///
/// Shows shimmer placeholders for:
/// - Section title "Quick Settings"
/// - 3 settings items with icon and label
class QuickSettingsSkeleton extends StatelessWidget {
  const QuickSettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder - matches "Quick Settings" text
        _SkeletonBox(width: 110, height: 18),
        const SizedBox(height: 12),
        // Settings list container
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            children: [
              // Settings item 1
              const _SettingsItemSkeleton(),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              // Settings item 2
              const _SettingsItemSkeleton(),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              // Settings item 3
              const _SettingsItemSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

/// A skeleton placeholder for a single settings item.
/// Matches the layout with icon, label, and chevron.
class _SettingsItemSkeleton extends StatelessWidget {
  const _SettingsItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon placeholder
          _SkeletonBox(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          const SizedBox(width: 12),
          // Label placeholder
          _SkeletonBox(width: 100, height: 14),
          const Spacer(),
          // Chevron placeholder
          _SkeletonBox(width: 16, height: 16),
        ],
      ),
    );
  }
}

/// A composite skeleton widget that combines all profile section skeletons
/// in the correct order with proper spacing, matching the real ProfileScreen layout.
///
/// Uses CustomScrollView with slivers like the real ProfileScreen.
/// Animations are staggered for a pleasant visual effect.
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header with "Profile" title and settings placeholder
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SkeletonBox(width: 80, height: 28)
                      .animate()
                      .fadeIn()
                      .slideX(begin: -0.1),
                ),
                _SkeletonBox(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
        // ProfileCard skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const ProfileCardSkeleton()
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // StatsSection skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const StatsSectionSkeleton()
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // BadgesSection skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const BadgesSectionSkeleton()
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // QuickAddedPhotosSection skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const QuickAddedPhotosSectionSkeleton()
                .animate()
                .fadeIn(delay: 320.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // ContributionsSection skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const ContributionsSectionSkeleton()
                .animate()
                .fadeIn(delay: 350.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // StravaSection skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const StravaSectionSkeleton()
                .animate()
                .fadeIn(delay: 380.ms)
                .slideY(begin: 0.1),
          ),
        ),
        // QuickSettings skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: const QuickSettingsSkeleton()
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.1),
          ),
        ),
      ],
    );
  }
}

/// A skeleton box for use on dark backgrounds.
/// Uses app surface colors for the shimmer effect.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xs),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(milliseconds: 1500),
      color: AppColors.surfaceLight.withValues(alpha: 0.5),
    );
  }
}
