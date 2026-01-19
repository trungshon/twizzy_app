import 'package:flutter/material.dart';

/// Match type enum
enum MatchType { hashtag, mention }

/// Text match helper class
class TextMatch {
  final int start;
  final int end;
  final MatchType type;

  TextMatch({
    required this.start,
    required this.end,
    required this.type,
  });
}

/// Custom TextEditingController to highlight hashtags and mentions
class HighlightTextController extends TextEditingController {
  // Regex patterns
  static final RegExp _hashtagRegex = RegExp(r'#\w+');
  static final RegExp _mentionRegex = RegExp(r'@\w+');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final text = this.text;

    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    const highlightColor = Color(0xFF1DA1F2);

    // Find all matches
    final List<TextMatch> matches = [];

    // Find hashtags
    for (final match in _hashtagRegex.allMatches(text)) {
      matches.add(
        TextMatch(
          start: match.start,
          end: match.end,
          type: MatchType.hashtag,
        ),
      );
    }

    // Find mentions
    for (final match in _mentionRegex.allMatches(text)) {
      matches.add(
        TextMatch(
          start: match.start,
          end: match.end,
          type: MatchType.mention,
        ),
      );
    }

    // Sort by start position
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Build text spans
    int currentIndex = 0;

    for (final match in matches) {
      // Skip overlapping matches
      if (match.start < currentIndex) continue;

      // Add normal text before match
      if (match.start > currentIndex) {
        children.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: style,
          ),
        );
      }

      // Add highlighted text
      children.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style:
              style?.copyWith(color: highlightColor) ??
              const TextStyle(color: highlightColor),
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      children.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: style,
        ),
      );
    }

    return TextSpan(children: children, style: style);
  }
}
