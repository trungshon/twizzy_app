import 'package:flutter/material.dart';

/// Divider with Text
///
/// Widget hiển thị divider với text ở giữa (ví dụ: "hoặc")
class DividerWithText extends StatelessWidget {
  final String text;
  final Color? color;

  const DividerWithText({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final themeData = Theme.of(context);
    final dividerColor = color ?? themeData.dividerColor;
    final textColor =
        textTheme.bodyMedium?.color ??
        themeData.colorScheme.onSurface;
    return Row(
      children: [
        Expanded(
          child: Divider(color: dividerColor, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: dividerColor, thickness: 1),
        ),
      ],
    );
  }
}
