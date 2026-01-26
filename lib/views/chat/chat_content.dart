import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';
import 'chat_detail_screen.dart';

/// Chat Content
class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Socket connection is now handled globally by AuthViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // No need to disconnect here, socket lifecycle is managed globally
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final chatViewModel = context.watch<ChatViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundImage:
                currentUser?.avatar != null
                    ? NetworkImage(currentUser!.avatar!)
                    : null,
            child:
                currentUser?.avatar == null
                    ? Text(
                      currentUser?.name[0].toUpperCase() ?? 'U',
                    )
                    : null,
          ),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_fab',
        onPressed: () {
          // TODO: Start new chat
        },
        child: const Icon(Icons.mail_outline),
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
                decoration: InputDecoration(
                  fillColor: themeData.colorScheme.surface,
                  hintText: 'Tìm kiếm',
                  prefixIcon: const Icon(Icons.search, size: 20),
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
                _buildTabChip('Tất cả', 0),
                const SizedBox(width: 12),
                _buildTabChip('Yêu cầu', 1),
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
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    final themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
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
    );
  }

  Widget _buildChatList(
    ChatViewModel viewModel,
    ThemeData themeData,
  ) {
    if (viewModel.isLoadingList &&
        viewModel.allConversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.allConversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadCurrentConversations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadCurrentConversations,
      child: ListView.builder(
        itemCount: viewModel.allConversations.length,
        itemBuilder: (context, index) {
          final thread = viewModel.allConversations[index];
          return _buildChatItem(
            thread.otherUser.name,
            thread.latestMessage.content,
            _formatTime(thread.latestMessage.createdAt),
            false, // TODO: Add unread logic if backend supports
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
            imageUrl != null ? NetworkImage(imageUrl) : null,
        child:
            imageUrl == null
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
              color: themeData.colorScheme.onSurface.withValues(alpha: 0.6),
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
                color:
                    isUnread
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurface.withValues(alpha: 0.6),
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

    if (viewModel.isLoadingList &&
        viewModel.requestConversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.requestConversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadCurrentConversations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tin nhắn yêu cầu',
                    style: themeData.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tin nhắn từ người không theo dõi bạn sẽ xuất hiện ở đây',
                    textAlign: TextAlign.center,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(
                          color: themeData.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadCurrentConversations,
      child: ListView.builder(
        itemCount: viewModel.requestConversations.length,
        itemBuilder: (context, index) {
          final thread = viewModel.requestConversations[index];
          return _buildChatItem(
            thread.otherUser.name,
            thread.latestMessage.content,
            _formatTime(thread.latestMessage.createdAt),
            true,
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
