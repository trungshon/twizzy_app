import 'package:flutter/material.dart';

/// Following Tab Content
///
/// Tab hiển thị nội dung từ những người đang theo dõi
class FollowingTab extends StatelessWidget {
  const FollowingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: themeData.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang theo dõi',
            style: themeData.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Nội dung từ những người bạn đang theo dõi sẽ hiển thị ở đây',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.colorScheme.onSurface.withOpacity(
                0.6,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
