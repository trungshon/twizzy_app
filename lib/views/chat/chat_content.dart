import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twizzy_app/core/constants/asset_paths.dart';
import 'package:twizzy_app/widgets/common/app_drawer.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';
import 'chat_detail_screen.dart';
import '../../widgets/common/user_avatar_leading.dart';

/// Chat Content
class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Socket connection is now handled globally by AuthViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().clearSearch();
      _searchController.clear();
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser != null) {
        context.read<ChatViewModel>().loadConversationsList(
          authViewModel.currentUser!.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // No need to disconnect here, socket lifecycle is managed globally
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final chatViewModel = context.watch<ChatViewModel>();

    return Theme(
      data: themeData.copyWith(
        drawerTheme: DrawerThemeData(
          scrimColor: themeData.colorScheme.onSurface.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const UserAvatarLeading(),
          leadingWidth: 56,
          centerTitle: true,
          title: const Text(
            'Chat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: const [
            SizedBox(width: 56), // Balance leading
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'chat_fab',
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.newMessage);
          },
          child: Image.asset(
            color: themeData.colorScheme.onPrimary,
            AssetPaths.addMail,
            colorBlendMode: BlendMode.srcIn,
            width: 36,
            height: 36,
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: themeData
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged:
                      (value) => context
                          .read<ChatViewModel>()
                          .setSearchQuery(value),
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                      color: themeData.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                    fillColor: themeData.colorScheme.surface,
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),

            // Custom Tabs
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  _buildTabChip(
                    'Tất cả',
                    0,
                    chatViewModel.unreadAllCount,
                  ),
                  const SizedBox(width: 12),
                  _buildTabChip(
                    'Yêu cầu',
                    1,
                    chatViewModel.unreadRequestCount,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child:
                  _selectedTabIndex == 0
                      ? _buildChatList(chatViewModel, themeData)
                      : _buildRequestList(themeData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, int index, int count) {
    final isSelected = _selectedTabIndex == index;
    final themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? themeData.colorScheme.primary
                      : themeData.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border:
                  isSelected
                      ? null
                      : Border.all(
                        color: themeData.colorScheme.onSurface
                            .withValues(alpha: 0.3),
                      ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? themeData.colorScheme.onPrimary
                        : themeData.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: themeData.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: themeData.colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatList(
    ChatViewModel viewModel,
    ThemeData themeData,
  ) {
    if (viewModel.allConversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadCurrentConversations,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child:
                      viewModel.isLoadingList
                          ? const CircularProgressIndicator()
                          : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 64,
                                color: themeData.disabledColor,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có cuộc trò chuyện nào',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            );
          },
        ),
      );
    }

    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    return RefreshIndicator(
      onRefresh: viewModel.loadCurrentConversations,
      child: ListView.builder(
        itemCount: viewModel.allConversations.length,
        itemBuilder: (context, index) {
          final thread = viewModel.allConversations[index];
          final latest = thread.latestMessage;
          final isUnread =
              !latest.isRead &&
              latest.receiverId == currentUserId;

          return _buildChatItem(
            thread.otherUser.name,
            latest.content,
            _formatTime(latest.createdAt),
            isUnread,
            thread.otherUser.avatar,
            themeData,
            onTap: () {
              Navigator.pushNamed(
                context,
                RouteNames.chatDetail,
                arguments: ChatDetailScreenArgs(
                  otherUser: thread.otherUser,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} p';
    }
    if (difference.inDays < 1) return '${difference.inHours} h';
    return '${time.day}/${time.month}';
  }

  Widget _buildChatItem(
    String name,
    String message,
    String time,
    bool isUnread,
    String? imageUrl,
    ThemeData themeData, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
        child:
            imageUrl == null || imageUrl.isEmpty
                ? Text(name[0].toUpperCase())
                : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: themeData.textTheme.bodySmall?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    isUnread
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    isUnread
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface
                            .withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1DA1F2),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildRequestList(ThemeData themeData) {
    final viewModel = context.watch<ChatViewModel>();

    if (viewModel.requestConversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadCurrentConversations,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child:
                      viewModel.isLoadingList
                          ? const CircularProgressIndicator()
                          : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'Chưa có tin nhắn yêu cầu',
                                style:
                                    themeData
                                        .textTheme
                                        .titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tin nhắn từ người không theo dõi bạn sẽ xuất hiện ở đây',
                                textAlign: TextAlign.center,
                                style: themeData
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: themeData
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                            alpha: 0.6,
                                          ),
                                    ),
                              ),
                            ],
                          ),
                ),
              ),
            );
          },
        ),
      );
    }

    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id;

    return RefreshIndicator(
      onRefresh: viewModel.loadCurrentConversations,
      child: ListView.builder(
        itemCount: viewModel.requestConversations.length,
        itemBuilder: (context, index) {
          final thread = viewModel.requestConversations[index];
          final latest = thread.latestMessage;
          final isUnread =
              !latest.isRead &&
              latest.receiverId == currentUserId;

          return _buildChatItem(
            thread.otherUser.name,
            latest.content,
            _formatTime(latest.createdAt),
            isUnread,
            thread.otherUser.avatar,
            themeData,
            onTap: () {
              Navigator.pushNamed(
                context,
                RouteNames.chatDetail,
                arguments: ChatDetailScreenArgs(
                  otherUser: thread.otherUser,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
