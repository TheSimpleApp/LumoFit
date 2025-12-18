import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fittravel/services/ai_guide_service.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/theme.dart';

/// Floating AI chat concierge for the map screen
///
/// Shows a floating button that expands to a chat panel.
/// Provides Egypt-wide fitness recommendations and can highlight
/// places on the map.
class AiMapConcierge extends StatefulWidget {
  final String? destination;
  final double? userLat;
  final double? userLng;
  final void Function(List<SuggestedPlace> places)? onPlacesSuggested;

  const AiMapConcierge({
    super.key,
    this.destination,
    this.userLat,
    this.userLng,
    this.onPlacesSuggested,
  });

  @override
  State<AiMapConcierge> createState() => _AiMapConciergeState();
}

class _AiMapConciergeState extends State<AiMapConcierge>
    with SingleTickerProviderStateMixin {
  final AiGuideService _aiService = AiGuideService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
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

    return _buildExpandedChat(colors);
  }

  Widget _buildFloatingButton(ColorScheme colors) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        heroTag: 'ai_concierge',
        onPressed: _toggleExpanded,
        backgroundColor: colors.primary,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ).animate().scale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildExpandedChat(ColorScheme colors) {
    final quickQuestions = widget.destination != null
        ? _aiService.getQuickQuestionsForDestination(widget.destination!)
        : _aiService.getQuickQuestions();

    return Positioned(
      right: 16,
      bottom: 100,
      child: Container(
        width: 320,
        height: 420,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(colors),

            // Messages
            Expanded(
              child: _buildMessageList(colors, quickQuestions),
            ),

            // Input
            _buildInputArea(colors),
          ],
        ),
      ).animate().scale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Egypt Fitness Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (widget.destination != null)
                  Text(
                    'Exploring ${widget.destination}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: _toggleExpanded,
            visualDensity: VisualDensity.compact,
          ),
        ],
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
      padding: const EdgeInsets.all(12),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask me anything about fitness in Egypt!',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick questions:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickQuestions
                .take(4)
                .map((q) => _buildQuickQuestionChip(q, colors))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionChip(String question, ColorScheme colors) {
    return ActionChip(
      label: Text(
        question,
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: () => _sendMessage(question),
      backgroundColor: colors.primaryContainer.withValues(alpha: 0.5),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMessageBubble(AiChatMessage message, ColorScheme colors) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: colors.primary,
              child: const Icon(Icons.auto_awesome,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? colors.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : colors.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  if (message.suggestedPlaces != null &&
                      message.suggestedPlaces!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSuggestedPlacesChips(message.suggestedPlaces!, colors),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSuggestedPlacesChips(
      List<SuggestedPlace> places, ColorScheme colors) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: places.map((place) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, size: 12, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                place.name,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primary,
            child:
                const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask about fitness in Egypt...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: _isLoading ? null : _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading
                ? null
                : () => _sendMessage(_textController.text),
            icon: Icon(
              Icons.send,
              color: _isLoading
                  ? colors.onSurface.withValues(alpha: 0.3)
                  : colors.primary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
