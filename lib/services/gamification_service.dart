import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

class GamificationService extends ChangeNotifier {
  final StorageService _storage;
  List<BadgeModel> _allBadges = [];
  List<UserBadgeModel> _userBadges = [];
  List<ChallengeModel> _allChallenges = [];
  List<UserChallengeModel> _userChallenges = [];
  bool _isLoading = false;

  GamificationService(this._storage);

  List<BadgeModel> get allBadges => _allBadges;
  List<UserBadgeModel> get userBadges => _userBadges;
  List<ChallengeModel> get allChallenges => _allChallenges;
  List<ChallengeModel> get activeChallenges => _allChallenges.where((c) => c.isActive).toList();
  List<UserChallengeModel> get userChallenges => _userChallenges;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load badges
      final badgesJson = _storage.getJsonList(StorageKeys.allBadges);
      if (badgesJson != null && badgesJson.isNotEmpty) {
        _allBadges = badgesJson.map((j) => BadgeModel.fromJson(j)).toList();
      } else {
        _loadDefaultBadges();
      }

      // Load user badges
      final userBadgesJson = _storage.getJsonList(StorageKeys.userBadges);
      if (userBadgesJson != null) {
        _userBadges = userBadgesJson.map((j) => UserBadgeModel.fromJson(j)).toList();
      }

      // Load challenges
      final challengesJson = _storage.getJsonList(StorageKeys.allChallenges);
      if (challengesJson != null && challengesJson.isNotEmpty) {
        _allChallenges = challengesJson.map((j) => ChallengeModel.fromJson(j)).toList();
      } else {
        _loadDefaultChallenges();
      }

      // Load user challenges
      final userChallengesJson = _storage.getJsonList(StorageKeys.userChallenges);
      if (userChallengesJson != null) {
        _userChallenges = userChallengesJson.map((j) => UserChallengeModel.fromJson(j)).toList();
      } else {
        _assignDefaultChallenges();
      }

      await _saveAll();
    } catch (e) {
      debugPrint('GamificationService.initialize error: $e');
      _loadDefaultBadges();
      _loadDefaultChallenges();
      _assignDefaultChallenges();
      await _saveAll();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadDefaultBadges() {
    _allBadges = [
      // Streak badges
      BadgeModel(
        id: 'badge-streak-3',
        name: 'Getting Started',
        description: 'Maintain a 3-day activity streak',
        iconName: 'local_fire_department',
        xpReward: 50,
        requirementType: BadgeRequirementType.streak,
        requirementValue: 3,
        tier: 'bronze',
      ),
      BadgeModel(
        id: 'badge-streak-7',
        name: 'Week Warrior',
        description: 'Maintain a 7-day activity streak',
        iconName: 'local_fire_department',
        xpReward: 150,
        requirementType: BadgeRequirementType.streak,
        requirementValue: 7,
        tier: 'silver',
      ),
      BadgeModel(
        id: 'badge-streak-30',
        name: 'Monthly Master',
        description: 'Maintain a 30-day activity streak',
        iconName: 'local_fire_department',
        xpReward: 500,
        requirementType: BadgeRequirementType.streak,
        requirementValue: 30,
        tier: 'gold',
      ),
      // Activity badges
      BadgeModel(
        id: 'badge-activities-10',
        name: 'Active Explorer',
        description: 'Complete 10 activities',
        iconName: 'fitness_center',
        xpReward: 100,
        requirementType: BadgeRequirementType.activities,
        requirementValue: 10,
        tier: 'bronze',
      ),
      BadgeModel(
        id: 'badge-activities-50',
        name: 'Fitness Enthusiast',
        description: 'Complete 50 activities',
        iconName: 'fitness_center',
        xpReward: 300,
        requirementType: BadgeRequirementType.activities,
        requirementValue: 50,
        tier: 'silver',
      ),
      BadgeModel(
        id: 'badge-activities-100',
        name: 'Fitness Champion',
        description: 'Complete 100 activities',
        iconName: 'fitness_center',
        xpReward: 750,
        requirementType: BadgeRequirementType.activities,
        requirementValue: 100,
        tier: 'gold',
      ),
      // Visit badges
      BadgeModel(
        id: 'badge-visits-5',
        name: 'Gym Hopper',
        description: 'Visit 5 different gyms',
        iconName: 'place',
        xpReward: 100,
        requirementType: BadgeRequirementType.visits,
        requirementValue: 5,
        tier: 'bronze',
      ),
      BadgeModel(
        id: 'badge-visits-15',
        name: 'Place Explorer',
        description: 'Visit 15 fitness spots',
        iconName: 'place',
        xpReward: 250,
        requirementType: BadgeRequirementType.visits,
        requirementValue: 15,
        tier: 'silver',
      ),
      // XP badges
      BadgeModel(
        id: 'badge-xp-1000',
        name: 'Rising Star',
        description: 'Earn 1,000 XP',
        iconName: 'star',
        xpReward: 100,
        requirementType: BadgeRequirementType.xp,
        requirementValue: 1000,
        tier: 'bronze',
      ),
      BadgeModel(
        id: 'badge-xp-5000',
        name: 'XP Hunter',
        description: 'Earn 5,000 XP',
        iconName: 'star',
        xpReward: 300,
        requirementType: BadgeRequirementType.xp,
        requirementValue: 5000,
        tier: 'silver',
      ),
      BadgeModel(
        id: 'badge-xp-10000',
        name: 'Legend',
        description: 'Earn 10,000 XP',
        iconName: 'star',
        xpReward: 1000,
        requirementType: BadgeRequirementType.xp,
        requirementValue: 10000,
        tier: 'gold',
      ),
    ];
  }

  void _loadDefaultChallenges() {
    _allChallenges = [
      ChallengeModel(
        id: 'challenge-daily-workout',
        title: 'Daily Workout',
        description: 'Complete at least one workout today',
        type: ChallengeType.daily,
        xpReward: 30,
        requirementType: 'workouts',
        requirementValue: 1,
        iconName: 'fitness_center',
      ),
      ChallengeModel(
        id: 'challenge-daily-meal',
        title: 'Eat Clean',
        description: 'Log a healthy meal today',
        type: ChallengeType.daily,
        xpReward: 15,
        requirementType: 'meals',
        requirementValue: 1,
        iconName: 'restaurant',
      ),
      ChallengeModel(
        id: 'challenge-weekly-5workouts',
        title: 'Weekly Warrior',
        description: 'Complete 5 workouts this week',
        type: ChallengeType.weekly,
        xpReward: 150,
        requirementType: 'workouts',
        requirementValue: 5,
        iconName: 'emoji_events',
      ),
      ChallengeModel(
        id: 'challenge-weekly-explore',
        title: 'Explorer',
        description: 'Visit 3 different fitness locations this week',
        type: ChallengeType.weekly,
        xpReward: 100,
        requirementType: 'visits',
        requirementValue: 3,
        iconName: 'explore',
      ),
      ChallengeModel(
        id: 'challenge-trip-gym',
        title: 'Trip Gym Finder',
        description: 'Visit a gym during your trip',
        type: ChallengeType.trip,
        xpReward: 75,
        requirementType: 'gym_visits',
        requirementValue: 1,
        iconName: 'fitness_center',
      ),
    ];
  }

  void _assignDefaultChallenges() {
    _userChallenges = [
      UserChallengeModel(
        id: const Uuid().v4(),
        odId: 'sample-user',
        challengeId: 'challenge-daily-workout',
        progress: 1,
        isCompleted: true,
        completedAt: DateTime.now(),
      ),
      UserChallengeModel(
        id: const Uuid().v4(),
        odId: 'sample-user',
        challengeId: 'challenge-daily-meal',
        progress: 0,
      ),
      UserChallengeModel(
        id: const Uuid().v4(),
        odId: 'sample-user',
        challengeId: 'challenge-weekly-5workouts',
        progress: 3,
      ),
      UserChallengeModel(
        id: const Uuid().v4(),
        odId: 'sample-user',
        challengeId: 'challenge-weekly-explore',
        progress: 1,
      ),
    ];
  }

  Future<void> _saveAll() async {
    await _storage.setJsonList(
      StorageKeys.allBadges,
      _allBadges.map((b) => b.toJson()).toList(),
    );
    await _storage.setJsonList(
      StorageKeys.userBadges,
      _userBadges.map((b) => b.toJson()).toList(),
    );
    await _storage.setJsonList(
      StorageKeys.allChallenges,
      _allChallenges.map((c) => c.toJson()).toList(),
    );
    await _storage.setJsonList(
      StorageKeys.userChallenges,
      _userChallenges.map((c) => c.toJson()).toList(),
    );
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
    return _userBadges.map((ub) => getBadgeById(ub.badgeId)).whereType<BadgeModel>().toList();
  }

  List<BadgeModel> getUnearnedBadges() {
    final earnedIds = _userBadges.map((ub) => ub.badgeId).toSet();
    return _allBadges.where((b) => !earnedIds.contains(b.id)).toList();
  }

  Future<void> awardBadge(String badgeId) async {
    if (hasBadge(badgeId)) return;
    
    final userBadge = UserBadgeModel(
      id: const Uuid().v4(),
      odId: 'sample-user',
      badgeId: badgeId,
    );
    _userBadges.add(userBadge);
    await _saveAll();
    notifyListeners();
  }

  /// Check XP milestone badges against the provided total XP and award any missed ones.
  Future<void> checkXpBadges(int totalXp) async {
    try {
      final xpBadges = _allBadges.where((b) => b.requirementType == BadgeRequirementType.xp);
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
      final visitBadges = _allBadges.where((b) => b.requirementType == BadgeRequirementType.visits);
      for (final b in visitBadges) {
        if (visitedCount >= b.requirementValue && !hasBadge(b.id)) {
          await awardBadge(b.id);
        }
      }
    } catch (e) {
      debugPrint('GamificationService.checkVisitBadges error: $e');
    }
  }

  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    final index = _userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
    if (index >= 0) {
      final challenge = getChallengeById(challengeId);
      final isCompleted = challenge != null && progress >= challenge.requirementValue;
      
      _userChallenges[index] = _userChallenges[index].copyWith(
        progress: progress,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );
      await _saveAll();
      notifyListeners();
    }
  }

  double getChallengeProgress(String challengeId) {
    final userChallenge = getUserChallenge(challengeId);
    final challenge = getChallengeById(challengeId);
    if (userChallenge == null || challenge == null) return 0;
    return (userChallenge.progress / challenge.requirementValue).clamp(0.0, 1.0);
  }
}
