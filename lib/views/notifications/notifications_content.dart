import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/widgets/common/app_drawer.dart';
import 'package:twizzy_app/widgets/common/user_avatar_leading.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../viewmodels/notification/notification_viewmodel.dart';
import '../../models/notification/notification_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../core/utils/media_url_helper.dart';

/// Notifications Content
class NotificationsContent extends StatefulWidget {
  const NotificationsContent({super.key});

  @override
  State<NotificationsContent> createState() =>
      _NotificationsContentState();
}

class _NotificationsContentState
    extends State<NotificationsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  void _showDeleteReadConfirmation(
    BuildContext context,
    NotificationViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa thông báo?'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa tất cả thông báo đã đọc không? Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await viewModel.deleteReadNotifications();
                  if (context.mounted) {
                    SnackBarUtils.showSuccess(
                      context,
                      message: 'Đã xóa các thông báo đã đọc',
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const UserAvatarLeading(),
        centerTitle: true,
        title: Text(
          'Thông báo',
          style: themeData.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await viewModel.markAllAsRead();
                if (context.mounted) {
                  SnackBarUtils.showSuccess(
                    context,
                    message: 'Đã đánh dấu tất cả là đã đọc',
                  );
                }
              } else if (value == 'delete_read') {
                _showDeleteReadConfirmation(context, viewModel);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 8),
                        Text('Đánh dấu tất cả đã đọc'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_outlined,
                          size: 20,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xóa thông báo đã đọc',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 1,
            thickness: 1,
            color: themeData.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            () => viewModel.loadNotifications(refresh: true),
        child: _buildBody(viewModel, themeData),
      ),
    );
  }

  Widget _buildBody(
    NotificationViewModel viewModel,
    ThemeData themeData,
  ) {
    if (viewModel.isLoading && viewModel.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null &&
        viewModel.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: ${viewModel.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      viewModel.loadNotifications(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (viewModel.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: themeData.colorScheme.secondary
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có thông báo nào',
                style: themeData.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                textAlign: TextAlign.center,
                'Các tương tác với bài viết của bạn sẽ xuất hiện ở đây',
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

    return ListView.separated(
      itemCount: viewModel.notifications.length,
      separatorBuilder:
          (context, index) => Divider(
            height: 1,
            color: themeData.dividerColor.withValues(alpha: 0.4),
          ),
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        return _NotificationItem(
          notification: notification,
          onTap:
              () => viewModel.handleNotificationClick(
                notification,
                context,
              ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final sender = notification.sender;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color:
            isUnread
                ? themeData.colorScheme.primary.withValues(
                  alpha: 0.1,
                )
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(notification.type, themeData),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildAvatar(sender, themeData),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: themeData.textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.3,
                                  color:
                                      themeData
                                          .colorScheme
                                          .onSurface,
                                  fontWeight:
                                      isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                            children: [
                              TextSpan(
                                text: sender.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: _getNotificationText(
                                  notification,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' · ${_getTimeAgo(notification.createdAt)}',
                                style: themeData
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: themeData
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                            alpha: 0.6,
                                          ),
                                      fontWeight:
                                          FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: themeData.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 0) {
      return 'Vừa xong';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildTypeIcon(
    NotificationType type,
    ThemeData themeData,
  ) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.like:
        iconData = Icons.favorite_border;
        iconColor = Colors.red;
        break;
      case NotificationType.comment:
        iconData = Icons.chat_bubble_outline;
        iconColor = themeData.colorScheme.primary;
        break;
      case NotificationType.quoteTwizz:
        iconData = Icons.repeat;
        iconColor = Colors.green;
        break;
      case NotificationType.follow:
        iconData = Icons.person_add_outlined;
        iconColor = themeData.colorScheme.secondary;
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email_outlined;
        iconColor = Colors.purple;
        break;
    }

    return Icon(iconData, color: iconColor, size: 28);
  }

  Widget _buildAvatar(dynamic user, ThemeData themeData) {
    final String? avatar = user.avatar;
    final String name = user.name ?? 'U';

    if (avatar != null && avatar.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(
          MediaUrlHelper.normalizeUrl(avatar),
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: themeData.colorScheme.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 12,
          color: themeData.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getNotificationText(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.like:
        return ' đã thích bài viết của bạn';
      case NotificationType.comment:
        if (notification.twizz?.type == TwizzType.comment) {
          return ' đã trả lời bình luận của bạn';
        }
        return ' đã bình luận bài viết của bạn';
      case NotificationType.quoteTwizz:
        return ' đã trích dẫn bài viết của bạn';
      case NotificationType.follow:
        return ' đã bắt đầu theo dõi bạn';
      case NotificationType.mention:
        return ' đã nhắc đến bạn trong một bài viết';
    }
  }
}
