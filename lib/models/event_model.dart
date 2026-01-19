import 'dart:convert';

/// Categories of active lifestyle events supported in MVP.
enum EventCategory {
  running, // 5K/10K/half/full/trail runs
  yoga, // Yoga classes, retreats
  hiking, // Hiking groups, trail walks
  cycling, // Road cycling, MTB, spin classes
  crossfit, // CrossFit boxes, functional fitness
  bootcamp, // Outdoor bootcamps, group training
  swimming, // Pool workouts, open water
  groupFitness, // Generic group classes
  triathlon, // Tri events, multi-sport
  obstacle, // Spartan, Tough Mudder, OCR
  other,
}

String eventCategoryEmoji(EventCategory c) {
  switch (c) {
    case EventCategory.running:
      return '🏃';
    case EventCategory.yoga:
      return '🧘';
    case EventCategory.hiking:
      return '🥾';
    case EventCategory.cycling:
      return '🚴';
    case EventCategory.crossfit:
      return '💪';
    case EventCategory.bootcamp:
      return '🏋️';
    case EventCategory.swimming:
      return '🏊';
    case EventCategory.groupFitness:
      return '🤸';
    case EventCategory.triathlon:
      return '🏅';
    case EventCategory.obstacle:
      return '🧗';
    case EventCategory.other:
      return '✨';
  }
}

EventCategory eventCategoryFromString(String s) {
  switch (s.toLowerCase()) {
    case 'running':
    case 'run':
    case '5k':
    case '10k':
    case 'marathon':
      return EventCategory.running;
    case 'yoga':
      return EventCategory.yoga;
    case 'hiking':
    case 'hike':
      return EventCategory.hiking;
    case 'cycling':
    case 'bike':
    case 'biking':
      return EventCategory.cycling;
    case 'crossfit':
      return EventCategory.crossfit;
    case 'bootcamp':
    case 'boot_camp':
      return EventCategory.bootcamp;
    case 'swimming':
    case 'swim':
      return EventCategory.swimming;
    case 'groupfitness':
    case 'group_fitness':
    case 'fitness':
    case 'class':
      return EventCategory.groupFitness;
    case 'triathlon':
    case 'tri':
      return EventCategory.triathlon;
    case 'obstacle':
    case 'ocr':
    case 'spartan':
    case 'tough_mudder':
      return EventCategory.obstacle;
    default:
      return EventCategory.other;
  }
}

/// Lightweight event model (local-first). Designed to be Supabase-ready later.
class EventModel {
  final String id;
  final String title;
  final EventCategory category;
  final DateTime start;
  final DateTime? end;
  final String? description;
  final String venueName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? websiteUrl;
  final String? registrationUrl;

  /// Optional image thumbnail (from provider if available)
  final String? imageUrl;

  /// Optional source/provider label (e.g., "eventbrite", "runsignup")
  final String? source;

  /// Distance from user in kilometers (calculated client-side)
  final double? distanceKm;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    this.end,
    this.description,
    required this.venueName,
    this.address,
    this.latitude,
    this.longitude,
    this.websiteUrl,
    this.registrationUrl,
    this.imageUrl,
    this.source,
    this.distanceKm,
  });

  String get shortDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[start.weekday % 7]}, ${months[start.month - 1]} ${start.day}';
  }

  String get shortTime {
    final hour = start.hour;
    final minute = start.minute.toString().padLeft(2, '0');
    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minute AM';
    if (hour == 12) return '12:$minute PM';
    return '${hour - 12}:$minute PM';
  }

  String get distanceLabel =>
      distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km away' : '';

  /// Create a copy with optional field overrides
  EventModel copyWith({
    String? id,
    String? title,
    EventCategory? category,
    DateTime? start,
    DateTime? end,
    String? description,
    String? venueName,
    String? address,
    double? latitude,
    double? longitude,
    String? websiteUrl,
    String? registrationUrl,
    String? imageUrl,
    String? source,
    double? distanceKm,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      registrationUrl: registrationUrl ?? this.registrationUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'description': description,
        'venueName': venueName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'websiteUrl': websiteUrl,
        'registrationUrl': registrationUrl,
        'imageUrl': imageUrl,
        'source': source,
      };

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: eventCategoryFromString(json['category'] as String? ?? 'other'),
      start: DateTime.parse(json['start'] as String),
      end: (json['end'] as String?) != null
          ? DateTime.parse(json['end'] as String)
          : null,
      description: json['description'] as String?,
      venueName: json['venueName'] as String? ?? '',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      websiteUrl: json['websiteUrl'] as String?,
      registrationUrl: json['registrationUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory EventModel.fromJsonString(String source) =>
      EventModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
