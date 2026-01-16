import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Reset Password Screen
///
/// Màn hình đặt lại mật khẩu mới
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    // At least 6 characters, 1 lowercase, 1 uppercase, 1 number, 1 symbol
    if (password.length < 6 || password.length > 50) {
      return false;
    }
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );
    return hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSymbol;
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = null; // Will be validated on submit
      } else if (value.length < 6) {
        _passwordError = 'Mật khẩu phải có từ 6 đến 50 ký tự';
      } else if (value.length > 50) {
        _passwordError = 'Mật khẩu không được vượt quá 50 ký tự';
      } else if (!_isStrongPassword(value)) {
        _passwordError =
            'Mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
      } else {
        _passwordError = null;
        // Re-validate confirm password if it's already filled
        if (_confirmPasswordController.text.isNotEmpty) {
          _validateConfirmPassword(
            _confirmPasswordController.text,
          );
        }
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError =
            null; // Will be validated on submit
      } else if (value.length < 6) {
        _confirmPasswordError =
            'Xác nhận mật khẩu phải có từ 6 đến 50 ký tự';
      } else if (value.length > 50) {
        _confirmPasswordError =
            'Xác nhận mật khẩu không được vượt quá 50 ký tự';
      } else if (!_isStrongPassword(value)) {
        _confirmPasswordError =
            'Xác nhận mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
      } else if (value != _passwordController.text) {
        _confirmPasswordError =
            'Xác nhận mật khẩu và mật khẩu phải giống nhau';
      } else {
        _confirmPasswordError = null;
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
                  const SizedBox(height: 20),
                  // Tiêu đề
                  Text(
                    'Đặt lại mật khẩu',
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Input field Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      errorText: _passwordError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    onChanged: (value) {
                      _validatePassword(value);
                      // Re-validate confirm password if it's already filled
                      if (_confirmPasswordController
                          .text
                          .isNotEmpty) {
                        _validateConfirmPassword(
                          _confirmPasswordController.text,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input field Confirm Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      errorText: _confirmPasswordError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    onChanged: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 32),

                  // Nút Đặt lại mật khẩu
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              authViewModel.isLoading
                                  ? null
                                  : () async {
                                    // Validate all fields
                                    final password =
                                        _passwordController.text;
                                    final confirmPassword =
                                        _confirmPasswordController
                                            .text;

                                    // Validate password
                                    if (password.isEmpty) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu không được để trống';
                                      });
                                      return;
                                    }
                                    if (password.length < 6 ||
                                        password.length > 50) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu phải có từ 6 đến 50 ký tự';
                                      });
                                      return;
                                    }
                                    if (!_isStrongPassword(
                                      password,
                                    )) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
                                      });
                                      return;
                                    }

                                    // Validate confirm password
                                    if (confirmPassword
                                        .isEmpty) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu không được để trống';
                                      });
                                      return;
                                    }
                                    if (confirmPassword.length <
                                            6 ||
                                        confirmPassword.length >
                                            50) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu phải có từ 6 đến 50 ký tự';
                                      });
                                      return;
                                    }
                                    if (!_isStrongPassword(
                                      confirmPassword,
                                    )) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
                                      });
                                      return;
                                    }
                                    if (confirmPassword !=
                                        password) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu và mật khẩu phải giống nhau';
                                      });
                                      return;
                                    }

                                    // Call reset password
                                    final success =
                                        await authViewModel
                                            .resetPassword(
                                              email:
                                                  widget.email,
                                              otp: widget.otp,
                                              password: password,
                                              confirmPassword:
                                                  confirmPassword,
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
                                            'Đặt lại mật khẩu thành công',
                                          ),
                                        ),
                                      );
                                      // Navigate to login screen
                                      Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        RouteNames.login,
                                        (route) => false,
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
                                          final passwordError =
                                              apiError
                                                  .getFieldError(
                                                    'password',
                                                  );
                                          if (passwordError !=
                                              null) {
                                            _passwordError =
                                                passwordError;
                                          }

                                          final confirmPasswordError =
                                              apiError.getFieldError(
                                                'confirm_password',
                                              );
                                          if (confirmPasswordError !=
                                              null) {
                                            _confirmPasswordError =
                                                confirmPasswordError;
                                          }

                                          final otpError = apiError
                                              .getFieldError(
                                                'forgot_password_otp',
                                              );
                                          if (otpError != null) {
                                            // Clear any existing SnackBar before showing a new one
                                            ScaffoldMessenger.of(
                                              context,
                                            ).clearSnackBars();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  otpError,
                                                  style: const TextStyle(
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
                                        });
                                      } else {
                                        // Clear any existing SnackBar before showing a new one
                                        ScaffoldMessenger.of(
                                          context,
                                        ).clearSnackBars();
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
                                    'Đặt lại mật khẩu',
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
