import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage
class StorageKeys {
  static const String userProfile = 'user_profile';
  static const String savedPlaces = 'saved_places';
  static const String trips = 'trips';
  static const String activities = 'activities';
  static const String userBadges = 'user_badges';
  static const String userChallenges = 'user_challenges';
  static const String streakData = 'streak_data';
  static const String lastActiveDate = 'last_active_date';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String allBadges = 'all_badges';
  static const String allChallenges = 'all_challenges';
  static const String tripItineraries = 'trip_itineraries';
  static const String communityPhotos = 'community_photos';
  static const String quickPhotos = 'quick_photos';
  static const String reviews = 'reviews';
  static const String events = 'events';
  static const String feedbackItems = 'feedback_items';
}

/// Wrapper service for SharedPreferences
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      debugPrint('StorageService.setString error: $e');
      return false;
    }
  }

  String? getString(String key) {
    try {
      return _prefs!.getString(key);
    } catch (e) {
      debugPrint('StorageService.getString error: $e');
      return null;
    }
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs!.setStringList(key, value);
    } catch (e) {
      debugPrint('StorageService.setStringList error: $e');
      return false;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return _prefs!.getStringList(key);
    } catch (e) {
      debugPrint('StorageService.getStringList error: $e');
      return null;
    }
  }

  // JSON operations
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      return await _prefs!.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('StorageService.setJson error: $e');
      return false;
    }
  }

  Map<String, dynamic>? getJson(String key) {
    try {
      final String? value = _prefs!.getString(key);
      if (value == null) return null;
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('StorageService.getJson error: $e');
      return null;
    }
  }

  // JSON List operations
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      final List<String> stringList = value.map((e) => jsonEncode(e)).toList();
      return await _prefs!.setStringList(key, stringList);
    } catch (e) {
      debugPrint('StorageService.setJsonList error: $e');
      return false;
    }
  }

  List<Map<String, dynamic>>? getJsonList(String key) {
    try {
      final List<String>? stringList = _prefs!.getStringList(key);
      if (stringList == null) return null;
      
      final List<Map<String, dynamic>> result = [];
      for (final s in stringList) {
        try {
          result.add(jsonDecode(s) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('StorageService: Skipping corrupted entry in $key');
        }
      }
      return result;
    } catch (e) {
      debugPrint('StorageService.getJsonList error: $e');
      return null;
    }
  }

  // Boolean operations
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      debugPrint('StorageService.setBool error: $e');
      return false;
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs!.getBool(key);
    } catch (e) {
      debugPrint('StorageService.getBool error: $e');
      return null;
    }
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs!.setInt(key, value);
    } catch (e) {
      debugPrint('StorageService.setInt error: $e');
      return false;
    }
  }

  int? getInt(String key) {
    try {
      return _prefs!.getInt(key);
    } catch (e) {
      debugPrint('StorageService.getInt error: $e');
      return null;
    }
  }

  // Remove
  Future<bool> remove(String key) async {
    try {
      return await _prefs!.remove(key);
    } catch (e) {
      debugPrint('StorageService.remove error: $e');
      return false;
    }
  }

  // Clear all
  Future<bool> clear() async {
    try {
      return await _prefs!.clear();
    } catch (e) {
      debugPrint('StorageService.clear error: $e');
      return false;
    }
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }
}
