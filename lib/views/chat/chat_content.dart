import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

/// Chat Content
class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  @override
  void initState() {
    super.initState();
    // Connect to socket when screen initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final chatViewModel = context.read<ChatViewModel>();
      final token = authViewModel.accessToken;

      if (token != null && !chatViewModel.isConnected) {
        chatViewModel.connect(token);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    final chatViewModel = context.read<ChatViewModel>();
    chatViewModel.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final chatViewModel = context.watch<ChatViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        chatViewModel.isConnected
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  chatViewModel.isConnected
                      ? 'Connected'
                      : 'Offline',
                  style: themeData.textTheme.bodySmall?.copyWith(
                    color:
                        chatViewModel.isConnected
                            ? Colors.green
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              chatViewModel.isConnected
                  ? Icons.message
                  : Icons.cloud_off,
              size: 64,
              color:
                  chatViewModel.isConnected
                      ? themeData.colorScheme.secondary
                      : themeData.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              chatViewModel.isConnected
                  ? 'Tin nhắn'
                  : 'Mất kết nối',
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              chatViewModel.isConnected
                  ? 'Danh sách tin nhắn sẽ hiển thị ở đây'
                  : 'Vui lòng kiểm tra kết nối để nhận tin nhắn mới',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            if (!chatViewModel.isConnected) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final token = authViewModel.accessToken;
                  if (token != null) {
                    chatViewModel.connect(token);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử kết nối lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
