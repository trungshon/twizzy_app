import 'package:flutter/material.dart';

/// Notifications Content
///
/// Nội dung màn hình thông báo
class NotificationsContent extends StatelessWidget {
  const NotificationsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications,
              size: 64,
              color: themeData.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Thông báo',
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Danh sách thông báo sẽ hiển thị ở đây',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
