import 'package:flutter/material.dart';
import 'package:twizzy_app/models/twizz/twizz_models.dart';

/// Mention suggestions widget
class MentionSuggestions extends StatelessWidget {
  final String query;
  final List<SearchUserResult> results;
  final bool isLoading;
  final void Function(SearchUserResult) onSelect;

  const MentionSuggestions({
    super.key,
    required this.query,
    required this.results,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeData.dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(context, themeData),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData themeData,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      if (query.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nhập tên hoặc @username để tìm kiếm',
            style: themeData.textTheme.bodySmall?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không tìm thấy "@$query"',
          style: themeData.textTheme.bodySmall?.copyWith(
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return MentionUserTile(
          user: user,
          onTap: () => onSelect(user),
        );
      },
    );
  }
}

/// Mention user tile widget
class MentionUserTile extends StatelessWidget {
  final SearchUserResult user;
  final VoidCallback onTap;

  const MentionUserTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            // Avatar
            user.avatar != null
                ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(user.avatar!),
                  onBackgroundImageError: (e, s) {},
                )
                : CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      themeData.colorScheme.secondary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onSecondary,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF1DA1F2),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: themeData.textTheme.bodySmall
                        ?.copyWith(
                          color: themeData.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
