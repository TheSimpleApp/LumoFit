import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';

class ActivityService extends ChangeNotifier {
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  ActivityService();

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
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        _activities = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user's activities from Supabase
      final activitiesData = await SupabaseConfig.client
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      _activities = (activitiesData as List)
          .map((json) => ActivityModel.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load activities';
      debugPrint('ActivityService.initialize error: $e');
      _activities = [];
    }

    _isLoading = false;
    notifyListeners();
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
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final xp = ActivityModel.calculateXp(type, durationMinutes);

    try {
      final data = {
        'user_id': userId,
        'trip_id': tripId,
        'activity_type': type.name,
        'place_id': placeId,
        'title': title,
        'description': description,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'xp_earned': xp,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseService.insert('activities', data);

      if (result.isNotEmpty) {
        final activity = ActivityModel.fromSupabaseJson(result.first);
        _activities.insert(0, activity);
        _error = null;
        notifyListeners();
        return activity;
      }
      throw Exception('Failed to log activity');
    } catch (e) {
      _error = 'Failed to log activity';
      debugPrint('ActivityService.logActivity error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await SupabaseService.delete('activities', filters: {'id': activityId});

      _activities.removeWhere((a) => a.id == activityId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete activity';
      debugPrint('ActivityService.deleteActivity error: $e');
      notifyListeners();
    }
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

  /// Clear local state (called on logout)
  void clearActivities() {
    _activities = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
