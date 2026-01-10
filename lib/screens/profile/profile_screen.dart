import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fittravel/supabase/supabase_config.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/services/activity_service.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/services/strava_service.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/models/activity_model.dart';
import 'package:fittravel/models/badge_model.dart';
import 'package:fittravel/services/community_photo_service.dart';
import 'package:fittravel/services/review_service.dart';
import 'package:fittravel/models/review_model.dart';
import 'package:fittravel/services/quick_photo_service.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';
import 'package:fittravel/screens/profile/profile_skeleton.dart';

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
                      Expanded(child: Text('Profile', style: textStyles.headlineMedium).animate().fadeIn().slideX(begin: -0.1)),
                      IconButton(onPressed: () => _showSettings(context), icon: const Icon(Icons.settings_outlined)).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _ProfileCard(user: user).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _StatsSection(activities: activityService.activities, user: user).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _BadgesSection(earnedBadges: gamificationService.getEarnedBadges(), allBadges: gamificationService.allBadges).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon!'), behavior: SnackBarBehavior.floating));
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
      decoration: BoxDecoration(gradient: AppColors.goldShimmer, borderRadius: BorderRadius.circular(AppRadius.xl)),
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
                  border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 3),
                ),
                child: Center(
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: textStyles.headlineMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: textStyles.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                    if (user.homeCity != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.black.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(user.homeCity!, style: textStyles.bodySmall?.copyWith(color: Colors.black.withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.full)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text('Level ${user.level}', style: textStyles.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppRadius.full)),
                          child: Text(user.fitnessLevel.name.toUpperCase(), style: textStyles.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w600)),
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
                  Text('${user.totalXp} XP', style: textStyles.labelMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text('${user.xpForNextLevel} XP to Level ${user.level + 1}', style: textStyles.labelSmall?.copyWith(color: Colors.black.withValues(alpha: 0.7))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: user.levelProgress,
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  minHeight: 8,
                ),
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

  String _formatNumber(int number) => number >= 1000 ? '${(number / 1000).toStringAsFixed(1)}k' : number.toString();

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final totalWorkouts = activities.where((a) => a.type == ActivityType.workout).length;
    final totalCalories = activities.fold(0, (sum, a) => sum + (a.caloriesBurned ?? 0));
    final totalMinutes = activities.fold(0, (sum, a) => sum + (a.durationMinutes ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Stats', style: textStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.local_fire_department, value: '${user.currentStreak}', label: 'Day Streak', color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.fitness_center, value: '$totalWorkouts', label: 'Workouts', color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.local_fire_department, value: _formatNumber(totalCalories), label: 'Calories', color: AppColors.error)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.timer, value: '${(totalMinutes / 60).floor()}h', label: 'Active Time', color: AppColors.info)),
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

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
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
            Text('${earnedBadges.length}/${allBadges.length}', style: textStyles.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isEarned = earnedBadges.any((b) => b.id == badge.id);
              return Padding(
                padding: EdgeInsets.only(right: index < allBadges.length - 1 ? 12 : 0),
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
      case 'gold': return const Color(0xFFFFD700);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'bronze': default: return const Color(0xFFCD7F32);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department': return Icons.local_fire_department;
      case 'fitness_center': return Icons.fitness_center;
      case 'place': return Icons.place;
      case 'star': return Icons.star;
      default: return Icons.emoji_events;
    }
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(badge.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: isEarned ? badgeColor.withValues(alpha: 0.5) : colors.outline.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(_getIconData(badge.iconName), color: badgeColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(badge.name, style: textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}