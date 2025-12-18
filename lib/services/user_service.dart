import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';

class UserService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasUser => _currentUser != null;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  /// Initialize the service - load user from Supabase
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        // No authenticated user
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user profile from Supabase
      final userData = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );

      if (userData != null) {
        _currentUser = UserModel.fromSupabaseJson(userData);
      } else {
        // User authenticated but no profile - this shouldn't happen
        // as SupabaseAuthManager creates profile on signup
        debugPrint('UserService: No profile found for user $userId');
        _currentUser = null;
      }
    } catch (e) {
      _error = 'Failed to load user profile';
      debugPrint('UserService.initialize error: $e');
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save user profile to Supabase
  Future<void> _saveUser() async {
    if (_currentUser == null || _currentUserId == null) return;

    try {
      await SupabaseService.update(
        'users',
        _currentUser!.toSupabaseJson(),
        filters: {'id': _currentUserId!},
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to save user profile';
      debugPrint('UserService._saveUser error: $e');
      notifyListeners();
    }
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

  /// Clear local user state (called on logout)
  void clearUser() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
