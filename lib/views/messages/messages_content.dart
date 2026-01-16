import 'package:flutter/material.dart';

/// Messages Content
///
/// Nội dung màn hình tin nhắn
class MessagesContent extends StatelessWidget {
  const MessagesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 64,
              color: themeData.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tin nhắn',
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Danh sách tin nhắn sẽ hiển thị ở đây',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
