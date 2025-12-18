import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/services/ai_guide_service.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/theme.dart';

/// Collapsible card showing AI-generated insights for a place
///
/// Lazy loads insights when expanded to minimize API calls.
/// Results are cached server-side for 7 days.
class PlaceInsightsCard extends StatefulWidget {
  final String placeName;
  final String placeType;
  final String destination;
  final String? googlePlaceId;

  const PlaceInsightsCard({
    super.key,
    required this.placeName,
    required this.placeType,
    required this.destination,
    this.googlePlaceId,
  });

  @override
  State<PlaceInsightsCard> createState() => _PlaceInsightsCardState();
}

class _PlaceInsightsCardState extends State<PlaceInsightsCard> {
  final AiGuideService _aiService = AiGuideService();

  bool _isExpanded = false;
  bool _isLoading = false;
  PlaceInsights? _insights;
  String? _errorMessage;

  Future<void> _loadInsights() async {
    if (_insights != null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insights = await _aiService.getPlaceInsights(
        placeName: widget.placeName,
        placeType: widget.placeType,
        destination: widget.destination,
        googlePlaceId: widget.googlePlaceId,
      );

      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load insights';
        _isLoading = false;
      });
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded && _insights == null) {
      _loadInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Local Insider Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'AI-powered recommendations',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(colors),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ColorScheme colors) {
    if (_isLoading) {
      return _buildLoadingState(colors);
    }

    if (_errorMessage != null) {
      return _buildErrorState(colors);
    }

    if (_insights == null) {
      return _buildLoadingState(colors);
    }

    return _buildInsightsContent(colors, _insights!);
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Getting insider tips...',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: colors.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: colors.error),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _insights = null;
              });
              _loadInsights();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(ColorScheme colors, PlaceInsights insights) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Best Times
          _buildInsightSection(
            icon: Icons.access_time,
            title: 'Best Times',
            content: insights.bestTimes,
            colors: colors,
          ),

          // What to Bring
          if (insights.whatToBring.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsightSection(
              icon: Icons.backpack,
              title: 'What to Bring',
              colors: colors,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.whatToBring.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Local Tips
          const SizedBox(height: 16),
          _buildInsightSection(
            icon: Icons.tips_and_updates,
            title: 'Local Tips',
            content: insights.localTips,
            colors: colors,
          ),

          // Hidden Gems
          if (insights.hiddenGems != null && insights.hiddenGems!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsightSection(
              icon: Icons.diamond,
              title: 'Hidden Gem',
              content: insights.hiddenGems!,
              colors: colors,
              highlight: true,
            ),
          ],

          // Fitness Notes
          if (insights.fitnessNotes != null &&
              insights.fitnessNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsightSection(
              icon: Icons.fitness_center,
              title: 'Fitness Notes',
              content: insights.fitnessNotes!,
              colors: colors,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildInsightSection({
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
    required ColorScheme colors,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: highlight
                ? Colors.amber.withValues(alpha: 0.2)
                : colors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: highlight ? Colors.amber[700] : colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: highlight ? Colors.amber[700] : colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              if (content != null)
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              if (child != null) child,
            ],
          ),
        ),
      ],
    );
  }
}
