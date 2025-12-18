import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/models/ai_models.dart';

/// Widget to display AI-generated quick insights for a place
/// Shows overview tags, vibe, best-for, and quick tip
class PlaceQuickInsightsWidget extends StatelessWidget {
  final PlaceQuickInsights insights;
  final bool compact;

  const PlaceQuickInsightsWidget({
    super.key,
    required this.insights,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    if (compact) {
      // Compact mode - just tags in a row
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: insights.tags.take(3).map((tag) => _QuickInsightChip(
          label: tag,
          compact: true,
        )).toList(),
      );
    }

    // Full mode - all insights
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Insights',
                style: textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              if (insights.fromCache)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cached,
                        size: 10,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'AI',
                        style: textStyles.labelSmall?.copyWith(
                          fontSize: 9,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insights.tags.map((tag) => _QuickInsightChip(
              label: tag,
            )).toList(),
          ),
          
          // Vibe & Best For
          if (insights.vibe != null || insights.bestFor != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (insights.vibe != null) ...[
                  Flexible(
                    child: _InfoPill(
                      icon: Icons.mood,
                      label: insights.vibe!,
                      color: AppColors.info,
                    ),
                  ),
                  if (insights.bestFor != null) const SizedBox(width: 8),
                ],
                if (insights.bestFor != null)
                  Flexible(
                    child: _InfoPill(
                      icon: Icons.people_outline,
                      label: insights.bestFor!,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
          
          // Quick Tip
          if (insights.quickTip != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.xp.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.xp.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: AppColors.xp,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insights.quickTip!,
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }
}

/// Individual quick insight tag chip
class _QuickInsightChip extends StatelessWidget {
  final String label;
  final bool compact;

  const _QuickInsightChip({
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: (compact ? textStyles.labelSmall : textStyles.labelMedium)?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Info pill for vibe and bestFor
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: textStyles.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inline quick insights for place cards
class PlaceQuickInsightsInline extends StatelessWidget {
  final PlaceQuickInsights insights;

  const PlaceQuickInsightsInline({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (insights.tags.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 10,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            insights.tags.take(2).join(' • '),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

