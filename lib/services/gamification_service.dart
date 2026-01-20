import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';

class GamificationService extends ChangeNotifier {
  List<BadgeModel> _allBadges = [];
  List<UserBadgeModel> _userBadges = [];
  List<ChallengeModel> _allChallenges = [];
  List<UserChallengeModel> _userChallenges = [];
  bool _isLoading = false;
  String? _error;

  GamificationService();

  List<BadgeModel> get allBadges => _allBadges;
  List<UserBadgeModel> get userBadges => _userBadges;
  List<ChallengeModel> get allChallenges => _allChallenges;
  List<ChallengeModel> get activeChallenges =>
      _allChallenges.where((c) => c.isActive).toList();
  List<UserChallengeModel> get userChallenges => _userChallenges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load global badges (public read)
      final badgesData = await SupabaseConfig.client
          .from('badges')
          .select()
          .order('requirement_value');

      _allBadges = (badgesData as List)
          .map((json) => BadgeModel.fromSupabaseJson(json))
          .toList();

      // Load global challenges (public read)
      final challengesData = await SupabaseConfig.client
          .from('challenges')
          .select()
          .order('created_at');

      _allChallenges = (challengesData as List)
          .map((json) => ChallengeModel.fromSupabaseJson(json))
          .toList();

      // Load user-specific data if authenticated
      final userId = _currentUserId;
      if (userId != null) {
        // Load user badges
        final userBadgesData = await SupabaseConfig.client
            .from('user_badges')
            .select()
            .eq('user_id', userId);

        _userBadges = (userBadgesData as List)
            .map((json) => UserBadgeModel.fromSupabaseJson(json))
            .toList();

        // Load user challenges
        final userChallengesData = await SupabaseConfig.client
            .from('user_challenges')
            .select()
            .eq('user_id', userId);

        _userChallenges = (userChallengesData as List)
            .map((json) => UserChallengeModel.fromSupabaseJson(json))
            .toList();
      } else {
        _userBadges = [];
        _userChallenges = [];
      }
    } catch (e) {
      _error = 'Failed to load gamification data';
      debugPrint('GamificationService.initialize error: $e');
      _allBadges = [];
      _allChallenges = [];
      _userBadges = [];
      _userChallenges = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  bool hasBadge(String badgeId) {
    return _userBadges.any((ub) => ub.badgeId == badgeId);
  }

  BadgeModel? getBadgeById(String badgeId) {
    try {
      return _allBadges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  ChallengeModel? getChallengeById(String challengeId) {
    try {
      return _allChallenges.firstWhere((c) => c.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  UserChallengeModel? getUserChallenge(String challengeId) {
    try {
      return _userChallenges.firstWhere((uc) => uc.challengeId == challengeId);
    } catch (e) {
      return null;
    }
  }

  List<BadgeModel> getEarnedBadges() {
    return _userBadges
        .map((ub) => getBadgeById(ub.badgeId))
        .whereType<BadgeModel>()
        .toList();
  }

  List<BadgeModel> getUnearnedBadges() {
    final earnedIds = _userBadges.map((ub) => ub.badgeId).toSet();
    return _allBadges.where((b) => !earnedIds.contains(b.id)).toList();
  }

  Future<void> awardBadge(String badgeId) async {
    if (hasBadge(badgeId)) return;

    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final data = {
        'user_id': userId,
        'badge_id': badgeId,
        'earned_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseService.insert('user_badges', data);

      if (result.isNotEmpty) {
        final userBadge = UserBadgeModel.fromSupabaseJson(result.first);
        _userBadges.add(userBadge);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to award badge';
      debugPrint('GamificationService.awardBadge error: $e');
      notifyListeners();
    }
  }

  /// Check XP milestone badges against the provided total XP and award any missed ones.
  Future<void> checkXpBadges(int totalXp) async {
    try {
      final xpBadges =
          _allBadges.where((b) => b.requirementType == BadgeRequirementType.xp);
      for (final b in xpBadges) {
        if (totalXp >= b.requirementValue && !hasBadge(b.id)) {
          await awardBadge(b.id);
        }
      }
    } catch (e) {
      debugPrint('GamificationService.checkXpBadges error: $e');
    }
  }

  /// Check visit-count badges and award if thresholds are met.
  Future<void> checkVisitBadges(int visitedCount) async {
    try {
      final visitBadges = _allBadges
          .where((b) => b.requirementType == BadgeRequirementType.visits);
      for (final b in visitBadges) {
        if (visitedCount >= b.requirementValue && !hasBadge(b.id)) {
          await awardBadge(b.id);
        }
      }
    } catch (e) {
      debugPrint('GamificationService.checkVisitBadges error: $e');
    }
  }

  /// Check streak badges and award if thresholds are met.
  Future<void> checkStreakBadges(int currentStreak) async {
    try {
      final streakBadges = _allBadges
          .where((b) => b.requirementType == BadgeRequirementType.streak);
      for (final b in streakBadges) {
        if (currentStreak >= b.requirementValue && !hasBadge(b.id)) {
          await awardBadge(b.id);
        }
      }
    } catch (e) {
      debugPrint('GamificationService.checkStreakBadges error: $e');
    }
  }

  /// Check activity count badges and award if thresholds are met.
  Future<void> checkActivityBadges(int activityCount) async {
    try {
      final activityBadges = _allBadges
          .where((b) => b.requirementType == BadgeRequirementType.activities);
      for (final b in activityBadges) {
        if (activityCount >= b.requirementValue && !hasBadge(b.id)) {
          await awardBadge(b.id);
        }
      }
    } catch (e) {
      debugPrint('GamificationService.checkActivityBadges error: $e');
    }
  }

  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index =
        _userChallenges.indexWhere((uc) => uc.challengeId == challengeId);

    if (index >= 0) {
      // Update existing user challenge
      final challenge = getChallengeById(challengeId);
      final isCompleted =
          challenge != null && progress >= challenge.requirementValue;

      try {
        await SupabaseConfig.client.from('user_challenges').update({
          'progress': progress,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        }).eq('id', _userChallenges[index].id);

        _userChallenges[index] = _userChallenges[index].copyWith(
          progress: progress,
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
        _error = null;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to update challenge progress';
        debugPrint('GamificationService.updateChallengeProgress error: $e');
        notifyListeners();
      }
    } else {
      // Create new user challenge entry
      final challenge = getChallengeById(challengeId);
      final isCompleted =
          challenge != null && progress >= challenge.requirementValue;

      try {
        final data = {
          'user_id': userId,
          'challenge_id': challengeId,
          'progress': progress,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        };

        final result = await SupabaseService.insert('user_challenges', data);

        if (result.isNotEmpty) {
          final userChallenge =
              UserChallengeModel.fromSupabaseJson(result.first);
          _userChallenges.add(userChallenge);
          _error = null;
          notifyListeners();
        }
      } catch (e) {
        _error = 'Failed to create challenge progress';
        debugPrint('GamificationService.updateChallengeProgress error: $e');
        notifyListeners();
      }
    }
  }

  double getChallengeProgress(String challengeId) {
    final userChallenge = getUserChallenge(challengeId);
    final challenge = getChallengeById(challengeId);
    if (userChallenge == null || challenge == null) return 0;
    return (userChallenge.progress / challenge.requirementValue)
        .clamp(0.0, 1.0);
  }

  /// Clear local state (called on logout)
  void clearGamification() {
    _userBadges = [];
    _userChallenges = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
