import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;
  final VoidCallback? onTap;
  final bool isFollowing;

  const UserListItem({
    super.key,
    required this.user,
    this.onFollow,
    this.onUnfollow,
    this.onTap,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            (user.avatar != null && user.avatar!.isNotEmpty)
                ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(user.avatar!),
                  onBackgroundImageError: (e, s) {},
                )
                : CircleAvatar(
                  radius: 20,
                  backgroundColor: themeData.colorScheme.primary,
                  child: Text(
                    (user.name.trim().isNotEmpty)
                        ? user.name.trim()[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onPrimary,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: themeData.textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.verify == 'Verified') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: themeData.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user.bio != null &&
                      user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: themeData.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Follow Button (hide for current user)
            if (onFollow != null || onUnfollow != null)
              _buildFollowButton(themeData),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(ThemeData theme) {
    final isFollowed = isFollowing;

    return ElevatedButton(
      onPressed: isFollowed ? onUnfollow : onFollow,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        backgroundColor:
            isFollowed
                ? theme.colorScheme.surface
                : theme.colorScheme.primary,
        foregroundColor:
            isFollowed
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onPrimary,
        side: BorderSide(
          color:
              isFollowed
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.primary,
        ),
      ),
      child: Text(isFollowed ? 'Đang theo dõi' : 'Theo dõi'),
    );
  }
}
