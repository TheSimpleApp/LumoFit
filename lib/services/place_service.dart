import 'package:flutter/foundation.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/supabase/supabase_config.dart';

class PlaceService extends ChangeNotifier {
  List<PlaceModel> _savedPlaces = [];
  bool _isLoading = false;
  String? _error;

  PlaceService();

  List<PlaceModel> get savedPlaces => _savedPlaces;
  List<PlaceModel> get gyms =>
      _savedPlaces.where((p) => p.type == PlaceType.gym).toList();
  List<PlaceModel> get restaurants =>
      _savedPlaces.where((p) => p.type == PlaceType.restaurant).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get current authenticated user ID
  String? get _currentUserId => SupabaseConfig.auth.currentUser?.id;

  /// Get count of visited places for badge checking
  int get visitedCount => _savedPlaces.where((p) => p.isVisited).length;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId;
      if (userId == null) {
        _savedPlaces = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user's saved places from Supabase
      final data = await SupabaseService.select(
        'saved_places',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      _savedPlaces = data.map((j) => PlaceModel.fromSupabaseJson(j)).toList();
    } catch (e) {
      _error = 'Failed to load saved places';
      debugPrint('PlaceService.initialize error: $e');
      _savedPlaces = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePlace(PlaceModel place) async {
    final userId = _currentUserId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    // Check if already exists locally
    final exists = _savedPlaces.any((p) =>
        p.id == place.id ||
        (place.googlePlaceId != null &&
            p.googlePlaceId == place.googlePlaceId));
    if (exists) return;

    try {
      final data = place.toSupabaseJson(userId);
      final result = await SupabaseService.insert('saved_places', data);

      if (result.isNotEmpty) {
        final newPlace = PlaceModel.fromSupabaseJson(result.first);
        _savedPlaces.insert(0, newPlace);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to save place';
      debugPrint('PlaceService.savePlace error: $e');
      notifyListeners();
    }
  }

  Future<void> removePlace(String placeId) async {
    try {
      await SupabaseService.delete(
        'saved_places',
        filters: {'id': placeId},
      );

      _savedPlaces.removeWhere((p) => p.id == placeId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove place';
      debugPrint('PlaceService.removePlace error: $e');
      notifyListeners();
    }
  }

  Future<void> updatePlace(PlaceModel place) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await SupabaseService.update(
        'saved_places',
        place.toSupabaseJson(userId),
        filters: {'id': place.id},
      );

      final index = _savedPlaces.indexWhere((p) => p.id == place.id);
      if (index >= 0) {
        _savedPlaces[index] = place;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update place';
      debugPrint('PlaceService.updatePlace error: $e');
      notifyListeners();
    }
  }

  Future<void> markVisited(String placeId) async {
    final index = _savedPlaces.indexWhere((p) => p.id == placeId);
    if (index < 0) return;

    final visitedAt = DateTime.now();

    try {
      await SupabaseService.update(
        'saved_places',
        {
          'is_visited': true,
          'visited_at': visitedAt.toIso8601String(),
        },
        filters: {'id': placeId},
      );

      _savedPlaces[index] = _savedPlaces[index].copyWith(
        isVisited: true,
        visitedAt: visitedAt,
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark place as visited';
      debugPrint('PlaceService.markVisited error: $e');
      notifyListeners();
    }
  }

  PlaceModel? getPlaceById(String id) {
    try {
      return _savedPlaces.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a place is saved by Google Place ID
  bool isPlaceSaved(String? googlePlaceId) {
    if (googlePlaceId == null) return false;
    return _savedPlaces.any((p) => p.googlePlaceId == googlePlaceId);
  }

  /// Get saved place by Google Place ID
  PlaceModel? getPlaceByGoogleId(String googlePlaceId) {
    try {
      return _savedPlaces.firstWhere((p) => p.googlePlaceId == googlePlaceId);
    } catch (e) {
      return null;
    }
  }

  List<PlaceModel> getPlacesByType(PlaceType type) {
    return _savedPlaces.where((p) => p.type == type).toList();
  }

  List<PlaceModel> searchPlaces(String query) {
    final lowerQuery = query.toLowerCase();
    return _savedPlaces.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          (p.address?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Clear local state (called on logout)
  void clearPlaces() {
    _savedPlaces = [];
    _error = null;
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
