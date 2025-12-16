import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/user_service.dart';
import 'package:fittravel/services/activity_service.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/models/user_model.dart';
import 'package:fittravel/models/activity_model.dart';
import 'package:fittravel/models/badge_model.dart';
import 'package:fittravel/services/community_photo_service.dart';
import 'package:fittravel/services/review_service.dart';
import 'package:fittravel/models/review_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              child: _ContributionsSection(userId: user.id).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(_getIconData(badge.iconName), color: badgeColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(badge.name, style: textStyles.labelSmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final badgeColor = _getBadgeColor(badge.tier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 3)),
                  child: Icon(_getIconData(badge.iconName), color: badgeColor, size: 36),
                ),
                const SizedBox(height: 16),
                Text(badge.name, style: textStyles.titleLarge),
                const SizedBox(height: 8),
                Text(badge.description, style: textStyles.bodyMedium?.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.xp.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: AppColors.xp, size: 18),
                      const SizedBox(width: 4),
                      Text('+${badge.xpReward} XP', style: textStyles.labelLarge?.copyWith(color: AppColors.xp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(isEarned ? '✅ Earned!' : '🔒 Not yet earned', style: textStyles.labelMedium?.copyWith(color: isEarned ? AppColors.success : colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Settings', style: textStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            children: [
              _SettingsTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              _SettingsTile(icon: Icons.restaurant_menu, title: 'Dietary Preferences', onTap: () {}),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
              _SettingsTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: textStyles.bodyMedium)),
            Icon(Icons.chevron_right, color: colors.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ContributionsSection extends StatelessWidget {
  final String userId;
  const _ContributionsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final photoSvc = context.watch<CommunityPhotoService>();
    final reviewSvc = context.watch<ReviewService>();
    final myPhotos = photoSvc.photos.where((p) => p.userId == userId || p.userId == null).take(9).toList();
    final myReviews = reviewSvc.reviews.where((r) => r.userId == userId || r.userId == null).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Contributions', style: textStyles.titleMedium),
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
                children: [
                  Icon(Icons.photo_library_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Photos', style: textStyles.labelLarge),
                  const Spacer(),
                  Text('${myPhotos.length}', style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              if (myPhotos.isEmpty)
                Text('No photos yet', style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
                  itemCount: myPhotos.length,
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: _ProfilePhotoThumb(imageUrl: myPhotos[index].imageUrl),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.rate_review_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Reviews', style: textStyles.labelLarge),
                  const Spacer(),
                  Text('${myReviews.length}', style: textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              if (myReviews.isEmpty)
                Text('No reviews yet', style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant))
              else
                Column(children: myReviews.map((r) => _MiniReviewTile(review: r)).toList()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoThumb extends StatelessWidget {
  final String imageUrl;
  const _ProfilePhotoThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Data = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Container(color: colors.surfaceContainerHighest);
      }
    }
    return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: colors.surfaceContainerHighest));
  }
}

class _MiniReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _MiniReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.star, size: 14, color: AppColors.xp),
          const SizedBox(width: 4),
          Text('${review.rating}', style: textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (review.text ?? '').isEmpty ? 'No comment' : review.text!,
              style: textStyles.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

