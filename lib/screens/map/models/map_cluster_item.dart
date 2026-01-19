import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';

/// Wrapper class for places and events to support clustering
class MapClusterItem with ClusterItem {
  final String id;
  final LatLng position;
  final dynamic item; // PlaceModel or EventModel
  final MapItemType type;

  MapClusterItem({
    required this.id,
    required this.position,
    required this.item,
    required this.type,
  });

  @override
  LatLng get location => position;

  factory MapClusterItem.fromPlace(PlaceModel place) {
    MapItemType type;
    switch (place.type) {
      case PlaceType.gym:
        type = MapItemType.gym;
        break;
      case PlaceType.restaurant:
        type = MapItemType.food;
        break;
      case PlaceType.trail:
      case PlaceType.park:
        type = MapItemType.trail;
        break;
      default:
        type = MapItemType.other;
    }

    return MapClusterItem(
      id: 'place_${place.id}',
      position: LatLng(place.latitude!, place.longitude!),
      item: place,
      type: type,
    );
  }

  factory MapClusterItem.fromEvent(EventModel event) {
    return MapClusterItem(
      id: 'event_${event.id}',
      position: LatLng(event.latitude!, event.longitude!),
      item: event,
      type: MapItemType.event,
    );
  }
}

enum MapItemType {
  gym,
  food,
  trail,
  event,
  other,
}
