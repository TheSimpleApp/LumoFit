import 'dart:convert';

/// Represents a planned item in a trip itinerary.
/// Can reference a saved place (placeId) or be a custom note/block.
class ItineraryItem {
  final String id;
  final DateTime date; // Date portion (local)
  final String? startTime; // HH:mm (24h)
  final int? durationMinutes; // Optional duration in minutes
  final String? placeId; // If null, it's a custom item
  final String title; // Place name snapshot or custom title
  final String? notes;

  const ItineraryItem({
    required this.id,
    required this.date,
    this.startTime,
    this.durationMinutes,
    this.placeId,
    required this.title,
    this.notes,
  });

  bool get isPlace => placeId != null;

  ItineraryItem copyWith({
    String? id,
    DateTime? date,
    String? startTime,
    int? durationMinutes,
    String? placeId,
    String? title,
    String? notes,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'startTime': startTime,
        'durationMinutes': durationMinutes,
        'placeId': placeId,
        'title': title,
        'notes': notes,
      };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      placeId: json['placeId'] as String?,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ItineraryItem.fromJsonString(String source) =>
      ItineraryItem.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Create from Supabase JSON (snake_case keys)
  factory ItineraryItem.fromSupabaseJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      placeId: json['place_id'] as String?,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  /// Convert to Supabase JSON (snake_case keys) for insert/update
  Map<String, dynamic> toSupabaseJson(String tripId) {
    return {
      'trip_id': tripId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0],
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'place_id': placeId,
      'title': title,
      'notes': notes,
    };
  }
}
