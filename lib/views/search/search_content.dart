import 'package:flutter/material.dart';

/// Search Content
///
/// Nội dung màn hình tìm kiếm
class SearchContent extends StatelessWidget {
  const SearchContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: themeData.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm',
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Chức năng tìm kiếm sẽ được triển khai sau',
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
