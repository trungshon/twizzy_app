import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Verify Forgot Password Screen
///
/// Màn hình xác nhận OTP quên mật khẩu
class VerifyForgotPasswordScreen extends StatefulWidget {
  final String email;

  const VerifyForgotPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyForgotPasswordScreen> createState() =>
      _VerifyForgotPasswordScreenState();
}

class _VerifyForgotPasswordScreenState
    extends State<VerifyForgotPasswordScreen> {
  final TextEditingController _codeController =
      TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const AppLogo(
                    showText: true,
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 40),

                  // Tiêu đề
                  Text(
                    'Chúng tôi đã gửi mã cho bạn',
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Text hướng dẫn
                  Text(
                    'Nhập vào bên dưới để xác thực',
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  // Email address
                  Text(
                    widget.email,
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(
                          fontSize: 15,
                          color: themeData.colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Input field Mã xác nhận
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Mã xác nhận',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: themeData.textTheme.bodyMedium,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 16),

                  // Link gửi lại mã
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return GestureDetector(
                        onTap:
                            authViewModel.isLoading
                                ? null
                                : () async {
                                  final success =
                                      await authViewModel
                                          .forgotPassword(
                                            widget.email,
                                          );
                                  if (success &&
                                      context.mounted) {
                                    // Clear any existing SnackBar before showing a new one
                                    ScaffoldMessenger.of(
                                      context,
                                    ).clearSnackBars();

                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã gửi lại mã xác nhận',
                                        ),
                                      ),
                                    );
                                  } else if (context.mounted &&
                                      authViewModel.error !=
                                          null) {
                                    // Clear any existing SnackBar before showing a new one
                                    ScaffoldMessenger.of(
                                      context,
                                    ).clearSnackBars();
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          authViewModel.error!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor:
                                            themeData
                                                .colorScheme
                                                .error,
                                      ),
                                    );
                                  }
                                },
                        child: Text(
                          'Bạn không nhận được email?',
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    authViewModel.isLoading
                                        ? themeData
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.5)
                                        : themeData
                                            .colorScheme
                                            .secondary,
                                fontSize: 15,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Nút Tiếp theo
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              authViewModel.isLoading
                                  ? null
                                  : () async {
                                    if (_codeController
                                        .text
                                        .isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).clearSnackBars();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Vui lòng nhập mã xác nhận',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final success =
                                        await authViewModel
                                            .verifyForgotPassword(
                                              widget.email,
                                              _codeController
                                                  .text
                                                  .trim(),
                                            );

                                    if (success &&
                                        context.mounted) {
                                      // Navigate to reset password screen
                                      Navigator.of(
                                        context,
                                      ).pushNamed(
                                        RouteNames.resetPassword,
                                        arguments: {
                                          'email': widget.email,
                                          'otp':
                                              _codeController
                                                  .text
                                                  .trim(),
                                        },
                                      );
                                    } else if (context.mounted &&
                                        authViewModel.error !=
                                            null) {
                                      // Clear any existing SnackBar before showing a new one
                                      ScaffoldMessenger.of(
                                        context,
                                      ).clearSnackBars();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            authViewModel.error!,
                                            style:
                                                const TextStyle(
                                                  color:
                                                      Colors
                                                          .white,
                                                ),
                                          ),
                                          backgroundColor:
                                              themeData
                                                  .colorScheme
                                                  .error,
                                        ),
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(24),
                            ),
                          ),
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
                                  : const Text(
                                    'Tiếp theo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
