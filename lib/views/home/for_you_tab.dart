import 'package:flutter/material.dart';

/// For You Tab Content
///
/// Tab hiển thị nội dung đề xuất cho người dùng
class ForYouTab extends StatelessWidget {
  const ForYouTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore,
            size: 64,
            color: themeData.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Đề xuất',
            style: themeData.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Nội dung đề xuất sẽ hiển thị ở đây',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withOpacity(
                0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
