import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fittravel/services/services.dart';
import 'package:fittravel/models/ai_models.dart';
import 'package:fittravel/models/place_model.dart';

/// Fitness Guide - AI-powered fitness recommendations for any location
/// Formerly CairoGuideScreen, now location-aware
class FitnessGuideScreen extends StatefulWidget {
  const FitnessGuideScreen({super.key});

  @override
  State<FitnessGuideScreen> createState() => _FitnessGuideScreenState();
}

class _FitnessGuideScreenState extends State<FitnessGuideScreen> {
  static const String _conversationKey = 'fitness_guide_conversation';

  final AiGuideService _aiGuide = AiGuideService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Use AiChatMessage model to support structured data like suggested places
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;

  // Location-aware destination
  String _currentDestination = 'your area';

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _initDestination();

    // Listen for trip changes to update destination
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripService>().addListener(_onTripChanged);
    });
  }

  /// Initialize destination from active trip or default
  void _initDestination() {
    final tripService = context.read<TripService>();
    final activeTrip = tripService.activeTrip;
    if (activeTrip != null) {
      setState(() {
        _currentDestination = activeTrip.destinationCity;
      });
    } else {
      setState(() {
        _currentDestination = 'your area';
      });
    }
  }

  void _onTripChanged() {
    _initDestination();
  }

  @override
  void dispose() {
    context.read<TripService>().removeListener(_onTripChanged);
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load conversation from SharedPreferences
  Future<void> _loadConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final messages = jsonList
            .map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

        // Clean up any messages that might have raw JSON as content
        final cleanedMessages = messages.map((msg) {
          if (!msg.isUser && msg.content.trimLeft().startsWith('{')) {
            // Try to extract text from raw JSON content
            try {
              final parsed = json.decode(msg.content);
              if (parsed is Map && parsed['text'] != null) {
                return AiChatMessage(
                  id: msg.id,
                  content: parsed['text'] as String,
                  isUser: msg.isUser,
                  timestamp: msg.timestamp,
                  suggestedPlaces: msg.suggestedPlaces,
                  elements: msg.elements,
                );
              }
            } catch (_) {
              // Not valid JSON, keep as is
            }
          }
          return msg;
        }).toList();

        if (mounted && cleanedMessages.isNotEmpty) {
          setState(() {
            _messages.addAll(cleanedMessages);
          });
          // Scroll to bottom after loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    }
  }

  /// Save conversation to SharedPreferences
  Future<void> _saveConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(_conversationKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  /// Clear conversation and remove from storage
  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
            'Are you sure you want to clear the conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationKey);
      _aiGuide.clearHistory();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _messages.add(AiChatMessage.user(question));
      _isLoading = true;
    });

    _questionController.clear();
    _saveConversation();

    // Scroll to bottom to show user message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      // Use askEgyptGuide to get structured response with suggested places
      final response = await _aiGuide.askEgyptGuide(
        question: question,
        destination: _currentDestination, // Use active trip destination or user's area
      );

      if (mounted) {
        // Build elements list from response
        final elements = <MessageElement>[];

        // Add tags if available
        if (response.tags != null && response.tags!.isNotEmpty) {
          elements.add(MessageElement.tags(response.tags!));
        }

        // Add quick replies if available
        if (response.quickReplies != null &&
            response.quickReplies!.isNotEmpty) {
          elements.add(MessageElement.quickReplies(response.quickReplies!));
        }

        // Add custom elements if available
        if (response.elements != null) {
          elements.addAll(response.elements!);
        }

        // Add places if available
        if (response.suggestedPlaces.isNotEmpty) {
          elements.add(MessageElement.places(response.suggestedPlaces));
        }

        // Final safety check: ensure text isn't raw JSON
        // This handles edge cases where parsing didn't catch nested JSON
        String cleanText = response.text;
        if (cleanText.trimLeft().startsWith('{')) {
          try {
            final parsed = json.decode(cleanText);
            if (parsed is Map && parsed['text'] != null) {
              cleanText = parsed['text'] as String;
            }
          } catch (_) {
            // Not valid JSON, use as-is
          }
        }

        setState(() {
          _messages.add(AiChatMessage.assistant(
            cleanText,
            suggestedPlaces: response.suggestedPlaces,
            elements: elements.isEmpty ? null : elements,
          ));
          _isLoading = false;
        });

        _saveConversation();

        // Scroll to bottom to show assistant response
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage.assistant(
            'Sorry, something went wrong. Please try again.',
          ));
          _isLoading = false;
        });
        _saveConversation();
      }
    }
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = _aiGuide.getQuickQuestions();
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Quick Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: quickQuestions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(quickQuestions[index]),
                  onPressed: () => _askQuestion(quickQuestions[index]),
                  backgroundColor: colors.surfaceContainerHighest,
                  side:
                      BorderSide(color: colors.outline.withValues(alpha: 0.3)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(AiChatMessage message, ColorScheme colors) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
          bottom: 12,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isUser ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main text content
            if (message.content.isNotEmpty)
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontSize: 15,
                  ),
                  h1: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  code: TextStyle(
                    color:
                        isUser ? colors.onPrimaryContainer : colors.onSurface,
                    backgroundColor: (isUser
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest)
                        .withValues(alpha: 0.3),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                selectable: true,
              ),

            // Render interactive elements
            if (!isUser &&
                message.elements != null &&
                message.elements!.isNotEmpty)
              ...message.elements!.map(
                  (element) => _buildMessageElement(element, colors, message)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageElement(
      MessageElement element, ColorScheme colors, AiChatMessage message) {
    switch (element.type) {
      case MessageElementType.text:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            element.text ?? '',
            style: TextStyle(color: colors.onSurface, fontSize: 15),
          ),
        );

      case MessageElementType.image:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  element.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: colors.surfaceContainer,
                      child: Center(
                        child: Icon(Icons.broken_image,
                            color: colors.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
              if (element.text != null) ...[
                const SizedBox(height: 8),
                Text(
                  element.text!,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );

      case MessageElementType.quickReplies:
        return _buildQuickReplies(element.quickReplies ?? [], colors);

      case MessageElementType.singleSelect:
        return _buildSingleSelect(element.selectOption!, colors, message);

      case MessageElementType.multiSelect:
        return _buildMultiSelect(element.selectOption!, colors, message);

      case MessageElementType.places:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSuggestedPlaces(element.places ?? [], colors),
        );

      case MessageElementType.tags:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: _buildTags(element.tags ?? [], colors),
        );
    }
  }

  Widget _buildTags(List<String> tags, ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickReplies(List<QuickReply> replies, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: replies.map((reply) {
          return ActionChip(
            avatar: reply.emoji != null
                ? Text(reply.emoji!, style: const TextStyle(fontSize: 16))
                : null,
            label: Text(reply.text),
            onPressed: () => _askQuestion(reply.value ?? reply.text),
            backgroundColor: colors.surface,
            side: BorderSide(
                color: colors.primary.withValues(alpha: 0.5), width: 1.5),
            labelStyle: TextStyle(
              fontSize: 13,
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleSelect(
      SelectOption option, ColorScheme colors, AiChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.question,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...option.choices.map((choice) {
            final isSelected = option.selectedIds.contains(choice.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  // Update selection and send response
                  _askQuestion(choice.text);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colors.primaryContainer : colors.surface,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (choice.emoji != null) ...[
                        Text(choice.emoji!,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.text,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (choice.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                choice.description!,
                                style: TextStyle(
                                  color: isSelected
                                      ? colors.onPrimaryContainer
                                          .withValues(alpha: 0.8)
                                      : colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: colors.primary, size: 20),
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

  Widget _buildMultiSelect(
      SelectOption option, ColorScheme colors, AiChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.question,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...option.choices.map((choice) {
            final isSelected = option.selectedIds.contains(choice.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    // Toggle selection
                    final newSelected = List<String>.from(option.selectedIds);
                    if (isSelected) {
                      newSelected.remove(choice.id);
                    } else {
                      newSelected.add(choice.id);
                    }

                    // Update the message element
                    final elementIndex = message.elements!.indexWhere((e) =>
                        e.type == MessageElementType.multiSelect &&
                        e.selectOption?.id == option.id);
                    if (elementIndex != -1) {
                      message.elements![elementIndex] =
                          MessageElement.multiSelect(
                        option.copyWithSelected(newSelected),
                      );
                    }
                  });
                  _saveConversation();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colors.primaryContainer : colors.surface,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: null, // Handled by InkWell
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (isSelected) return colors.primary;
                          return colors.surface;
                        }),
                      ),
                      const SizedBox(width: 8),
                      if (choice.emoji != null) ...[
                        Text(choice.emoji!,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.text,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (choice.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                choice.description!,
                                style: TextStyle(
                                  color: isSelected
                                      ? colors.onPrimaryContainer
                                          .withValues(alpha: 0.8)
                                      : colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () {
                // Build a summary of selections
                final selectedTexts = option.choices
                    .where((c) => option.selectedIds.contains(c.id))
                    .map((c) => c.text)
                    .join(', ');
                if (selectedTexts.isNotEmpty) {
                  _askQuestion('I selected: $selectedTexts');
                }
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPlaces(
      List<SuggestedPlace> places, ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: places.map((place) {
        return ActionChip(
          avatar:
              Icon(_getPlaceIcon(place.type), size: 16, color: colors.primary),
          label: Text(place.name),
          onPressed: () => _handlePlaceTap(place),
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
          labelStyle: TextStyle(
            fontSize: 12,
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
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

  void _handlePlaceTap(SuggestedPlace place) {
    // If it has a Google Place ID or coordinates, we could try to open details
    // For now, let's open the Place Detail screen with a temporary model
    // In a real app, you might fetch full details first

    // Create a temporary PlaceModel to pass to detail screen
    final placeModel = PlaceModel(
      id: place.googlePlaceId ?? 'temp_${place.name.hashCode}',
      name: place.name,
      type: _parsePlaceType(place.type),
      latitude: place.lat,
      longitude: place.lng,
      address: place.neighborhood,
      notes: 'Recommended by Cairo Guide',
      rating: 0,
      userRatingsTotal: 0,
      isVisited: false,
    );

    context.push('/place-detail', extra: placeModel);
  }

  PlaceType _parsePlaceType(String type) {
    switch (type.toLowerCase()) {
      case 'gym':
        return PlaceType.gym;
      case 'restaurant':
      case 'food':
        return PlaceType.restaurant;
      case 'park':
        return PlaceType.park;
      case 'trail':
        return PlaceType.trail;
      default:
        return PlaceType.gym; // Default
    }
  }

  Widget _buildEmptyState(ColorScheme colors, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fitness Guide',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Get AI-powered recommendations for gyms, restaurants, events, and activities in $_currentDestination',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Try asking:',
              style: textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• "Best gyms nearby?"\n'
              '• "Healthy restaurants near me?"\n'
              '• "Where can I run?"',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, color: colors.primary),
            const SizedBox(width: 8),
            Text('Fitness Guide${_currentDestination != 'your area' ? ' - $_currentDestination' : ''}'),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear conversation',
              onPressed: _clearConversation,
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick Questions
          if (_messages.isEmpty) _buildQuickQuestions(),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(colors, textTheme)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index], colors);
                    },
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'Ask about fitness in $_currentDestination...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _askQuestion,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: () => _askQuestion(_questionController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
