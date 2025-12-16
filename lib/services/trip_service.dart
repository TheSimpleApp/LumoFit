import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/models.dart';
import 'package:fittravel/services/storage_service.dart';

class TripService extends ChangeNotifier {
  final StorageService _storage;
  List<TripModel> _trips = [];
  bool _isLoading = false;
  // tripId -> itinerary items
  final Map<String, List<ItineraryItem>> _itineraries = {};

  TripService(this._storage);

  List<TripModel> get trips => _trips;
  List<TripModel> get upcomingTrips => _trips.where((t) => t.isUpcoming).toList();
  List<TripModel> get pastTrips => _trips.where((t) => t.isPast).toList();
  List<TripModel> get currentTrips => _trips.where((t) => t.isCurrent).toList();
  TripModel? get activeTrip {
    try {
      return _trips.firstWhere((t) => t.isActive);
    } catch (e) {
      return null;
    }
  }
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonList = _storage.getJsonList(StorageKeys.trips);
      if (jsonList != null && jsonList.isNotEmpty) {
        _trips = jsonList.map((j) => TripModel.fromJson(j)).toList();
      } else {
        await _loadSampleData();
      }

      // Load itineraries map
      final map = _storage.getJson(StorageKeys.tripItineraries);
      if (map != null) {
        _itineraries.clear();
        map.forEach((key, value) {
          try {
            final list = (value as List<dynamic>)
                .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
                .toList();
            _itineraries[key] = list;
          } catch (e) {
            debugPrint('TripService.initialize itinerary parse error for $key: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('TripService.initialize error: $e');
      await _loadSampleData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSampleData() async {
    final now = DateTime.now();
    _trips = [
      TripModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        destinationCity: 'Salt Lake City',
        destinationCountry: 'USA',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        isActive: true,
        notes: 'Exploring the fitness scene in SLC!',
      ),
      TripModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        destinationCity: 'Denver',
        destinationCountry: 'USA',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 21)),
        notes: 'Mountain fitness adventure',
      ),
      TripModel(
        id: const Uuid().v4(),
        userId: 'sample-user',
        destinationCity: 'San Diego',
        destinationCountry: 'USA',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 25)),
        notes: 'Beach workouts completed!',
      ),
    ];
    await _saveTrips();
  }

  Future<void> _saveTrips() async {
    final jsonList = _trips.map((t) => t.toJson()).toList();
    await _storage.setJsonList(StorageKeys.trips, jsonList);
  }

  Future<void> _saveItineraries() async {
    final map = <String, dynamic>{};
    _itineraries.forEach((tripId, items) {
      map[tripId] = items.map((e) => e.toJson()).toList();
    });
    await _storage.setJson(StorageKeys.tripItineraries, map);
  }

  Future<TripModel> createTrip({
    required String destinationCity,
    String? destinationCountry,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    final trip = TripModel(
      id: const Uuid().v4(),
      userId: 'sample-user',
      destinationCity: destinationCity,
      destinationCountry: destinationCountry,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );
    _trips.add(trip);
    await _saveTrips();
    notifyListeners();
    return trip;
  }

  Future<void> updateTrip(TripModel trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      _trips[index] = trip.copyWith(updatedAt: DateTime.now());
      await _saveTrips();
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((t) => t.id == tripId);
    _itineraries.remove(tripId);
    await _saveTrips();
    await _saveItineraries();
    notifyListeners();
  }

  Future<void> setActiveTrip(String tripId) async {
    for (int i = 0; i < _trips.length; i++) {
      _trips[i] = _trips[i].copyWith(isActive: _trips[i].id == tripId);
    }
    await _saveTrips();
    notifyListeners();
  }

  Future<void> addPlaceToTrip(String tripId, String placeId) async {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index >= 0) {
      final trip = _trips[index];
      if (!trip.savedPlaceIds.contains(placeId)) {
        _trips[index] = trip.copyWith(
          savedPlaceIds: [...trip.savedPlaceIds, placeId],
        );
        await _saveTrips();
        notifyListeners();
      }
    }
  }

  Future<void> removePlaceFromTrip(String tripId, String placeId) async {
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index >= 0) {
      final trip = _trips[index];
      _trips[index] = trip.copyWith(
        savedPlaceIds: trip.savedPlaceIds.where((id) => id != placeId).toList(),
      );
      await _saveTrips();
      notifyListeners();
    }
  }

  TripModel? getTripById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ---------- Itinerary APIs ----------

  List<ItineraryItem> getItinerary(String tripId, {DateTime? forDate}) {
    final items = List<ItineraryItem>.from(_itineraries[tripId] ?? const []);
    if (forDate == null) return items..sort(_compareItems);
    final d = DateTime(forDate.year, forDate.month, forDate.day);
    return items
      ..retainWhere((it) => _isSameDay(it.date, d))
      ..sort(_compareItems);
  }

  Future<void> addItineraryItem(String tripId, ItineraryItem item) async {
    final list = _itineraries.putIfAbsent(tripId, () => []);
    list.add(item);
    await _saveItineraries();
    notifyListeners();
  }

  Future<void> updateItineraryItem(String tripId, ItineraryItem item) async {
    final list = _itineraries[tripId];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) list[idx] = item;
    await _saveItineraries();
    notifyListeners();
  }

  Future<void> removeItineraryItem(String tripId, String itemId) async {
    final list = _itineraries[tripId];
    if (list == null) return;
    list.removeWhere((e) => e.id == itemId);
    await _saveItineraries();
    notifyListeners();
  }

  Future<void> reorderItinerary(String tripId, List<ItineraryItem> newOrder) async {
    _itineraries[tripId] = List<ItineraryItem>.from(newOrder);
    await _saveItineraries();
    notifyListeners();
  }

  int _compareItems(ItineraryItem a, ItineraryItem b) {
    final at = a.startTime ?? '99:99';
    final bt = b.startTime ?? '99:99';
    final cmpDate = a.date.compareTo(b.date);
    if (cmpDate != 0) return cmpDate;
    return at.compareTo(bt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
