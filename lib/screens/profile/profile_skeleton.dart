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
