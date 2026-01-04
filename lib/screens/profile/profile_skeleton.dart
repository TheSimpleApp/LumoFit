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
