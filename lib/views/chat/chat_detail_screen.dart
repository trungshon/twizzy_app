import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth/auth_models.dart';
import '../../models/chat/chat_models.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../services/chat_service/chat_service.dart';

class ChatDetailScreenArgs {
  final User otherUser;

  ChatDetailScreenArgs({required this.otherUser});
}

class ChatDetailScreen extends StatefulWidget {
  final ChatDetailScreenArgs args;

  const ChatDetailScreen({super.key, required this.args});

  @override
  State<ChatDetailScreen> createState() =>
      _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Conversation> _messages = [];
  bool _isLoading = false;
  bool _isAccepted = true;
  ChatViewModel? _chatViewModel;

  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _scrollController.addListener(_onScroll);

    // Listen for new messages
    _chatViewModel = context.read<ChatViewModel>();
    _chatViewModel?.addListener(_onChatUpdate);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Remove listener to prevent memory leaks
    _chatViewModel?.removeListener(_onChatUpdate);
    super.dispose();
  }

  void _onChatUpdate() {
    // When a new message arrives via socket, we just reload page 1
    // and reset pagination because the whole thread might have shifted
    _currentPage = 1;
    _hasMore = true;
    _loadMessages(quiet: true);
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    await _loadMessages(page: _currentPage + 1, quiet: true);
    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadMessages({
    bool quiet = false,
    int page = 1,
  }) async {
    if (!quiet && page == 1) {
      setState(() => _isLoading = true);
    }

    try {
      final chatService = context.read<ChatService>();
      final result = await chatService.getConversations(
        receiverId: widget.args.otherUser.id,
        page: page,
        limit: _limit,
      );

      final List conversationsJson = result['conversations'];
      final List<Conversation> fetchedMessages =
          conversationsJson
              .map((j) => Conversation.fromJson(j))
              .toList();

      // Backend returns DESC (latest first)
      // We keep it as is because we'll use reverse: true in ListView

      setState(() {
        if (page == 1) {
          _messages = fetchedMessages;
          _currentPage = 1;
        } else {
          // Append older messages to the end of the list
          _messages.addAll(fetchedMessages);
          _currentPage = page;
        }

        _hasMore = fetchedMessages.length >= _limit;

        // Check if the latest message (or any) is accepted
        if (_messages.isNotEmpty) {
          _isAccepted = _messages.first.isAccepted;
        } else {
          _isAccepted = true;
        }
      });

      if (page == 1) {
        // No need to scroll to bottom manually with reverse: true
        // But we might want to ensure we're at 0
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      if (!quiet && page == 1) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authViewModel = context.read<AuthViewModel>();
    final chatViewModel = context.read<ChatViewModel>();

    chatViewModel.sendMessage(
      widget.args.otherUser.id,
      authViewModel.currentUser!.id,
      content,
    );

    _messageController.clear();
    // Socket will trigger receive_message which reloads via _onChatUpdate
    // But let's also trigger a local reload just in case socket is slow
    _loadMessages(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.args.otherUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  otherUser.avatar != null
                      ? NetworkImage(otherUser.avatar!)
                      : null,
              child:
                  otherUser.avatar == null
                      ? Text(otherUser.name[0].toUpperCase())
                      : null,
            ),
            const SizedBox(width: 12),
            Text(
              otherUser.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _messages.length + (_hasMore ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index ==
                            _messages.length +
                                (_hasMore ? 1 : 0)) {
                          return _buildHeaderInfo();
                        }
                        if (index == _messages.length &&
                            _hasMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final message = _messages[index];
                        final isMe =
                            message.senderId ==
                            context
                                .read<AuthViewModel>()
                                .currentUser
                                ?.id;
                        return _buildMessageBubble(
                          message,
                          context,
                          isMe,
                        );
                      },
                    ),
          ),

          if (!_isAccepted &&
              _messages.isNotEmpty &&
              _messages.last.senderId !=
                  context.read<AuthViewModel>().currentUser?.id)
            _buildRequestActions()
          else
            _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final otherUser = widget.args.otherUser;
    final themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 16,
      ),
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                otherUser.avatar != null
                    ? NetworkImage(otherUser.avatar!)
                    : null,
            child:
                otherUser.avatar == null
                    ? Text(
                      otherUser.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            otherUser.name,
            style: themeData.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${otherUser.username}',
            style: themeData.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã tham gia vào tháng ${otherUser.createdAt.month} năm ${otherUser.createdAt.year}',
            style: themeData.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to profile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.primary,
              foregroundColor: themeData.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Xem hồ sơ'),
          ),
          const Divider(height: 48),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Conversation message,
    BuildContext context,
    bool isMe,
  ) {
    final themeData = Theme.of(context);
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              isMe
                  ? themeData.colorScheme.secondary
                  : Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: themeData.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: themeData.colorScheme.secondary,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(),
              child: TextField(
                controller: _messageController,
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  fillColor: themeData.colorScheme.surface,
                  hintText: 'Tin nhắn',
                  hintStyle: themeData.textTheme.bodyMedium
                      ?.copyWith(
                        color: themeData.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: themeData.colorScheme.secondary,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestActions() {
    final themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: themeData.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await context
                    .read<ChatViewModel>()
                    .acceptConversation(
                      widget.args.otherUser.id,
                    );
                _loadMessages();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Chấp nhận',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await context
                    .read<ChatViewModel>()
                    .deleteConversation(
                      widget.args.otherUser.id,
                    );
                Navigator.pop(context);
              },
              child: Text(
                'Xóa',
                style: TextStyle(
                  color: themeData.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
