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

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _BadgesSection(earnedBadges: gamificationService.getEarnedBadges(), allBadges: gamificationService.allBadges).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _QuickAddedPhotosSection(userId: user.id).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _ContributionsSection(userId: user.id).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: const _StravaSection().animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _QuickSettings().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final badgeColor = _getBadgeColor(badge.tier);

    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: isEarned ? badgeColor.withValues(alpha: 0.5) : colors.outline.withValues(alpha: 0.1), width: isEarned ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getIconData(badge.iconName), color: badgeColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(badge.name, style: textStyles.labelSmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: _getBadgeColor(badge.tier).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getIconData(badge.iconName), color: _getBadgeColor(badge.tier), size: 40),
            ),
            const SizedBox(height: 16),
            Text(badge.description),
            const SizedBox(height: 8),
            Text('Tier: ${badge.tier.toUpperCase()}', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _QuickAddedPhotosSection extends StatelessWidget {
  final String userId;

  const _QuickAddedPhotosSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<QuickPhotoService>().getPhotosByUserId(userId),
      builder: (context, snapshot) {
        final textStyles = Theme.of(context).textTheme;
        final colors = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.photo_camera_back,
            title: 'No Photos Yet',
            description: 'Start adding photos to your quick gallery',
            actionLabel: 'Add Photo',
            onAction: () {},
          );
        }

        final photos = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recently Added Photos', style: textStyles.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < photos.length - 1 ? 12 : 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.network(
                          photos[index]['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.image_not_supported, color: colors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContributionsSection extends StatelessWidget {
  final String userId;

  const _ContributionsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<CommunityPhotoService>().getPhotosByUserId(userId),
      builder: (context, snapshot) {
        final textStyles = Theme.of(context).textTheme;
        final colors = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.public,
            title: 'No Contributions Yet',
            description: 'Share your photos with the community',
            actionLabel: 'Contribute',
            onAction: () {},
          );
        }

        final photos = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Community Contributions', style: textStyles.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < photos.length - 1 ? 12 : 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.network(
                          photos[index]['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.image_not_supported, color: colors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StravaSection extends StatelessWidget {
  const _StravaSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final stravaService = context.watch<StravaService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strava Integration', style: textStyles.titleMedium),
        const SizedBox(height: 12),
        if (stravaService.isConnected)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Connected', style: textStyles.bodyMedium?.copyWith(color: Colors.green)),
                    ElevatedButton(
                      onPressed: () => stravaService.disconnect(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          EmptyStateWidget(
            icon: Icons.fitness_center,
            title: 'Connect Strava',
            description: 'Sync your Strava activities to FitTravel',
            actionLabel: 'Connect Now',
            onAction: () => stravaService.authenticate(),
          ),
      ],
    );
  }
}

class _QuickSettings extends StatelessWidget {
  const _QuickSettings();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final userService = context.watch<UserService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Settings', style: textStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: textStyles.bodyMedium),
                  Switch(
                    value: userService.currentUser?.notificationsEnabled ?? false,
                    onChanged: (value) => userService.updateNotifications(value),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Private Profile', style: textStyles.bodyMedium),
                  Switch(
                    value: userService.currentUser?.isPrivate ?? false,
                    onChanged: (value) => userService.updatePrivacy(value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}