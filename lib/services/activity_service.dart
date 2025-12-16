import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

class ActivityService extends ChangeNotifier {
  final StorageService _storage;
  List<ActivityModel> _activities = [];
  bool _isLoading = false;

  ActivityService(this._storage);

  List<ActivityModel> get activities => _activities;
  List<ActivityModel> get todayActivities {
    final today = DateTime.now();
    return _activities.where((a) {
      return a.completedAt.year == today.year &&
          a.completedAt.month == today.month &&
          a.completedAt.day == today.day;
    }).toList();
  }
  List<ActivityModel> get thisWeekActivities {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _activities.where((a) => a.completedAt.isAfter(weekStart)).toList();
  }
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonList = _storage.getJsonList(StorageKeys.activities);
      if (jsonList != null && jsonList.isNotEmpty) {
        _activities = jsonList.map((j) => ActivityModel.fromJson(j)).toList();
      } else {
        await _loadSampleData();
      }
    } catch (e) {
      debugPrint('ActivityService.initialize error: $e');
      await _loadSampleData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSampleData() async {
    final now = DateTime.now();
    _activities = [
      ActivityModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        type: ActivityType.workout,
        title: 'Morning Gym Session',
        description: 'Full body workout at Vasa Fitness',
        durationMinutes: 60,
        caloriesBurned: 450,
        xpEarned: 80,
        completedAt: now.subtract(const Duration(hours: 4)),
      ),
      ActivityModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        type: ActivityType.meal,
        title: 'Healthy Lunch',
        description: 'Grilled chicken salad at Cafe Zupas',
        xpEarned: 20,
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
      ActivityModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        type: ActivityType.walk,
        title: 'Evening Walk',
        description: 'Walk around Liberty Park',
        durationMinutes: 30,
        caloriesBurned: 150,
        xpEarned: 25,
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      ActivityModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        type: ActivityType.hike,
        title: 'Ensign Peak Hike',
        description: 'Morning hike with city views',
        durationMinutes: 90,
        caloriesBurned: 600,
        xpEarned: 110,
        completedAt: now.subtract(const Duration(days: 2)),
      ),
      ActivityModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        type: ActivityType.yoga,
        title: 'Hotel Room Yoga',
        description: '20 min morning stretch',
        durationMinutes: 20,
        caloriesBurned: 80,
        xpEarned: 35,
        completedAt: now.subtract(const Duration(days: 2, hours: 10)),
      ),
    ];
    await _saveActivities();
  }

  Future<void> _saveActivities() async {
    final jsonList = _activities.map((a) => a.toJson()).toList();
    await _storage.setJsonList(StorageKeys.activities, jsonList);
  }

  Future<ActivityModel> logActivity({
    required ActivityType type,
    required String title,
    String? description,
    String? tripId,
    String? placeId,
    int? durationMinutes,
    int? caloriesBurned,
  }) async {
    final xp = ActivityModel.calculateXp(type, durationMinutes);
    final activity = ActivityModel(
      id: const Uuid().v4(),
      userId: 'sample-user',
      tripId: tripId,
      type: type,
      placeId: placeId,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      xpEarned: xp,
    );
    
    _activities.insert(0, activity);
    await _saveActivities();
    notifyListeners();
    return activity;
  }

  Future<void> deleteActivity(String activityId) async {
    _activities.removeWhere((a) => a.id == activityId);
    await _saveActivities();
    notifyListeners();
  }

  List<ActivityModel> getActivitiesByTrip(String tripId) {
    return _activities.where((a) => a.tripId == tripId).toList();
  }

  List<ActivityModel> getActivitiesByType(ActivityType type) {
    return _activities.where((a) => a.type == type).toList();
  }

  int getTotalXpEarned() {
    return _activities.fold(0, (sum, a) => sum + a.xpEarned);
  }

  int getTotalCaloriesBurned() {
    return _activities.fold(0, (sum, a) => sum + (a.caloriesBurned ?? 0));
  }

  int getTotalDurationMinutes() {
    return _activities.fold(0, (sum, a) => sum + (a.durationMinutes ?? 0));
  }

  Map<ActivityType, int> getActivityCounts() {
    final counts = <ActivityType, int>{};
    for (final a in _activities) {
      counts[a.type] = (counts[a.type] ?? 0) + 1;
    }
    return counts;
  }
}
