import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style ?? TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      );
    }

    final String textLower = text.toLowerCase();
    final String queryLower = query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = textLower.indexOf(queryLower, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfMatch),
          style: style ?? TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: highlightStyle ??
            TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
              fontSize: 16,
            ),
      ));

      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style ?? TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: style ?? TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ),
    );
  }
}
