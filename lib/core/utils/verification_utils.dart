import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

class VerificationUtils {
  static void showUnverifiedWarning(
    BuildContext context,
    String? email, {
    String? message,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tài khoản chưa xác nhận'),
            content: Text(
              message ??
                  'Tài khoản của bạn chưa được xác nhận. Vui lòng xác nhận để thực hiện tính năng này.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bỏ qua'),
              ),
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  return ElevatedButton(
                    onPressed:
                        authViewModel.isLoading
                            ? null
                            : () async {
                              // Resend verification email
                              await authViewModel
                                  .resendVerifyEmail();

                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pop(); // Close dialog

                                ScaffoldMessenger.of(
                                  context,
                                ).clearSnackBars();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã gửi mã xác nhận đến email của bạn',
                                    ),
                                  ),
                                );

                                if (email != null) {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(
                                    RouteNames.verifyEmail,
                                    arguments: {
                                      'email': email,
                                      'isFromInitialFlow': false,
                                    },
                                  );
                                }
                              }
                            },
                    child:
                        authViewModel.isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                      Color
                                    >(Colors.white),
                              ),
                            )
                            : const Text('Xác nhận tài khoản'),
                  );
                },
              ),
            ],
          ),
    );
  }
}
