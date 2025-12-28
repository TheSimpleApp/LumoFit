// AI-related models for fitness guide features
import 'dart:convert';

/// Response from the fitness guide AI
/// Note: Named EgyptGuideResponse for legacy compatibility, but works globally
class EgyptGuideResponse {
  final String text;
  final List<SuggestedPlace> suggestedPlaces;
  final Map<String, dynamic>? suggestedFilters;
  final List<MessageElement>? elements;
  final List<QuickReply>? quickReplies;
  final List<String>? tags;

  const EgyptGuideResponse({
    required this.text,
    this.suggestedPlaces = const [],
    this.suggestedFilters,
    this.elements,
    this.quickReplies,
    this.tags,
  });

  factory EgyptGuideResponse.fromJson(Map<String, dynamic> json) {
    // Recursively extract text from potentially nested JSON structures
    String extractText(dynamic obj, int depth) {
      if (depth > 5) return '';
      if (obj is String) {
        final trimmed = obj.trim();
        if (trimmed.startsWith('{')) {
          try {
            final parsed = jsonDecode(trimmed);
            final nested = extractText(parsed, depth + 1);
            if (nested.isNotEmpty) return nested;
          } catch (_) {
            // Not valid JSON, return as-is if it looks like text
            if (trimmed.length > 5 && !trimmed.contains('"text"')) {
              return trimmed;
            }
          }
        }
        return obj;
      }
      if (obj is Map) {
        final textVal = obj['text'];
        if (textVal is String && textVal.trim().isNotEmpty) {
          final trimmedText = textVal.trim();
          if (trimmedText.startsWith('{')) {
            try {
              final parsed = jsonDecode(trimmedText);
              final nested = extractText(parsed, depth + 1);
              if (nested.isNotEmpty) return nested;
            } catch (_) {
              // Not nested JSON
            }
          }
          return textVal;
        }
      }
      return '';
    }

    // Recursively extract array from potentially nested JSON
    List<T> extractArray<T>(dynamic obj, String key, T Function(Map<String, dynamic>) fromJson, int depth) {
      if (depth > 5 || obj == null) return [];
      if (obj is Map) {
        final arr = obj[key];
        if (arr is List) {
          return arr
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<T>()
              .toList();
        }
        // Check nested text field
        final textVal = obj['text'];
        if (textVal is String && textVal.trim().startsWith('{')) {
          try {
            final parsed = jsonDecode(textVal.trim());
            return extractArray(parsed, key, fromJson, depth + 1);
          } catch (_) {}
        }
      }
      return [];
    }

    // Extract text, handling multiple levels of nesting
    String text = extractText(json, 0);

    // Final fallback: if text still looks like JSON, provide default
    if (text.isEmpty || text.trimLeft().startsWith('{') || text.trimLeft().startsWith('[')) {
      text = "I'd be happy to help you find fitness spots! What are you looking for?";
    }

    // Extract arrays, checking both top-level and nested
    final suggestedPlaces = extractArray<SuggestedPlace>(json, 'suggestedPlaces', SuggestedPlace.fromJson, 0);
    final elements = extractArray<MessageElement>(json, 'elements', MessageElement.fromJson, 0);
    final quickReplies = extractArray<QuickReply>(json, 'quickReplies', QuickReply.fromJson, 0);

    // Extract tags (simple strings)
    List<String> extractStringArray(dynamic obj, String key, int depth) {
      if (depth > 5 || obj == null) return [];
      if (obj is Map) {
        final arr = obj[key];
        if (arr is List) {
          return arr.whereType<String>().toList();
        }
        final textVal = obj['text'];
        if (textVal is String && textVal.trim().startsWith('{')) {
          try {
            return extractStringArray(jsonDecode(textVal.trim()), key, depth + 1);
          } catch (_) {}
        }
      }
      return [];
    }

    final tags = extractStringArray(json, 'tags', 0);

    return EgyptGuideResponse(
      text: text,
      suggestedPlaces: suggestedPlaces,
      suggestedFilters: json['suggestedFilters'] as Map<String, dynamic>?,
      elements: elements.isEmpty ? null : elements,
      quickReplies: quickReplies.isEmpty ? null : quickReplies,
      tags: tags.isEmpty ? null : tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'suggestedPlaces': suggestedPlaces.map((e) => e.toJson()).toList(),
        if (suggestedFilters != null) 'suggestedFilters': suggestedFilters,
        if (elements != null)
          'elements': elements!.map((e) => e.toJson()).toList(),
        if (quickReplies != null)
          'quickReplies': quickReplies!.map((e) => e.toJson()).toList(),
        if (tags != null) 'tags': tags,
      };
}

/// Type alias for global fitness guide response
typedef FitnessGuideResponse = EgyptGuideResponse;

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

/// Enhanced AI-generated fitness intelligence for a specific place
/// Extracted from reviews and place data
class PlaceFitnessIntelligence {
  // Core Analysis
  final String summary; // 2-3 sentence AI summary focused on fitness/health
  final double? fitnessScore; // 0-10 score for fitness suitability
  
  // Crowd & Timing
  final Map<String, String> bestTimesDetailed; // e.g., {"morning": "6-9 AM - Least crowded", "evening": "After 8 PM - Peak hours"}
  final String? crowdInsights; // AI analysis of crowd patterns
  
  // Type-specific Intelligence
  final GymIntelligence? gymInsights; // For gyms/fitness centers
  final RestaurantIntelligence? restaurantInsights; // For restaurants
  final TrailIntelligence? trailInsights; // For trails/outdoor
  
  // Common Insights
  final List<String> pros; // Fitness-focused pros
  final List<String> cons; // Fitness-focused cons
  final List<String> tips; // Actionable fitness tips
  final List<String> whatToBring; // Recommended items
  
  // Review Analysis
  final ReviewSentiment? sentiment; // Aggregated sentiment from reviews
  final List<String> commonPhrases; // Frequently mentioned fitness-related phrases
  
  // Metadata
  final DateTime generatedAt;
  final int reviewsAnalyzed;

  const PlaceFitnessIntelligence({
    required this.summary,
    this.fitnessScore,
    this.bestTimesDetailed = const {},
    this.crowdInsights,
    this.gymInsights,
    this.restaurantInsights,
    this.trailInsights,
    this.pros = const [],
    this.cons = const [],
    this.tips = const [],
    this.whatToBring = const [],
    this.sentiment,
    this.commonPhrases = const [],
    required this.generatedAt,
    this.reviewsAnalyzed = 0,
  });

  factory PlaceFitnessIntelligence.fromJson(Map<String, dynamic> json) {
    return PlaceFitnessIntelligence(
      summary: json['summary'] as String? ?? '',
      fitnessScore: (json['fitnessScore'] as num?)?.toDouble(),
      bestTimesDetailed: (json['bestTimesDetailed'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      crowdInsights: json['crowdInsights'] as String?,
      gymInsights: json['gymInsights'] != null
          ? GymIntelligence.fromJson(json['gymInsights'] as Map<String, dynamic>)
          : null,
      restaurantInsights: json['restaurantInsights'] != null
          ? RestaurantIntelligence.fromJson(json['restaurantInsights'] as Map<String, dynamic>)
          : null,
      trailInsights: json['trailInsights'] != null
          ? TrailIntelligence.fromJson(json['trailInsights'] as Map<String, dynamic>)
          : null,
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      whatToBring: (json['whatToBring'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sentiment: json['sentiment'] != null
          ? ReviewSentiment.fromJson(json['sentiment'] as Map<String, dynamic>)
          : null,
      commonPhrases: (json['commonPhrases'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      reviewsAnalyzed: json['reviewsAnalyzed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        if (fitnessScore != null) 'fitnessScore': fitnessScore,
        'bestTimesDetailed': bestTimesDetailed,
        if (crowdInsights != null) 'crowdInsights': crowdInsights,
        if (gymInsights != null) 'gymInsights': gymInsights!.toJson(),
        if (restaurantInsights != null) 'restaurantInsights': restaurantInsights!.toJson(),
        if (trailInsights != null) 'trailInsights': trailInsights!.toJson(),
        'pros': pros,
        'cons': cons,
        'tips': tips,
        'whatToBring': whatToBring,
        if (sentiment != null) 'sentiment': sentiment!.toJson(),
        'commonPhrases': commonPhrases,
        'generatedAt': generatedAt.toIso8601String(),
        'reviewsAnalyzed': reviewsAnalyzed,
      };
}

/// Gym-specific intelligence
class GymIntelligence {
  final List<String> equipment; // Available equipment mentioned
  final String? cleanlinessRating; // Extracted cleanliness sentiment
  final List<String> amenities; // Showers, lockers, WiFi, etc.
  final String? coachingQuality; // Trainer/coaching mentions
  final bool? beginnerFriendly;
  final Map<String, String>? classSchedule; // If mentioned in reviews

  const GymIntelligence({
    this.equipment = const [],
    this.cleanlinessRating,
    this.amenities = const [],
    this.coachingQuality,
    this.beginnerFriendly,
    this.classSchedule,
  });

  factory GymIntelligence.fromJson(Map<String, dynamic> json) {
    return GymIntelligence(
      equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      cleanlinessRating: json['cleanlinessRating'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      coachingQuality: json['coachingQuality'] as String?,
      beginnerFriendly: json['beginnerFriendly'] as bool?,
      classSchedule: (json['classSchedule'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipment': equipment,
        if (cleanlinessRating != null) 'cleanlinessRating': cleanlinessRating,
        'amenities': amenities,
        if (coachingQuality != null) 'coachingQuality': coachingQuality,
        if (beginnerFriendly != null) 'beginnerFriendly': beginnerFriendly,
        if (classSchedule != null) 'classSchedule': classSchedule,
      };
}

/// Restaurant-specific intelligence
class RestaurantIntelligence {
  final List<String> healthyOptions; // Healthy menu items mentioned
  final List<String> dietaryAccommodations; // Vegan, gluten-free, etc.
  final String? macroInfo; // Protein-rich, low-carb mentions
  final String? portionSize; // Portion size feedback
  final double? proteinScore; // 0-10 for protein availability
  final List<String> popularHealthyDishes; // Specific dishes mentioned
  final bool? postWorkoutFriendly;

  const RestaurantIntelligence({
    this.healthyOptions = const [],
    this.dietaryAccommodations = const [],
    this.macroInfo,
    this.portionSize,
    this.proteinScore,
    this.popularHealthyDishes = const [],
    this.postWorkoutFriendly,
  });

  factory RestaurantIntelligence.fromJson(Map<String, dynamic> json) {
    return RestaurantIntelligence(
      healthyOptions: (json['healthyOptions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      dietaryAccommodations: (json['dietaryAccommodations'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      macroInfo: json['macroInfo'] as String?,
      portionSize: json['portionSize'] as String?,
      proteinScore: (json['proteinScore'] as num?)?.toDouble(),
      popularHealthyDishes: (json['popularHealthyDishes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      postWorkoutFriendly: json['postWorkoutFriendly'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'healthyOptions': healthyOptions,
        'dietaryAccommodations': dietaryAccommodations,
        if (macroInfo != null) 'macroInfo': macroInfo,
        if (portionSize != null) 'portionSize': portionSize,
        if (proteinScore != null) 'proteinScore': proteinScore,
        'popularHealthyDishes': popularHealthyDishes,
        if (postWorkoutFriendly != null) 'postWorkoutFriendly': postWorkoutFriendly,
      };
}

/// Trail/outdoor-specific intelligence
class TrailIntelligence {
  final String? difficulty; // Easy, Moderate, Hard
  final String? terrain; // Type of terrain
  final double? distanceKm; // Trail distance if mentioned
  final String? elevationGain; // Elevation info
  final List<String> scenicHighlights; // Views, landmarks
  final String? bestSeason; // Best time of year
  final bool? dogFriendly;
  final bool? bikeAccessible;
  final String? waterAvailability;

  const TrailIntelligence({
    this.difficulty,
    this.terrain,
    this.distanceKm,
    this.elevationGain,
    this.scenicHighlights = const [],
    this.bestSeason,
    this.dogFriendly,
    this.bikeAccessible,
    this.waterAvailability,
  });

  factory TrailIntelligence.fromJson(Map<String, dynamic> json) {
    return TrailIntelligence(
      difficulty: json['difficulty'] as String?,
      terrain: json['terrain'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      elevationGain: json['elevationGain'] as String?,
      scenicHighlights: (json['scenicHighlights'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      bestSeason: json['bestSeason'] as String?,
      dogFriendly: json['dogFriendly'] as bool?,
      bikeAccessible: json['bikeAccessible'] as bool?,
      waterAvailability: json['waterAvailability'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (difficulty != null) 'difficulty': difficulty,
        if (terrain != null) 'terrain': terrain,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (elevationGain != null) 'elevationGain': elevationGain,
        'scenicHighlights': scenicHighlights,
        if (bestSeason != null) 'bestSeason': bestSeason,
        if (dogFriendly != null) 'dogFriendly': dogFriendly,
        if (bikeAccessible != null) 'bikeAccessible': bikeAccessible,
        if (waterAvailability != null) 'waterAvailability': waterAvailability,
      };
}

/// Review sentiment analysis
class ReviewSentiment {
  final double overall; // -1 to 1
  final String label; // "Very Positive", "Positive", "Mixed", "Negative"
  final Map<String, double> aspectScores; // e.g., {"cleanliness": 0.8, "equipment": 0.6}

  const ReviewSentiment({
    required this.overall,
    required this.label,
    this.aspectScores = const {},
  });

  factory ReviewSentiment.fromJson(Map<String, dynamic> json) {
    return ReviewSentiment(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String? ?? 'Unknown',
      aspectScores: (json['aspectScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'label': label,
        'aspectScores': aspectScores,
      };
}

/// Interactive message element types
enum MessageElementType {
  text,
  quickReplies,
  singleSelect,
  multiSelect,
  image,
  places,
  tags,
}

/// An interactive element within a message
class MessageElement {
  final MessageElementType type;
  final String? text;
  final String? imageUrl;
  final List<QuickReply>? quickReplies;
  final SelectOption? selectOption;
  final List<SuggestedPlace>? places;
  final List<String>? tags;

  const MessageElement({
    required this.type,
    this.text,
    this.imageUrl,
    this.quickReplies,
    this.selectOption,
    this.places,
    this.tags,
  });

  factory MessageElement.text(String text) {
    return MessageElement(type: MessageElementType.text, text: text);
  }

  factory MessageElement.image(String imageUrl, {String? caption}) {
    return MessageElement(
      type: MessageElementType.image,
      imageUrl: imageUrl,
      text: caption,
    );
  }

  factory MessageElement.quickReplies(List<QuickReply> replies) {
    return MessageElement(
      type: MessageElementType.quickReplies,
      quickReplies: replies,
    );
  }

  factory MessageElement.singleSelect(SelectOption option) {
    return MessageElement(
      type: MessageElementType.singleSelect,
      selectOption: option,
    );
  }

  factory MessageElement.multiSelect(SelectOption option) {
    return MessageElement(
      type: MessageElementType.multiSelect,
      selectOption: option,
    );
  }

  factory MessageElement.places(List<SuggestedPlace> places) {
    return MessageElement(
      type: MessageElementType.places,
      places: places,
    );
  }

  factory MessageElement.tags(List<String> tags) {
    return MessageElement(
      type: MessageElementType.tags,
      tags: tags,
    );
  }

  factory MessageElement.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = MessageElementType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => MessageElementType.text,
    );

    return MessageElement(
      type: type,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      quickReplies: (json['quickReplies'] as List<dynamic>?)
          ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectOption: json['selectOption'] != null
          ? SelectOption.fromJson(json['selectOption'] as Map<String, dynamic>)
          : null,
      places: (json['places'] as List<dynamic>?)
          ?.map((e) => SuggestedPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (quickReplies != null)
          'quickReplies': quickReplies!.map((e) => e.toJson()).toList(),
        if (selectOption != null) 'selectOption': selectOption!.toJson(),
        if (places != null) 'places': places!.map((e) => e.toJson()).toList(),
        if (tags != null) 'tags': tags,
      };
}

/// A quick reply option
class QuickReply {
  final String id;
  final String text;
  final String? emoji;
  final String? value;

  const QuickReply({
    required this.id,
    required this.text,
    this.emoji,
    this.value,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (emoji != null) 'emoji': emoji,
        if (value != null) 'value': value,
      };
}

/// A select option (single or multi-select)
class SelectOption {
  final String id;
  final String question;
  final List<SelectChoice> choices;
  final List<String> selectedIds;

  const SelectOption({
    required this.id,
    required this.question,
    required this.choices,
    this.selectedIds = const [],
  });

  SelectOption copyWithSelected(List<String> selectedIds) {
    return SelectOption(
      id: id,
      question: question,
      choices: choices,
      selectedIds: selectedIds,
    );
  }

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    return SelectOption(
      id: json['id'] as String,
      question: json['question'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => SelectChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedIds: (json['selectedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'choices': choices.map((e) => e.toJson()).toList(),
        'selectedIds': selectedIds,
      };
}

/// A choice in a select option
class SelectChoice {
  final String id;
  final String text;
  final String? emoji;
  final String? description;

  const SelectChoice({
    required this.id,
    required this.text,
    this.emoji,
    this.description,
  });

  factory SelectChoice.fromJson(Map<String, dynamic> json) {
    return SelectChoice(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (emoji != null) 'emoji': emoji,
        if (description != null) 'description': description,
      };
}

/// A message in the AI chat conversation
class AiChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SuggestedPlace>? suggestedPlaces;
  final List<MessageElement>? elements;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestedPlaces,
    this.elements,
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
      {List<SuggestedPlace>? suggestedPlaces, List<MessageElement>? elements}) {
    return AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedPlaces: suggestedPlaces,
      elements: elements,
    );
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestedPlaces: (json['suggestedPlaces'] as List<dynamic>?)
          ?.map((e) => SuggestedPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      elements: (json['elements'] as List<dynamic>?)
          ?.map((e) => MessageElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        if (suggestedPlaces != null)
          'suggestedPlaces': suggestedPlaces!.map((e) => e.toJson()).toList(),
        if (elements != null)
          'elements': elements!.map((e) => e.toJson()).toList(),
      };
}

/// Popular fitness destination constants with coordinates
/// Note: Currently contains Egypt destinations but app supports global search
/// via location-based discovery and Google Places API
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

/// AI-generated quick insights for a place
/// These are lightweight, fast-generated tags to help users quickly understand a place
/// Generated using a lighter AI model (e.g., Gemini 2.5 Flash) for speed
class PlaceQuickInsights {
  final List<String> tags; // Quick overview tags (e.g., "Great Equipment", "Crowded Evenings")
  final String? vibe; // Overall vibe in 2-3 words (e.g., "Energetic & Social")
  final String? bestFor; // Best suited for (e.g., "Serious Lifters", "Beginners")
  final String? quickTip; // One quick tip (e.g., "Come early for machines")
  final DateTime generatedAt;
  final bool fromCache; // Whether this was retrieved from cache

  const PlaceQuickInsights({
    required this.tags,
    this.vibe,
    this.bestFor,
    this.quickTip,
    required this.generatedAt,
    this.fromCache = false,
  });

  factory PlaceQuickInsights.fromJson(Map<String, dynamic> json) {
    return PlaceQuickInsights(
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      vibe: json['vibe'] as String?,
      bestFor: json['bestFor'] as String?,
      quickTip: json['quickTip'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tags': tags,
        if (vibe != null) 'vibe': vibe,
        if (bestFor != null) 'bestFor': bestFor,
        if (quickTip != null) 'quickTip': quickTip,
        'generatedAt': generatedAt.toIso8601String(),
        'fromCache': fromCache,
      };

  /// Whether the insights are still fresh (< 7 days old)
  bool get isFresh {
    final age = DateTime.now().difference(generatedAt);
    return age.inDays < 7;
  }
}
