import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/activity_service.dart';
import 'package:fittravel/models/activity_model.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';

class TodayActivities extends StatelessWidget {
  const TodayActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activityService = context.watch<ActivityService>();
    final todayActivities = activityService.todayActivities;
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Activity', style: textStyles.titleMedium),
            if (todayActivities.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '+${todayActivities.fold(0, (sum, a) => sum + a.xpEarned)} XP',
                  style: textStyles.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayActivities.isEmpty)
          EmptyStateWidget.activities(
            streakMessage: 'Log your first activity to keep your streak!',
            ctaLabel: 'Log Activity',
            onCtaPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Use the camera button below to log your activity!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          )
        else
          ...todayActivities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityTile(activity: activity),
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final timeFormat = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(activity.typeEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: textStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormat.format(activity.completedAt),
                  style: textStyles.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.xp.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppColors.xp, size: 14),
                const SizedBox(width: 2),
                Text(
                  '+${activity.xpEarned}',
                  style: textStyles.labelSmall?.copyWith(
                    color: AppColors.xp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.workout:
        return AppColors.primary;
      case ActivityType.meal:
        return AppColors.success;
      case ActivityType.walk:
      case ActivityType.run:
      case ActivityType.hike:
        return AppColors.info;
      case ActivityType.swim:
      case ActivityType.yoga:
        return AppColors.warning;
      case ActivityType.other:
        return AppColors.primary;
    }
  }
}
