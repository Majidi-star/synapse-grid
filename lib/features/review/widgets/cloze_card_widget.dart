import 'package:flutter/material.dart';

class ClozeCardWidget extends StatelessWidget {
  final String text;
  final int? targetIndex;
  final bool isBack;
  final TextStyle? style;

  const ClozeCardWidget({
    Key? key,
    required this.text,
    this.targetIndex,
    required this.isBack,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isBack || targetIndex == null) {
      // Front side rendering
      final spans = <InlineSpan>[];
      final regex = RegExp(r'\[\.\.\.\]');
      int lastIndex = 0;

      for (final match in regex.allMatches(text)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3C36C).withOpacity(0.15),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE3C36C), width: 1.5),
                ),
              ),
              child: const Text(
                ' [...] ',
                style: TextStyle(
                  color: Color(0xFFE3C36C),
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
        lastIndex = match.end;
      }

      if (lastIndex < text.length) {
        spans.add(TextSpan(text: text.substring(lastIndex)));
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: style?.copyWith(color: const Color(0xFFE7E2DA)),
          children: spans.isEmpty ? [TextSpan(text: text)] : spans,
        ),
      );
    } else {
      // Back side rendering with highlighted answer
      final regex = RegExp(r'\{\{c(\d+)::(.*?)\}\}');
      final spans = <InlineSpan>[];
      int lastIndex = 0;

      for (final match in regex.allMatches(text)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
        }

        final index = int.parse(match.group(1)!);
        final answer = match.group(2)!;

        if (index == targetIndex) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3C36C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE3C36C), width: 1),
                ),
                child: Text(
                  answer,
                  style: const TextStyle(
                    color: Color(0xFFFFDF8C),
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        } else {
          spans.add(TextSpan(text: answer));
        }
        lastIndex = match.end;
      }

      if (lastIndex < text.length) {
        spans.add(TextSpan(text: text.substring(lastIndex)));
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: style?.copyWith(color: const Color(0xFFE7E2DA)),
          children: spans.isEmpty ? [TextSpan(text: text)] : spans,
        ),
      );
    }
  }
}
