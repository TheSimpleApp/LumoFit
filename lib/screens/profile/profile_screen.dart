import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/services/activity_service.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/models/activity_model.dart';
import 'package:fittravel/models/badge_model.dart';
import 'package:fittravel/screens/profile/profile_skeleton.dart';
import 'package:fittravel/widgets/polish_widgets.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:fittravel/utils/haptic_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _onRefresh() async {
    final userService = context.read<UserService>();
    final activityService = context.read<ActivityService>();
    final gamificationService = context.read<GamificationService>();

    await Future.wait([
      userService.initialize(),
      activityService.initialize(),
      gamificationService.initialize(),
    ]);
    await HapticUtils.success();
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final activityService = context.watch<ActivityService>();
    final gamificationService = context.watch<GamificationService>();
    final user = userService.currentUser;
    final textStyles = Theme.of(context).textTheme;

    // Show skeleton when any service is loading OR user is null
    final isLoading = userService.isLoading ||
        activityService.isLoading ||
        gamificationService.isLoading ||
        user == null;

    if (isLoading) {
      return const Scaffold(
        body: SafeArea(child: ProfileScreenSkeleton()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Text('Profile', style: textStyles.headlineMedium)
                                  .animate()
                                  .fadeIn()
                                  .slideX(begin: -0.1)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.settings_outlined),
                        onSelected: (value) => _handleMenuSelection(context, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 12),
                                Text('Edit Profile'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('Log Out', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _ProfileCard(user: user)
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _StatsSection(
                          activities: activityService.activities, user: user)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _BadgesSection(
                          earnedBadges: gamificationService.getEarnedBadges(),
                          allBadges: gamificationService.allBadges)
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        context.push('/edit-profile');
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear user service
      context.read<UserService>().clearUser();
      // Sign out from Supabase
      await SupabaseConfig.auth.signOut();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: AppColors.goldShimmer,
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.5), width: 3),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Image.network(
                          user.avatarUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: textStyles.headlineMedium?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: textStyles.headlineMedium?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: textStyles.titleLarge?.copyWith(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    if (user.homeCity != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14,
                              color: Colors.black.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(user.homeCity!,
                              style: textStyles.bodySmall?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text('Level ${user.level}',
                                  style: textStyles.labelSmall?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full)),
                          child: Text(user.fitnessLevel.name.toUpperCase(),
                              style: textStyles.labelSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AnimatedCounter(
                        value: user.totalXp,
                        style: textStyles.labelMedium?.copyWith(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Text(' XP',
                          style: textStyles.labelMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${user.xpForNextLevel} XP to Level ${user.level + 1}',
                      style: textStyles.labelSmall?.copyWith(
                          color: Colors.black.withValues(alpha: 0.7))),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedGradientProgressBar(
                value: user.levelProgress,
                gradient: const LinearGradient(
                  colors: [Colors.black87, Colors.black],
                ),
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                height: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<ActivityModel> activities;
  final UserModel user;

  const _StatsSection({required this.activities, required this.user});

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final totalWorkouts =
        activities.where((a) => a.type == ActivityType.workout).length;
    final totalCalories =
        activities.fold(0, (sum, a) => sum + (a.caloriesBurned ?? 0));
    final totalMinutes =
        activities.fold(0, (sum, a) => sum + (a.durationMinutes ?? 0));
    final totalHours = (totalMinutes / 60).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Stats', style: textStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                value: '${user.currentStreak}',
                label: 'Day Streak',
                color: AppColors.warning,
                animatedValue: user.currentStreak,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                value: '$totalWorkouts',
                label: 'Workouts',
                color: AppColors.primary,
                animatedValue: totalWorkouts,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                value: '$totalCalories',
                label: 'Calories',
                color: AppColors.error,
                animatedValue: totalCalories,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer,
                value: '${totalHours}h',
                label: 'Active Time',
                color: AppColors.info,
                animatedValue: totalHours,
                suffix: 'h',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int? animatedValue;
  final String? suffix;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.animatedValue,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return PressableScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderGold, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (animatedValue != null)
                    AnimatedFormattedCounter(
                      value: animatedValue!,
                      suffix: suffix,
                      style: textStyles.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )
                  else
                    Text(value,
                        style: textStyles.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      style: textStyles.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  final List<BadgeModel> earnedBadges;
  final List<BadgeModel> allBadges;

  const _BadgesSection({required this.earnedBadges, required this.allBadges});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Badges', style: textStyles.titleMedium),
            Text('${earnedBadges.length}/${allBadges.length}',
                style: textStyles.labelMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110, // Increased height for better badge display
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isEarned = earnedBadges.any((b) => b.id == badge.id);
              return Padding(
                padding: EdgeInsets.only(
                    right: index < allBadges.length - 1 ? 12 : 0),
                child: _BadgeItem(badge: badge, isEarned: isEarned),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeItem({required this.badge, required this.isEarned});

  Color _getBadgeColor(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'place':
        return Icons.place;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  void _showBadgeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getBadgeColor(badge.tier).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getBadgeColor(badge.tier).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getBadgeColor(badge.tier).withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(badge.iconName),
                  color: _getBadgeColor(badge.tier),
                  size: 40,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: 300.ms)
                  .fadeIn(),
              const SizedBox(height: 20),
              // Badge Name
              Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              // Badge Description
              Text(
                badge.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
              const SizedBox(height: 20),
              // XP Reward
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldShimmer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      'Earn ${badge.xpReward} XP',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
              const SizedBox(height: 20),
              // Status Badge
              if (isEarned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Earned',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms).scale()
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Not Yet Earned',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms).scale(),
              const SizedBox(height: 20),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final badgeColor = _getBadgeColor(badge.tier);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => _showBadgeDetails(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Opacity(
          opacity: isEarned ? 1.0 : 0.4,
          child: Container(
            width: 80,
            height: 105, // Fixed height to prevent overflow
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: isEarned
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : colors.outline.withValues(alpha: 0.2),
                  width: isEarned ? 1.5 : 1),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(_getIconData(badge.iconName),
                      color: badgeColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(badge.name,
                    style: textStyles.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
