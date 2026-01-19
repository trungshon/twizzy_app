import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service/auth_service.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/auth/change_password_viewmodel.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => ChangePasswordViewModel(
            context.read<AuthService>(),
          ),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() =>
      _ChangePasswordState();
}

class _ChangePasswordState extends State<_ChangePasswordView> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final viewModel = context.watch<ChangePasswordViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Cập nhật mật khẩu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (user?.username != null)
              Text(
                '@${user!.username}',
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed:
                viewModel.isLoading
                    ? null
                    : () async {
                      final success =
                          await viewModel.changePassword();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đổi mật khẩu thành công',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
            child:
                viewModel.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Hoàn tất',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error Message
            if (viewModel.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  viewModel
                      .detailedErrorMessage, // Use detailed error
                  style: TextStyle(
                    color:
                        themeData.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Mật khẩu hiện tại',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(
              context,
              controller: viewModel.oldPasswordController,
              hintText: 'Nhập mật khẩu hiện tại',

              isVisible: viewModel.isOldPasswordVisible,
              onToggleVisibility:
                  viewModel.toggleOldPasswordVisibility,
              errorText: viewModel.apiError?.getFieldError(
                'old_password',
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 32),

            const Text(
              'Mật khẩu mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(
              context,
              controller: viewModel.newPasswordController,
              hintText: 'Nhập mật khẩu mới',
              isVisible: viewModel.isPasswordVisible,
              onToggleVisibility:
                  viewModel.togglePasswordVisibility,
              errorText: viewModel.apiError?.getFieldError(
                'password',
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Xác nhận mật khẩu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(
              context,
              controller: viewModel.confirmPasswordController,
              hintText: 'Xác nhận mật khẩu',
              isVisible: viewModel.isConfirmPasswordVisible,
              onToggleVisibility:
                  viewModel.toggleConfirmPasswordVisibility,
              errorText: viewModel.apiError?.getFieldError(
                'confirm_password',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        fillColor: Theme.of(context).colorScheme.surface,
        hintStyle: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        hintText: hintText,
        errorText: errorText,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

extension on ChangePasswordViewModel {
  String get detailedErrorMessage {
    if (apiError == null) return error ?? 'Có lỗi xảy ra';

    if (apiError!.hasValidationErrors()) {
      // Get first validation error message
      final firstError = apiError!.errors!.values.first;
      return firstError.msg;
    }

    return apiError!.message;
  }
}
