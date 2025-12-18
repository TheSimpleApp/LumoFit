import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fittravel/services/ai_guide_service.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/theme.dart';

/// Modern bottom sheet AI concierge for the map screen
///
/// Shows a floating button that expands to a draggable bottom sheet.
/// Provides Egypt-wide fitness recommendations and can highlight
/// places on the map.
class AiMapConcierge extends StatefulWidget {
  final String? destination;
  final double? userLat;
  final double? userLng;
  final void Function(List<SuggestedPlace> places)? onPlacesSuggested;
  final void Function(SuggestedPlace place)? onPlaceTapped;
  final bool isBottomSheetOpen;

  const AiMapConcierge({
    super.key,
    this.destination,
    this.userLat,
    this.userLng,
    this.onPlacesSuggested,
    this.onPlaceTapped,
    this.isBottomSheetOpen = false,
  });

  @override
  State<AiMapConcierge> createState() => _AiMapConciergeState();
}

class _AiMapConciergeState extends State<AiMapConcierge>
    with SingleTickerProviderStateMixin {
  final AiGuideService _aiService = AiGuideService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  void didUpdateWidget(AiMapConcierge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapse chat when bottom sheet opens
    if (widget.isBottomSheetOpen &&
        !oldWidget.isBottomSheetOpen &&
        _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isExpanded = false);
        }
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _textController.clear();
    setState(() => _isLoading = true);

    try {
      final response = await _aiService.askEgyptGuide(
        question: message,
        destination: widget.destination,
        userLat: widget.userLat,
        userLng: widget.userLng,
      );

      // Notify parent about suggested places to highlight on map
      if (response.suggestedPlaces.isNotEmpty &&
          widget.onPlacesSuggested != null) {
        widget.onPlacesSuggested!(response.suggestedPlaces);
      }
    } catch (e) {
      debugPrint('AiMapConcierge error: $e');
    }

    setState(() => _isLoading = false);

    // Scroll to bottom after new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    if (!_isExpanded) {
      return _buildFloatingButton(colors);
    }

    return _buildBottomSheet(colors);
  }

  Widget _buildFloatingButton(ColorScheme colors) {
    // Keep the "pillow" tucked just above the system safe area.
    // If the place preview sheet is open, lift above it.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final obstruction = widget.isBottomSheetOpen ? 220.0 : 0.0;
    final bottomOffset = obstruction + safeBottom + 16.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: Center(
        child: Hero(
          tag: 'ai_concierge_hero',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Fitness Guide',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().scale(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
            ).shimmer(
              duration: const Duration(milliseconds: 1500),
              delay: const Duration(milliseconds: 500),
            ),
      ),
    );
  }

  Widget _buildBottomSheet(ColorScheme colors) {
    final quickQuestions = widget.destination != null
        ? _aiService.getQuickQuestionsForDestination(widget.destination!)
        : _aiService.getQuickQuestions();

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (context, scrollController) {
        return Hero(
          tag: 'ai_concierge_hero',
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle and header
                  _buildSheetHeader(colors),

                  // Messages
                  Expanded(
                    child: _buildMessageList(colors, quickQuestions),
                  ),

                  // Input area with safe area
                  SafeArea(
                    child: _buildInputArea(colors),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _buildSheetHeader(ColorScheme colors) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header content
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Egypt Fitness Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (widget.destination != null)
                        Text(
                          'Exploring ${widget.destination}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: _toggleExpanded,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMessageList(ColorScheme colors, List<String> quickQuestions) {
    final messages = _aiService.conversationHistory;

    if (messages.isEmpty) {
      return _buildWelcomeState(colors, quickQuestions);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == messages.length) {
          return _buildLoadingIndicator(colors);
        }

        final message = messages[index];
        return _buildMessageBubble(message, colors);
      },
    );
  }

  Widget _buildWelcomeState(ColorScheme colors, List<String> quickQuestions) {
    // Starter message examples
    final starterExamples = [
      {
        'icon': Icons.fitness_center,
        'text': 'Best gyms near me',
        'subtitle': 'Find top-rated fitness centers',
      },
      {
        'icon': Icons.restaurant,
        'text': 'Healthy restaurants in ${widget.destination ?? 'Egypt'}',
        'subtitle': 'Discover nutritious dining spots',
      },
      {
        'icon': Icons.directions_run,
        'text': 'Where can I go running?',
        'subtitle': 'Explore trails and parks',
      },
      {
        'icon': Icons.event,
        'text': 'Upcoming fitness events',
        'subtitle': 'Join local fitness activities',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.2),
                    colors.tertiary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 48,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Welcome text
          Text(
            '👋 Hi! I\'m your fitness travel guide.',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Let me help you find the perfect places! I\'ll ask a few quick questions to personalize your recommendations.',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildStartButton(colors),
          const SizedBox(height: 32),
          Divider(color: colors.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            'Try these examples:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Starter message examples
          ...starterExamples.map((example) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _sendMessage(example['text'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          example['icon'] as IconData,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              example['text'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              example['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStartButton(ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _sendMessage('Start guided search'),
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text(
          'Start Guided Search',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message, ColorScheme colors) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primary,
              child:
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? colors.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 15,
                      ),
                      h1: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      code: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        backgroundColor:
                            (isUser ? Colors.white : colors.surface)
                                .withValues(alpha: 0.2),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    selectable: true,
                  ),
                  if (message.suggestedPlaces != null &&
                      message.suggestedPlaces!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSuggestedPlacesCards(
                        message.suggestedPlaces!, colors),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestedPlacesCards(
      List<SuggestedPlace> places, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recommended Places',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...places.map((place) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (widget.onPlaceTapped != null) {
                    widget.onPlaceTapped!(place);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withValues(alpha: 0.2),
                              colors.primary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getPlaceIcon(place.type),
                          size: 28,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            if (place.neighborhood != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      place.neighborhood!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (place.type.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  place.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onPrimaryContainer,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'gym':
        return Icons.fitness_center;
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'park':
      case 'trail':
        return Icons.directions_run;
      case 'event':
        return Icons.event;
      default:
        return Icons.place;
    }
  }

  Widget _buildLoadingIndicator(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primary,
            child:
                const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask about fitness in Egypt...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 15),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isLoading ? null : _sendMessage,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isLoading ? colors.surfaceContainerHighest : null,
              shape: BoxShape.circle,
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: IconButton(
              onPressed:
                  _isLoading ? null : () => _sendMessage(_textController.text),
              icon: Icon(
                Icons.send_rounded,
                color: _isLoading
                    ? colors.onSurface.withValues(alpha: 0.3)
                    : Colors.white,
                size: 22,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
