import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/common/app_logo.dart';
import '../auth/register_screen.dart';

/// Home Screen
///
/// Màn hình home tạm thời hiển thị thông tin user
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load user info khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser == null) {
        authViewModel.getMe();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed:
                    authViewModel.isLoading
                        ? null
                        : () async {
                          await authViewModel.logout();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const RegisterScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                tooltip: 'Đăng xuất',
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          if (authViewModel.isLoading &&
              authViewModel.currentUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (authViewModel.error != null &&
              authViewModel.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lỗi: ${authViewModel.error}',
                    style: TextStyle(
                      color: themeData.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authViewModel.getMe(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final user = authViewModel.currentUser;
          if (user == null) {
            return const Center(
              child: Text('Không có thông tin user'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                const Center(
                  child: AppLogo(
                    showText: true,
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),

                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin User',
                          style: themeData.textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, 'ID', user.id),
                        const Divider(),
                        _buildInfoRow(context, 'Tên', user.name),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Email',
                          user.email,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Ngày sinh',
                          _formatDate(user.dateOfBirth),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Trạng thái xác thực',
                          user.verify == 'Verified'
                              ? 'Đã xác thực'
                              : 'Chưa xác thực',
                        ),
                        if (user.username != null &&
                            user.username!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Username',
                            user.username!,
                          ),
                        ],
                        if (user.bio != null &&
                            user.bio!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Bio',
                            user.bio!,
                          ),
                        ],
                        if (user.location != null &&
                            user.location!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Địa chỉ',
                            user.location!,
                          ),
                        ],
                        if (user.website != null &&
                            user.website!.isNotEmpty) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Website',
                            user.website!,
                          ),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Ngày tạo',
                          _formatDateTime(user.createdAt),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Cập nhật lần cuối',
                          _formatDateTime(user.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return FloatingActionButton(
            onPressed:
                authViewModel.isLoading
                    ? null
                    : () => authViewModel.getMe(),
            tooltip: 'Làm mới',
            child: const Icon(Icons.refresh),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final themeData = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: themeData.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.secondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: themeData.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
