import 'dart:convert';

/// Categories of active lifestyle events supported in MVP.
enum EventCategory {
  running, // 5K/10K/half/full
  yoga,
  hiking,
  cycling,
  crossfit,
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
    case EventCategory.other:
      return '✨';
  }
}

EventCategory eventCategoryFromString(String s) {
  switch (s) {
    case 'running':
      return EventCategory.running;
    case 'yoga':
      return EventCategory.yoga;
    case 'hiking':
      return EventCategory.hiking;
    case 'cycling':
      return EventCategory.cycling;
    case 'crossfit':
      return EventCategory.crossfit;
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
  });

  String get shortDate => '${start.month}/${start.day}/${start.year}';
  String get shortTime => '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

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
      end: (json['end'] as String?) != null ? DateTime.parse(json['end'] as String) : null,
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
