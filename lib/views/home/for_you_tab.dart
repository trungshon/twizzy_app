import 'package:flutter/material.dart';
import 'package:twizzy_app/widgets/twizz/twizz_list.dart';
import '../../models/twizz/twizz_models.dart';

/// For You Tab Content
///
/// Tab hiển thị nội dung đề xuất cho người dùng (tạm thời để trống)
class ForYouTab extends StatelessWidget {
  const ForYouTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return TwizzList(
      twizzs: const <Twizz>[],
      isLoading: false,
      hasMore: false,
      emptyWidget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài viết đề xuất',
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Text(
                'Nội dung đề xuất sẽ hiển thị ở đây',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
