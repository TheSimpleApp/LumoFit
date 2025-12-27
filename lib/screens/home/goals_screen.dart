import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/user_service.dart';

/// Goals Screen - Shows user fitness goals and achievements
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final user = userService.currentUser;
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.goldShimmer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    '${user?.currentStreak ?? 0} Day Streak',
                    style: textStyles.headlineMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personal Best: ${user?.longestStreak ?? 0} days',
                    style: textStyles.bodyLarge?.copyWith(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 24),

            // XP Progress Section
            Text(
              'Experience Points',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: AppColors.xp, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '${user?.totalXp ?? 0} XP',
                            style: textStyles.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldShimmer,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'Level ${user?.level ?? 1}',
                          style: textStyles.labelLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress to next level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress to Level ${(user?.level ?? 1) + 1}',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${_getXpProgress(user?.totalXp ?? 0)}%',
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _getXpProgress(user?.totalXp ?? 0) / 100,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.xp),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Goals Section
            Text(
              'Daily Goals',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            _GoalCard(
              icon: Icons.fitness_center,
              title: 'Visit a Gym',
              description: 'Check in at any gym today',
              isCompleted: false,
              xpReward: 50,
            ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),
            _GoalCard(
              icon: Icons.restaurant,
              title: 'Healthy Meal',
              description: 'Log a healthy restaurant visit',
              isCompleted: false,
              xpReward: 30,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),
            _GoalCard(
              icon: Icons.directions_run,
              title: 'Outdoor Activity',
              description: 'Visit a trail or park',
              isCompleted: false,
              xpReward: 40,
            ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),
            _GoalCard(
              icon: Icons.camera_alt,
              title: 'Log Activity',
              description: 'Take a photo of your workout',
              isCompleted: false,
              xpReward: 20,
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

            // Achievements Section
            Text(
              'Achievements',
              style: textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _AchievementBadge(
                  emoji: '🏃',
                  title: 'First Run',
                  isUnlocked: true,
                ),
                _AchievementBadge(
                  emoji: '💪',
                  title: 'Gym Rat',
                  isUnlocked: (user?.totalXp ?? 0) >= 100,
                ),
                _AchievementBadge(
                  emoji: '🔥',
                  title: '7 Day Streak',
                  isUnlocked: (user?.longestStreak ?? 0) >= 7,
                ),
                _AchievementBadge(
                  emoji: '🌟',
                  title: 'Level 5',
                  isUnlocked: (user?.level ?? 1) >= 5,
                ),
                _AchievementBadge(
                  emoji: '🗺️',
                  title: 'Explorer',
                  isUnlocked: false,
                ),
                _AchievementBadge(
                  emoji: '🏆',
                  title: 'Champion',
                  isUnlocked: false,
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  int _getXpProgress(int totalXp) {
    // Simple level calculation: 100 XP per level
    final xpInCurrentLevel = totalXp % 100;
    return xpInCurrentLevel;
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompleted;
  final int xpReward;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.xpReward,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
              : colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.2)
                  : colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? AppColors.success : colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.xp.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 14, color: AppColors.xp),
                const SizedBox(width: 4),
                Text(
                  '+$xpReward',
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
}

class _AchievementBadge extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.emoji,
    required this.title,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? colors.primaryContainer.withValues(alpha: 0.5)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnlocked
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textStyles.labelSmall?.copyWith(
              color: isUnlocked ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
