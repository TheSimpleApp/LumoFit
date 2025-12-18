/// AI-related models for Egypt fitness guide features

/// Response from the Egypt fitness guide AI
class EgyptGuideResponse {
  final String text;
  final List<SuggestedPlace> suggestedPlaces;
  final Map<String, dynamic>? suggestedFilters;

  const EgyptGuideResponse({
    required this.text,
    this.suggestedPlaces = const [],
    this.suggestedFilters,
  });

  factory EgyptGuideResponse.fromJson(Map<String, dynamic> json) {
    return EgyptGuideResponse(
      text: json['text'] as String? ?? '',
      suggestedPlaces: (json['suggestedPlaces'] as List<dynamic>?)
              ?.map((e) => SuggestedPlace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedFilters: json['suggestedFilters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'suggestedPlaces': suggestedPlaces.map((e) => e.toJson()).toList(),
        if (suggestedFilters != null) 'suggestedFilters': suggestedFilters,
      };
}

/// A place suggested by the AI guide
class SuggestedPlace {
  final String name;
  final String type;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final String? googlePlaceId;

  const SuggestedPlace({
    required this.name,
    required this.type,
    this.neighborhood,
    this.lat,
    this.lng,
    this.googlePlaceId,
  });

  factory SuggestedPlace.fromJson(Map<String, dynamic> json) {
    return SuggestedPlace(
      name: json['name'] as String,
      type: json['type'] as String,
      neighborhood: json['neighborhood'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      googlePlaceId: json['googlePlaceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
      };

  bool get hasCoordinates => lat != null && lng != null;
}

/// Response from the itinerary generator AI
class ItineraryResponse {
  final String title;
  final String destination;
  final List<ItineraryPlanItem> items;
  final List<String> packingList;

  const ItineraryResponse({
    required this.title,
    required this.destination,
    required this.items,
    this.packingList = const [],
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    return ItineraryResponse(
      title: json['title'] as String? ?? 'Fitness Day Plan',
      destination: json['destination'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ItineraryPlanItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      packingList: (json['packingList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'destination': destination,
        'items': items.map((e) => e.toJson()).toList(),
        'packingList': packingList,
      };

  /// Total duration in minutes
  int get totalDurationMinutes =>
      items.fold(0, (sum, item) => sum + item.duration);
}

/// A single item in an AI-generated itinerary
class ItineraryPlanItem {
  final String time;
  final int duration; // in minutes
  final ItineraryItemType type;
  final String title;
  final String description;
  final String? tips;
  final String? placeName;
  final double? lat;
  final double? lng;

  const ItineraryPlanItem({
    required this.time,
    required this.duration,
    required this.type,
    required this.title,
    required this.description,
    this.tips,
    this.placeName,
    this.lat,
    this.lng,
  });

  factory ItineraryPlanItem.fromJson(Map<String, dynamic> json) {
    return ItineraryPlanItem(
      time: json['time'] as String,
      duration: json['duration'] as int? ?? 60,
      type: ItineraryItemType.fromString(json['type'] as String?),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      tips: json['tips'] as String?,
      placeName: json['placeName'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'duration': duration,
        'type': type.name,
        'title': title,
        'description': description,
        if (tips != null) 'tips': tips,
        if (placeName != null) 'placeName': placeName,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  bool get hasCoordinates => lat != null && lng != null;
}

/// Types of itinerary items
enum ItineraryItemType {
  activity,
  meal,
  rest,
  travel,
  other;

  static ItineraryItemType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'activity':
        return ItineraryItemType.activity;
      case 'meal':
        return ItineraryItemType.meal;
      case 'rest':
        return ItineraryItemType.rest;
      case 'travel':
        return ItineraryItemType.travel;
      default:
        return ItineraryItemType.other;
    }
  }

  String get emoji {
    switch (this) {
      case ItineraryItemType.activity:
        return '💪';
      case ItineraryItemType.meal:
        return '🥗';
      case ItineraryItemType.rest:
        return '😌';
      case ItineraryItemType.travel:
        return '🚗';
      case ItineraryItemType.other:
        return '📍';
    }
  }
}

/// AI-generated insights for a specific place
class PlaceInsights {
  final String bestTimes;
  final List<String> whatToBring;
  final String localTips;
  final String? hiddenGems;
  final String? fitnessNotes;
  final DateTime? cachedAt;

  const PlaceInsights({
    required this.bestTimes,
    required this.whatToBring,
    required this.localTips,
    this.hiddenGems,
    this.fitnessNotes,
    this.cachedAt,
  });

  factory PlaceInsights.fromJson(Map<String, dynamic> json) {
    return PlaceInsights(
      bestTimes: json['bestTimes'] as String? ?? '',
      whatToBring: (json['whatToBring'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      localTips: json['localTips'] as String? ?? '',
      hiddenGems: json['hiddenGems'] as String?,
      fitnessNotes: json['fitnessNotes'] as String?,
      cachedAt: json['cachedAt'] != null
          ? DateTime.tryParse(json['cachedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bestTimes': bestTimes,
        'whatToBring': whatToBring,
        'localTips': localTips,
        if (hiddenGems != null) 'hiddenGems': hiddenGems,
        if (fitnessNotes != null) 'fitnessNotes': fitnessNotes,
        if (cachedAt != null) 'cachedAt': cachedAt!.toIso8601String(),
      };
}

/// A message in the AI chat conversation
class AiChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SuggestedPlace>? suggestedPlaces;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestedPlaces,
  });

  factory AiChatMessage.user(String content) {
    return AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory AiChatMessage.assistant(String content,
      {List<SuggestedPlace>? suggestedPlaces}) {
    return AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedPlaces: suggestedPlaces,
    );
  }
}

/// Egypt destination constants with coordinates
class EgyptDestinations {
  static const List<EgyptDestination> all = [
    EgyptDestination(
      name: 'Cairo',
      lat: 30.0444,
      lng: 31.2357,
      neighborhoods: ['Zamalek', 'Maadi', 'Heliopolis', 'New Cairo', 'Giza', 'Downtown'],
    ),
    EgyptDestination(
      name: 'Luxor',
      lat: 25.6872,
      lng: 32.6396,
      neighborhoods: ['East Bank', 'West Bank', 'Karnak'],
    ),
    EgyptDestination(
      name: 'Aswan',
      lat: 24.0889,
      lng: 32.8998,
      neighborhoods: ['Nile-side', 'Nubian Villages', 'Elephantine Island'],
    ),
    EgyptDestination(
      name: 'Hurghada',
      lat: 27.2579,
      lng: 33.8116,
      neighborhoods: ['El Dahar', 'Sigala', 'El Gouna', 'Sahl Hasheesh'],
    ),
    EgyptDestination(
      name: 'Sharm El Sheikh',
      lat: 27.9158,
      lng: 34.3300,
      neighborhoods: ['Naama Bay', 'Old Market', 'Ras Um Sid', 'Nabq Bay'],
    ),
    EgyptDestination(
      name: 'Alexandria',
      lat: 31.2001,
      lng: 29.9187,
      neighborhoods: ['Corniche', 'Montaza', 'San Stefano', 'Downtown'],
    ),
    EgyptDestination(
      name: 'Dahab',
      lat: 28.5007,
      lng: 34.5133,
      neighborhoods: ['Assalah', 'Masbat', 'Lighthouse', 'Blue Hole'],
    ),
    EgyptDestination(
      name: 'Siwa',
      lat: 29.2032,
      lng: 25.5195,
      neighborhoods: ['Shali', 'Aghurmi', 'Salt Lakes'],
    ),
  ];

  static EgyptDestination? findByName(String name) {
    try {
      return all.firstWhere(
        (d) => d.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// An Egypt destination with coordinates
class EgyptDestination {
  final String name;
  final double lat;
  final double lng;
  final List<String> neighborhoods;

  const EgyptDestination({
    required this.name,
    required this.lat,
    required this.lng,
    this.neighborhoods = const [],
  });
}
