import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/models/challenge_model.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';

/// ChallengesScreen - Displays all user challenges organized by status
///
/// Shows a tabbed interface with:
/// - Active challenges (in-progress)
/// - Completed challenges (finished)
class ChallengesScreen extends StatefulWidget {
  /// Initial tab index: 0 = Active, 1 = Completed
  final int initialTab;

  const ChallengesScreen({super.key, this.initialTab = 0});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final gamificationService = context.watch<GamificationService>();
    final allUserChallenges = gamificationService.userChallenges;

    // Separate active and completed challenges
    final activeChallenges = allUserChallenges
        .where((uc) => !uc.isCompleted)
        .toList();
    final completedChallenges = allUserChallenges
        .where((uc) => uc.isCompleted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              labelStyle: textStyles.labelMedium,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag, size: 16),
                      const SizedBox(width: 6),
                      Text('Active (${activeChallenges.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 6),
                      Text('Completed (${completedChallenges.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Challenges Tab
                _ChallengeList(
                  challenges: activeChallenges,
                  gamificationService: gamificationService,
                  emptyState: EmptyStateWidget.challenges(
                    allCompleted: completedChallenges.isNotEmpty,
                    ctaLabel: completedChallenges.isNotEmpty
                        ? 'View Completed'
                        : null,
                    onCtaPressed: completedChallenges.isNotEmpty
                        ? () => _tabController.animateTo(1)
                        : null,
                  ),
                ),

                // Completed Challenges Tab
                _ChallengeList(
                  challenges: completedChallenges,
                  gamificationService: gamificationService,
                  isCompletedTab: true,
                  emptyState: EmptyStateWidget(
                    title: 'No completed challenges',
                    description:
                        'Complete challenges to earn XP and see them here.',
                    icon: Icons.emoji_events_outlined,
                    ctaLabel: activeChallenges.isNotEmpty
                        ? 'View Active Challenges'
                        : null,
                    onCtaPressed: activeChallenges.isNotEmpty
                        ? () => _tabController.animateTo(0)
                        : null,
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

/// Widget to display a list of challenges or an empty state
class _ChallengeList extends StatelessWidget {
  final List<UserChallengeModel> challenges;
  final GamificationService gamificationService;
  final Widget emptyState;
  final bool isCompletedTab;

  const _ChallengeList({
    required this.challenges,
    required this.gamificationService,
    required this.emptyState,
    this.isCompletedTab = false,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return emptyState;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final userChallenge = challenges[index];
        final challenge =
            gamificationService.getChallengeById(userChallenge.challengeId);

        if (challenge == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ChallengeTile(
            challenge: challenge,
            userChallenge: userChallenge,
            isCompleted: isCompletedTab,
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(
              begin: -0.05,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

/// Challenge tile widget - reused pattern from active_challenges.dart
class _ChallengeTile extends StatelessWidget {
  final ChallengeModel challenge;
  final UserChallengeModel userChallenge;
  final bool isCompleted;

  const _ChallengeTile({
    required this.challenge,
    required this.userChallenge,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final progress =
        (userChallenge.progress / challenge.requirementValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withValues(alpha: 0.08)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChallengeColor(challenge.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  challenge.typeLabel,
                  style: textStyles.labelSmall?.copyWith(
                    color: _getChallengeColor(challenge.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: textStyles.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: AppColors.xp, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '+${challenge.xpReward}',
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            challenge.title,
            style: textStyles.titleSmall?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? colors.onSurfaceVariant : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.outline.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? AppColors.success
                          : _getChallengeColor(challenge.type),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${userChallenge.progress}/${challenge.requirementValue}',
                style:
                    textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          // Show completion date for completed challenges
          if (isCompleted && userChallenge.completedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed ${_formatDate(userChallenge.completedAt!)}',
                  style: textStyles.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return AppColors.primary;
      case ChallengeType.weekly:
        return AppColors.warning;
      case ChallengeType.trip:
        return AppColors.info;
      case ChallengeType.special:
        return AppColors.xp;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
