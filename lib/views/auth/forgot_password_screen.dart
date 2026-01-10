import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'verify_forgot_password_screen.dart';

/// Forgot Password Screen
///
/// Màn hình nhập email để quên mật khẩu
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController =
      TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _emailError = null; // Will be validated on submit
      } else {
        // Basic email validation
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailRegex.hasMatch(trimmed)) {
          _emailError = 'Email không hợp lệ';
        } else {
          _emailError = null;
        }
      }
    });
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
                    'Quên mật khẩu?',
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Text hướng dẫn
                  Text(
                    'Nhập email của bạn để nhận mã OTP đặt lại mật khẩu',
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Input field Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      errorText: _emailError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _validateEmail,
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
                                    final email =
                                        _emailController.text
                                            .trim();

                                    // Validate email
                                    if (email.isEmpty) {
                                      setState(() {
                                        _emailError =
                                            'Email không được để trống';
                                      });
                                      return;
                                    }
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(
                                      email,
                                    )) {
                                      setState(() {
                                        _emailError =
                                            'Email không hợp lệ';
                                      });
                                      return;
                                    }

                                    // Call forgot password
                                    final success =
                                        await authViewModel
                                            .forgotPassword(
                                              email,
                                            );

                                    if (success &&
                                        context.mounted) {
                                      // Navigate to verify forgot password screen
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  VerifyForgotPasswordScreen(
                                                    email: email,
                                                  ),
                                        ),
                                      );
                                    } else if (context.mounted &&
                                        authViewModel.error !=
                                            null) {
                                      // Handle validation errors from backend
                                      final apiError =
                                          authViewModel.apiError;
                                      if (apiError != null &&
                                          apiError
                                              .hasValidationErrors()) {
                                        setState(() {
                                          final emailError =
                                              apiError
                                                  .getFieldError(
                                                    'email',
                                                  );
                                          if (emailError !=
                                              null) {
                                            _emailError =
                                                emailError;
                                          }
                                        });
                                      } else {
                                        // Show general error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              authViewModel
                                                  .error!,
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
