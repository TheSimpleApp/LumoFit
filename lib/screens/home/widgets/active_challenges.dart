import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/services/gamification_service.dart';
import 'package:fittravel/models/challenge_model.dart';
import 'package:fittravel/widgets/empty_state_widget.dart';

class ActiveChallenges extends StatelessWidget {
  const ActiveChallenges({super.key});

  @override
  Widget build(BuildContext context) {
    final gamificationService = context.watch<GamificationService>();
    final allUserChallenges = gamificationService.userChallenges;
    final activeChallenges =
        allUserChallenges.where((uc) => !uc.isCompleted).take(3).toList();
    final textStyles = Theme.of(context).textTheme;

    // Determine if user has completed challenges vs no challenges at all
    final hasCompletedChallenges =
        allUserChallenges.any((uc) => uc.isCompleted);
    final allCompleted = activeChallenges.isEmpty && hasCompletedChallenges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Challenges', style: textStyles.titleMedium),
            TextButton(
                onPressed: () => context.push('/challenges'),
                child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 8),
        if (activeChallenges.isEmpty)
          EmptyStateWidget.challenges(
            allCompleted: allCompleted,
            ctaLabel: allCompleted ? 'View Completed' : null,
            onCtaPressed: allCompleted
                ? () => context.push('/challenges?tab=completed')
                : null,
          )
        else
          ...activeChallenges.map((uc) {
            final challenge =
                gamificationService.getChallengeById(uc.challengeId);
            if (challenge == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChallengeTile(challenge: challenge, userChallenge: uc),
            );
          }),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final ChallengeModel challenge;
  final UserChallengeModel userChallenge;

  const _ChallengeTile({required this.challenge, required this.userChallenge});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final progress =
        (userChallenge.progress / challenge.requirementValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: colors.outline.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChallengeColor(challenge.type)
                      .withValues(alpha: 0.15),
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
          Text(challenge.title, style: textStyles.titleSmall),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style:
                textStyles.bodySmall?.copyWith(color: colors.onSurfaceVariant),
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
                        _getChallengeColor(challenge.type)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${userChallenge.progress}/${challenge.requirementValue}',
                style: textStyles.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
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
}
