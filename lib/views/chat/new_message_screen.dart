import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat/new_message_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/user/user_list_item.dart';
import '../../routes/route_names.dart';
import 'chat_detail_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() =>
      _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newMessageViewModel =
          context.read<NewMessageViewModel>();
      newMessageViewModel.clearSearch();

      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser != null) {
        newMessageViewModel.loadFollowing(
          authViewModel.currentUser!.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final viewModel = context.watch<NewMessageViewModel>();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text(
          'Tin nhắn mới',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search/Recipient input
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                const Text(
                  'Đến: ',
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged:
                        (value) => viewModel.searchUsers(value),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: themeData.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                      hintText: 'Tìm kiếm người dùng',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // User List
          Expanded(
            child:
                viewModel.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(),
                    )
                    : viewModel.displayUsers.isEmpty
                    ? Center(
                      child: Text(
                        viewModel.searchQuery.isEmpty
                            ? 'Bạn chưa theo dõi ai'
                            : 'Không tìm thấy người dùng',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: viewModel.displayUsers.length,
                      itemBuilder: (context, index) {
                        final user =
                            viewModel.displayUsers[index];
                        return UserListItem(
                          user: user,
                          showBio: false,
                          onTap: () {
                            // Navigate to chat detail
                            Navigator.pushReplacementNamed(
                              context,
                              RouteNames.chatDetail,
                              arguments: ChatDetailScreenArgs(
                                otherUser: user,
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
