import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenAI configuration via environment variables.
/// NOTE: Do not append API paths; the endpoint is used directly.
const apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

/// Result of a moderation check.
class ModerationResult {
  final bool allowed;
  final List<String> categories; // categories or reasons triggered
  final String? reason;

  const ModerationResult(
      {required this.allowed, this.categories = const [], this.reason});

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      allowed: json['allowed'] == true,
      categories: ((json['categories'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      reason: json['reason'] as String?,
    );
  }
}

/// Lightweight OpenAI client for moderation.
/// Uses chat with response_format: json_object to return a strict JSON decision.
class OpenAIClient {
  OpenAIClient();

  Uri get _uri {
    try {
      return Uri.parse(endpoint);
    } catch (_) {
      // Fallback to a dummy URI to avoid crashes; requests will fail cleanly
      return Uri.parse('https://example.invalid');
    }
  }

  Map<String, String> get _headers => {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
      };

  Future<http.Response> _postWithRetry(Map<String, dynamic> body) async {
    const maxAttempts = 3;
    var attempt = 0;
    int delayMs = 600;
    http.Response? last;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        final res = await http.post(_uri,
            headers: _headers, body: utf8.encode(jsonEncode(body)));
        if (res.statusCode < 500 && res.statusCode != 429) return res;
        last = res;
      } catch (e) {
        debugPrint('OpenAI request error (attempt $attempt): $e');
      }
      await Future.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }
    return last ?? http.Response('{"error":"request_failed"}', 500);
  }

  /// Generic text generation for assistant answers (gpt-4o family)
  /// Returns the assistant message content, or a friendly fallback on failure.
  Future<String> generateText({
    required String systemPrompt,
    required String userText,
    String model = 'gpt-4o',
  }) async {
    if (apiKey.isEmpty || endpoint.isEmpty) {
      debugPrint('OpenAI env vars missing; cannot call generateText');
      return 'Sorry, the AI is temporarily unavailable.';
    }

    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText.trim()},
          ]
        }
      ]
    };

    final res = await _postWithRetry(body);
    if (res.statusCode != 200) {
      debugPrint('OpenAI generateText failed: ${res.statusCode} ${res.body}');
      return 'Sorry, the AI is busy. Please try again in a moment.';
    }

    try {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = ((data['choices'] as List).first as Map)['message']
          ['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return 'I couldn\'t generate a response. Please try again.';
      }
      return content.trim();
    } catch (e) {
      debugPrint('OpenAI generateText parse error: $e');
      return 'Sorry, something went wrong parsing the AI response.';
    }
  }

  /// Moderate user-submitted text (reviews, captions, etc.)
  /// Returns [ModerationResult] indicating allow/reject and categories triggered.
  Future<ModerationResult> moderateText(
      {required String text, String context = ''}) async {
    if (apiKey.isEmpty || endpoint.isEmpty) {
      debugPrint('OpenAI env vars missing; allowing by default');
      return const ModerationResult(allowed: true);
    }

    final systemPrompt =
        'You are a strict content moderator. Analyze the user text for policy violations (nudity/sexual content, hate/harassment, violence, spam/scam, PII leaks). '
        'Return ONLY a JSON object with keys: allowed (boolean), categories (string[]), reason (string). '
        'If any severe category is detected, set allowed=false. Keep reason concise.';

    final body = {
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Context: $context'},
            {'type': 'text', 'text': 'UserText: ${text.trim()}'},
          ]
        }
      ]
    };

    final res = await _postWithRetry(body);
    if (res.statusCode != 200) {
      debugPrint(
          'OpenAI text moderation failed: ${res.statusCode} ${res.body}');
      // Fail-open to not block UX; log for troubleshooting.
      return const ModerationResult(allowed: true);
    }
    try {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = ((data['choices'] as List).first as Map)['message']
          ['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return ModerationResult.fromJson(parsed);
    } catch (e) {
      debugPrint('OpenAI text moderation parse error: $e');
      return const ModerationResult(allowed: true);
    }
  }

  /// Moderate images: supports http(s) URLs or data URLs (base64) per the spec.
  Future<ModerationResult> moderateImage({
    required String imageUrlOrData,
    String context = '',
  }) async {
    if (apiKey.isEmpty || endpoint.isEmpty) {
      debugPrint('OpenAI env vars missing; allowing image by default');
      return const ModerationResult(allowed: true);
    }

    final systemPrompt =
        'You are a strict image content moderator. Review the image for policy violations (nudity/sexual content, gore/violence, hate symbols, illegal content, spam). '
        'Return ONLY a JSON object with keys: allowed (boolean), categories (string[]), reason (string). '
        'If any severe category is detected, set allowed=false. Keep reason concise.';

    final content = [
      {'type': 'text', 'text': 'Context: $context'},
      {
        'type': 'image_url',
        'image_url': {
          'url': imageUrlOrData,
        }
      }
    ];

    final body = {
      'model': 'gpt-4o',
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': content}
      ]
    };

    final res = await _postWithRetry(body);
    if (res.statusCode != 200) {
      debugPrint(
          'OpenAI image moderation failed: ${res.statusCode} ${res.body}');
      return const ModerationResult(allowed: true);
    }
    try {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = ((data['choices'] as List).first as Map)['message']
          ['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return ModerationResult.fromJson(parsed);
    } catch (e) {
      debugPrint('OpenAI image moderation parse error: $e');
      return const ModerationResult(allowed: true);
    }
  }
}
