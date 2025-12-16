import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/theme.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/services/trip_service.dart';
import 'package:uuid/uuid.dart';
import 'package:fittravel/models/itinerary_item.dart';
import 'package:fittravel/utils/haptic_utils.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (event.websiteUrl != null)
            IconButton(
              icon: const Icon(Icons.public),
              tooltip: 'Website',
              onPressed: () {
                // Web-only placeholder: open in new tab via url_launcher in future
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Open website: ${event.websiteUrl}')),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(child: Text(eventCategoryEmoji(event.category), style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: text.titleMedium),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.event, size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('${event.shortDate} • ${event.shortTime}', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ]),
                    if (event.venueName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.place, size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text(event.venueName, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 16),
          if (event.address != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.address!, style: text.bodyMedium)),
                ],
              ),
            ),

          if (event.description != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
              child: Text(event.description!, style: text.bodyMedium),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add to Trip'),
            onPressed: () => _handleAddToTrip(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToTrip(BuildContext context) async {
    final tripService = context.read<TripService>();
    final active = tripService.activeTrip;
    if (active == null) {
      await HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active trip. Create a trip first.')),
      );
      return;
    }

    // Ensure event date within trip range; if not, still allow but warn.
    final inRange = !event.start.isBefore(active.startDate) && !event.start.isAfter(active.endDate);

    final item = ItineraryItem(
      id: const Uuid().v4(),
      date: DateTime(event.start.year, event.start.month, event.start.day),
      startTime: '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}',
      durationMinutes: 90,
      placeId: null, // local-first: store as custom item snapshot
      title: '${eventCategoryEmoji(event.category)} ${event.title}',
      notes: [
        if (event.venueName.isNotEmpty) 'Venue: ${event.venueName}',
        if (event.address != null) 'Address: ${event.address}',
        if (event.websiteUrl != null) 'Website: ${event.websiteUrl}',
      ].join('\n'),
    );

    await tripService.addItineraryItem(active.id, item);
    await HapticUtils.success();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inRange ? 'Added to ${active.destinationCity} itinerary' : 'Added (outside trip dates)'),
        ),
      );
    }
  }
}
