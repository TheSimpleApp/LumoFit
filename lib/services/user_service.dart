import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

class UserService extends ChangeNotifier {
  final StorageService _storage;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserService(this._storage);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasUser => _currentUser != null;

  /// Initialize the service - load user from storage or create default
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final json = _storage.getJson(StorageKeys.userProfile);
      if (json != null) {
        _currentUser = UserModel.fromJson(json);
      } else {
        // Create default sample user
        await _createSampleUser();
      }
    } catch (e) {
      debugPrint('UserService.initialize error: $e');
      await _createSampleUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createSampleUser() async {
    _currentUser = UserModel(
      id: const Uuid().v4(),
      displayName: 'Fit Traveler',
      email: 'traveler@fittravel.app',
      homeCity: 'Salt Lake City, UT',
      fitnessLevel: FitnessLevel.intermediate,
      dietaryPreferences: ['High Protein', 'Low Carb'],
      currentStreak: 7,
      longestStreak: 14,
      totalXp: 2450,
    );
    await _saveUser();
  }

  Future<void> _saveUser() async {
    if (_currentUser == null) return;
    await _storage.setJson(StorageKeys.userProfile, _currentUser!.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    _currentUser = user.copyWith(updatedAt: DateTime.now());
    await _saveUser();
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(displayName: name);
    await _saveUser();
    notifyListeners();
  }

  Future<void> updateHomeCity(String city) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(homeCity: city);
    await _saveUser();
    notifyListeners();
  }

  Future<void> updateFitnessLevel(FitnessLevel level) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(fitnessLevel: level);
    await _saveUser();
    notifyListeners();
  }

  Future<void> updateDietaryPreferences(List<String> prefs) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(dietaryPreferences: prefs);
    await _saveUser();
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      totalXp: _currentUser!.totalXp + amount,
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> updateStreak(int newStreak) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > _currentUser!.longestStreak
          ? newStreak
          : _currentUser!.longestStreak,
    );
    await _saveUser();
    notifyListeners();
  }

  Future<void> incrementStreak() async {
    if (_currentUser == null) return;
    final newStreak = _currentUser!.currentStreak + 1;
    await updateStreak(newStreak);
  }

  Future<void> resetStreak() async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(currentStreak: 0);
    await _saveUser();
    notifyListeners();
  }

  Future<void> clearUser() async {
    await _storage.remove(StorageKeys.userProfile);
    _currentUser = null;
    notifyListeners();
  }
}
