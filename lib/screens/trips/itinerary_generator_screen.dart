import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fittravel/services/ai_guide_service.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/theme.dart';

/// Screen to generate AI-powered fitness itineraries for any destination
class ItineraryGeneratorScreen extends StatefulWidget {
  final String? initialDestination;
  final DateTime? initialDate;

  const ItineraryGeneratorScreen({
    super.key,
    this.initialDestination,
    this.initialDate,
  });

  @override
  State<ItineraryGeneratorScreen> createState() =>
      _ItineraryGeneratorScreenState();
}

class _ItineraryGeneratorScreenState extends State<ItineraryGeneratorScreen> {
  final AiGuideService _aiService = AiGuideService();

  String? _selectedDestination;
  DateTime _selectedDate = DateTime.now();
  String _fitnessLevel = 'intermediate';
  final Set<String> _focusAreas = {};

  bool _isGenerating = false;
  ItineraryResponse? _generatedItinerary;
  String? _errorMessage;

  final List<String> _destinations = [
    'New York',
    'Los Angeles',
    'London',
    'Paris',
    'Tokyo',
    'Sydney',
    'Dubai',
    'Barcelona',
  ];

  final List<String> _fitnessLevels = ['beginner', 'intermediate', 'advanced'];

  final Map<String, IconData> _focusAreaOptions = {
    'strength': Icons.fitness_center,
    'cardio': Icons.directions_run,
    'yoga': Icons.self_improvement,
    'outdoor': Icons.terrain,
    'water': Icons.pool,
    'recovery': Icons.spa,
  };

  @override
  void initState() {
    super.initState();
    _selectedDestination = widget.initialDestination;
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  Future<void> _generateItinerary() async {
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedItinerary = null;
    });

    try {
      final itinerary = await _aiService.generateItinerary(
        destination: _selectedDestination!,
        date: _selectedDate,
        fitnessLevel: _fitnessLevel,
        focusAreas: _focusAreas.toList(),
      );

      setState(() {
        _generatedItinerary = itinerary;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate itinerary. Please try again.';
        _isGenerating = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Fitness Day'),
        actions: [
          if (_generatedItinerary != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateItinerary,
              tooltip: 'Regenerate',
            ),
        ],
      ),
      body: _generatedItinerary != null
          ? _buildItineraryView(colors)
          : _buildGeneratorForm(colors),
    );
  }

  Widget _buildGeneratorForm(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Fitness Planner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Create a personalized active day anywhere',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Destination selector
          Text(
            'Destination',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedDestination,
            decoration: InputDecoration(
              hintText: 'Select destination',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.place),
            ),
            items: _destinations.map((dest) {
              return DropdownMenuItem(value: dest, child: Text(dest));
            }).toList(),
            onChanged: (value) => setState(() => _selectedDestination = value),
          ),

          const SizedBox(height: 20),

          // Date selector
          Text(
            'Date',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colors.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.edit, size: 18, color: colors.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Fitness level
          Text(
            'Fitness Level',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: _fitnessLevels.map((level) {
              return ButtonSegment(
                value: level,
                label: Text(level[0].toUpperCase() + level.substring(1)),
              );
            }).toList(),
            selected: {_fitnessLevel},
            onSelectionChanged: (selection) {
              setState(() => _fitnessLevel = selection.first);
            },
          ),

          const SizedBox(height: 20),

          // Focus areas
          Text(
            'Focus Areas (optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _focusAreaOptions.entries.map((entry) {
              final isSelected = _focusAreas.contains(entry.key);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(entry.value, size: 16),
                    const SizedBox(width: 6),
                    Text(entry.key[0].toUpperCase() + entry.key.substring(1)),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _focusAreas.add(entry.key);
                    } else {
                      _focusAreas.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateItinerary,
              icon: _isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label:
                  Text(_isGenerating ? 'Generating...' : 'Generate Itinerary'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItineraryView(ColorScheme colors) {
    final itinerary = _generatedItinerary!;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itinerary.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${itinerary.destination} • ${DateFormat('MMMM d').format(_selectedDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        Icons.schedule,
                        '${(itinerary.totalDurationMinutes / 60).toStringAsFixed(1)}h',
                        colors,
                      ),
                      _buildStatChip(
                        Icons.list,
                        '${itinerary.items.length} activities',
                        colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Timeline
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = itinerary.items[index];
                final isLast = index == itinerary.items.length - 1;
                return _buildTimelineItem(item, colors, isLast)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 100 * index))
                    .slideX(begin: 0.1, end: 0);
              },
              childCount: itinerary.items.length,
            ),
          ),
        ),

        // Packing list
        if (itinerary.packingList.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildPackingList(itinerary.packingList, colors),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      ItineraryPlanItem item, ColorScheme colors, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getItemColor(item.type, colors),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.type.emoji,
                      style: const TextStyle(fontSize: 6),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.type.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.duration} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (item.tips != null && item.tips!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.tips!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(ItineraryItemType type, ColorScheme colors) {
    switch (type) {
      case ItineraryItemType.activity:
        return Colors.orange;
      case ItineraryItemType.meal:
        return Colors.green;
      case ItineraryItemType.rest:
        return Colors.purple;
      case ItineraryItemType.travel:
        return Colors.blue;
      case ItineraryItemType.other:
        return colors.primary;
    }
  }

  Widget _buildPackingList(List<String> items, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backpack, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Packing List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(item, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
