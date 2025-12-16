import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

class PlaceService extends ChangeNotifier {
  final StorageService _storage;
  List<PlaceModel> _savedPlaces = [];
  bool _isLoading = false;

  PlaceService(this._storage);

  List<PlaceModel> get savedPlaces => _savedPlaces;
  List<PlaceModel> get gyms => _savedPlaces.where((p) => p.type == PlaceType.gym).toList();
  List<PlaceModel> get restaurants => _savedPlaces.where((p) => p.type == PlaceType.restaurant).toList();
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonList = _storage.getJsonList(StorageKeys.savedPlaces);
      if (jsonList != null && jsonList.isNotEmpty) {
        _savedPlaces = jsonList.map((j) => PlaceModel.fromJson(j)).toList();
      } else {
        await _loadSampleData();
      }
    } catch (e) {
      debugPrint('PlaceService.initialize error: $e');
      await _loadSampleData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSampleData() async {
    // Salt Lake City gyms
    _savedPlaces = [
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.gym,
        name: 'Vasa Fitness - Downtown SLC',
        address: '134 W Pierpont Ave, Salt Lake City, UT 84101',
        latitude: 40.7633,
        longitude: -111.8977,
        rating: 4.3,
        userRatingsTotal: 1247,
        openingHours: [
          'Monday: 5:00 AM - 11:00 PM',
          'Tuesday: 5:00 AM - 11:00 PM',
          'Wednesday: 5:00 AM - 11:00 PM',
          'Thursday: 5:00 AM - 11:00 PM',
          'Friday: 5:00 AM - 10:00 PM',
          'Saturday: 7:00 AM - 8:00 PM',
          'Sunday: 7:00 AM - 8:00 PM',
        ],
        priceLevel: '\$',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.gym,
        name: 'Gold\'s Gym - Sugar House',
        address: '2159 S 700 E, Salt Lake City, UT 84106',
        latitude: 40.7245,
        longitude: -111.8634,
        rating: 4.1,
        userRatingsTotal: 892,
        openingHours: [
          'Monday: 5:00 AM - 10:00 PM',
          'Tuesday: 5:00 AM - 10:00 PM',
          'Wednesday: 5:00 AM - 10:00 PM',
          'Thursday: 5:00 AM - 10:00 PM',
          'Friday: 5:00 AM - 9:00 PM',
          'Saturday: 7:00 AM - 7:00 PM',
          'Sunday: 8:00 AM - 6:00 PM',
        ],
        priceLevel: '\$\$',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.gym,
        name: 'The Gym SLC',
        address: '845 E 900 S, Salt Lake City, UT 84102',
        latitude: 40.7503,
        longitude: -111.8614,
        rating: 4.7,
        userRatingsTotal: 456,
        openingHours: [
          'Monday: 6:00 AM - 9:00 PM',
          'Tuesday: 6:00 AM - 9:00 PM',
          'Wednesday: 6:00 AM - 9:00 PM',
          'Thursday: 6:00 AM - 9:00 PM',
          'Friday: 6:00 AM - 8:00 PM',
          'Saturday: 8:00 AM - 6:00 PM',
          'Sunday: 8:00 AM - 4:00 PM',
        ],
        priceLevel: '\$\$',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.gym,
        name: 'Anytime Fitness - 9th & 9th',
        address: '923 E 900 S, Salt Lake City, UT 84105',
        latitude: 40.7503,
        longitude: -111.8574,
        rating: 4.4,
        userRatingsTotal: 234,
        openingHours: ['Open 24 hours'],
        priceLevel: '\$\$',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.gym,
        name: 'UFC Gym - Sandy',
        address: '9460 S Union Square, Sandy, UT 84070',
        latitude: 40.5758,
        longitude: -111.8876,
        rating: 4.5,
        userRatingsTotal: 678,
        openingHours: [
          'Monday: 5:00 AM - 11:00 PM',
          'Tuesday: 5:00 AM - 11:00 PM',
          'Wednesday: 5:00 AM - 11:00 PM',
          'Thursday: 5:00 AM - 11:00 PM',
          'Friday: 5:00 AM - 10:00 PM',
          'Saturday: 7:00 AM - 8:00 PM',
          'Sunday: 8:00 AM - 6:00 PM',
        ],
        priceLevel: '\$\$',
      ),
      // Salt Lake City healthy restaurants
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.restaurant,
        name: 'Cafe Zupas',
        address: '676 E 400 S, Salt Lake City, UT 84102',
        latitude: 40.7590,
        longitude: -111.8686,
        rating: 4.4,
        userRatingsTotal: 1456,
        openingHours: [
          'Monday: 11:00 AM - 9:00 PM',
          'Tuesday: 11:00 AM - 9:00 PM',
          'Wednesday: 11:00 AM - 9:00 PM',
          'Thursday: 11:00 AM - 9:00 PM',
          'Friday: 11:00 AM - 9:00 PM',
          'Saturday: 11:00 AM - 9:00 PM',
          'Sunday: Closed',
        ],
        priceLevel: '\$\$',
        notes: 'Fresh soups, salads & sandwiches',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.restaurant,
        name: 'Even Stevens Sandwiches',
        address: '471 E 300 S, Salt Lake City, UT 84111',
        latitude: 40.7608,
        longitude: -111.8742,
        rating: 4.5,
        userRatingsTotal: 987,
        openingHours: [
          'Monday: 7:00 AM - 9:00 PM',
          'Tuesday: 7:00 AM - 9:00 PM',
          'Wednesday: 7:00 AM - 9:00 PM',
          'Thursday: 7:00 AM - 9:00 PM',
          'Friday: 7:00 AM - 9:00 PM',
          'Saturday: 8:00 AM - 9:00 PM',
          'Sunday: 8:00 AM - 8:00 PM',
        ],
        priceLevel: '\$\$',
        notes: 'Healthy sandwiches & smoothies - gives back to community',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.restaurant,
        name: 'Vessel Kitchen',
        address: '26 E St, Salt Lake City, UT 84103',
        latitude: 40.7761,
        longitude: -111.8859,
        rating: 4.6,
        userRatingsTotal: 543,
        openingHours: [
          'Monday: 11:00 AM - 9:00 PM',
          'Tuesday: 11:00 AM - 9:00 PM',
          'Wednesday: 11:00 AM - 9:00 PM',
          'Thursday: 11:00 AM - 9:00 PM',
          'Friday: 11:00 AM - 9:00 PM',
          'Saturday: 10:00 AM - 9:00 PM',
          'Sunday: 10:00 AM - 8:00 PM',
        ],
        priceLevel: '\$\$',
        notes: 'Health-focused menu with fresh ingredients',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.restaurant,
        name: 'Roots Cafe',
        address: '3474 S 2300 E, Salt Lake City, UT 84109',
        latitude: 40.7004,
        longitude: -111.8294,
        rating: 4.7,
        userRatingsTotal: 321,
        openingHours: [
          'Monday: 8:00 AM - 3:00 PM',
          'Tuesday: 8:00 AM - 3:00 PM',
          'Wednesday: 8:00 AM - 3:00 PM',
          'Thursday: 8:00 AM - 3:00 PM',
          'Friday: 8:00 AM - 3:00 PM',
          'Saturday: 9:00 AM - 3:00 PM',
          'Sunday: 9:00 AM - 2:00 PM',
        ],
        priceLevel: '\$\$',
        notes: 'Vegan & vegetarian friendly',
      ),
      PlaceModel(
        id: const Uuid().v4(),
        type: PlaceType.restaurant,
        name: 'Aubergine & Company',
        address: '3670 S Highland Dr, Salt Lake City, UT 84106',
        latitude: 40.6958,
        longitude: -111.8484,
        rating: 4.5,
        userRatingsTotal: 276,
        openingHours: [
          'Monday: 11:00 AM - 9:00 PM',
          'Tuesday: 11:00 AM - 9:00 PM',
          'Wednesday: 11:00 AM - 9:00 PM',
          'Thursday: 11:00 AM - 9:00 PM',
          'Friday: 11:00 AM - 10:00 PM',
          'Saturday: 11:00 AM - 10:00 PM',
          'Sunday: Closed',
        ],
        priceLevel: '\$\$',
        notes: 'Mediterranean cuisine - fresh & healthy',
      ),
    ];
    await _savePlaces();
  }

  Future<void> _savePlaces() async {
    final jsonList = _savedPlaces.map((p) => p.toJson()).toList();
    await _storage.setJsonList(StorageKeys.savedPlaces, jsonList);
  }

  Future<void> savePlace(PlaceModel place) async {
    final exists = _savedPlaces.any((p) => p.id == place.id);
    if (!exists) {
      _savedPlaces.add(place);
      await _savePlaces();
      notifyListeners();
    }
  }

  Future<void> removePlace(String placeId) async {
    _savedPlaces.removeWhere((p) => p.id == placeId);
    await _savePlaces();
    notifyListeners();
  }

  Future<void> updatePlace(PlaceModel place) async {
    final index = _savedPlaces.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      _savedPlaces[index] = place;
      await _savePlaces();
      notifyListeners();
    }
  }

  Future<void> markVisited(String placeId) async {
    final index = _savedPlaces.indexWhere((p) => p.id == placeId);
    if (index >= 0) {
      _savedPlaces[index] = _savedPlaces[index].copyWith(
        isVisited: true,
        visitedAt: DateTime.now(),
      );
      await _savePlaces();
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
}
