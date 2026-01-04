import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';

/// A reusable skeleton placeholder box with shimmer animation.
///
/// Use this widget to create placeholder UI elements that show a loading
/// state with a smooth shimmer effect. The shimmer uses the app's surface
/// colors for a consistent dark luxury look.
///
/// Example usage:
/// ```dart
/// SkeletonBox(
///   width: 100,
///   height: 20,
///   borderRadius: BorderRadius.circular(AppRadius.sm),
/// )
/// ```
class SkeletonBox extends StatelessWidget {
  /// Creates a skeleton box with shimmer animation.
  ///
  /// [width] and [height] can be null to use constraints from parent.
  /// [borderRadius] defaults to [AppRadius.sm] rounded corners.
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// The width of the skeleton box. If null, uses available width from parent.
  final double? width;

  /// The height of the skeleton box. If null, uses available height from parent.
  final double? height;

  /// The border radius for rounded corners.
  /// Defaults to [AppRadius.sm] (12.0) if not specified.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: const Duration(milliseconds: 1500),
      color: AppColors.surfaceLight.withValues(alpha: 0.5),
    );
  }
}
