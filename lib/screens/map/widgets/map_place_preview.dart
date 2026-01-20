import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fittravel/models/place_model.dart';
import 'package:fittravel/models/event_model.dart';
import 'package:fittravel/theme.dart';

/// Bottom sheet preview when a marker is tapped
class MapPlacePreview extends StatefulWidget {
  final dynamic item; // PlaceModel or EventModel
  final VoidCallback onClose;

  const MapPlacePreview({
    super.key,
    required this.item,
    required this.onClose,
  });

  @override
  State<MapPlacePreview> createState() => _MapPlacePreviewState();
}

class _MapPlacePreviewState extends State<MapPlacePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isPlace = widget.item is PlaceModel;
    final isEvent = widget.item is EventModel;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(colors),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getEmoji(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTypeLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _handleClose,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    _getTitle(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Subtitle (address or venue)
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Rating (for places)
                  if (isPlace &&
                      (widget.item as PlaceModel).rating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          (widget.item as PlaceModel)
                              .rating!
                              .toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if ((widget.item as PlaceModel).userRatingsTotal !=
                            null) ...[
                          Text(
                            ' (${(widget.item as PlaceModel).userRatingsTotal} reviews)',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Event date
                  if (isEvent) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatEventDate((widget.item as EventModel).start),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(context),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Directions'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openDetails(context),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    if (widget.item is PlaceModel) return (widget.item as PlaceModel).name;
    if (widget.item is EventModel) return (widget.item as EventModel).title;
    return 'Unknown';
  }

  String _getSubtitle() {
    if (widget.item is PlaceModel) {
      return (widget.item as PlaceModel).address ?? '';
    }
    if (widget.item is EventModel) {
      final event = widget.item as EventModel;
      return event.venueName.isNotEmpty
          ? event.venueName
          : (event.address ?? '');
    }
    return '';
  }

  String _getTypeLabel() {
    if (widget.item is PlaceModel) {
      switch ((widget.item as PlaceModel).type) {
        case PlaceType.gym:
          return 'Gym';
        case PlaceType.restaurant:
          return 'Food';
        case PlaceType.trail:
          return 'Trail';
        case PlaceType.park:
          return 'Park';
        default:
          return 'Place';
      }
    }
    if (widget.item is EventModel) {
      return (widget.item as EventModel).category.name.toUpperCase();
    }
    return 'Place';
  }

  String _getEmoji() {
    if (widget.item is PlaceModel) {
      switch ((widget.item as PlaceModel).type) {
        case PlaceType.gym:
          return '💪';
        case PlaceType.restaurant:
          return '🥗';
        case PlaceType.trail:
          return '🥾';
        case PlaceType.park:
          return '🌳';
        default:
          return '📍';
      }
    }
    if (widget.item is EventModel) {
      return eventCategoryEmoji((widget.item as EventModel).category);
    }
    return '📍';
  }

  Color _getBadgeColor(ColorScheme colors) {
    if (widget.item is PlaceModel) {
      switch ((widget.item as PlaceModel).type) {
        case PlaceType.gym:
          return Colors.blue.withValues(alpha: 0.2);
        case PlaceType.restaurant:
          return Colors.orange.withValues(alpha: 0.2);
        case PlaceType.trail:
        case PlaceType.park:
          return Colors.green.withValues(alpha: 0.2);
        default:
          return colors.primaryContainer;
      }
    }
    if (widget.item is EventModel) {
      return Colors.purple.withValues(alpha: 0.2);
    }
    return colors.primaryContainer;
  }

  String _formatEventDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _openDirections(BuildContext context) async {
    double? lat, lng;

    if (widget.item is PlaceModel) {
      final place = widget.item as PlaceModel;
      lat = place.latitude;
      lng = place.longitude;
    } else if (widget.item is EventModel) {
      final event = widget.item as EventModel;
      lat = event.latitude;
      lng = event.longitude;
    }

    if (lat != null && lng != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openDetails(BuildContext context) {
    if (widget.item is PlaceModel) {
      context.push('/place-detail', extra: widget.item);
    } else if (widget.item is EventModel) {
      context.push('/event-detail', extra: widget.item);
    }
  }
}
