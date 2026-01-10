import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/common/divider_with_text.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Login Screen
///
/// Màn hình đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
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
                    'Đăng nhập vào Twizzy',
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Nút đăng nhập bằng Google
                  GoogleSignInButton(
                    text: 'Đăng nhập bằng Google',
                    onPressed: () {
                      // TODO: Implement Google sign in
                      debugPrint('Google sign in pressed');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Divider "hoặc"
                  const DividerWithText(text: 'hoặc'),
                  const SizedBox(height: 8),

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
                  const SizedBox(height: 16),

                  // Input field Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
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
                    onChanged: _validatePassword,
                  ),
                  const SizedBox(height: 16),

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
                                    // Validate
                                    final email =
                                        _emailController.text
                                            .trim();
                                    final password =
                                        _passwordController.text;

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

                                    // Validate password
                                    if (password.isEmpty) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu không được để trống';
                                      });
                                      return;
                                    }

                                    // Call login
                                    final success =
                                        await authViewModel
                                            .login(
                                              email: email,
                                              password: password,
                                            );

                                    if (success &&
                                        context.mounted) {
                                      // Navigate to home screen
                                      Navigator.of(
                                        context,
                                      ).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const HomeScreen(),
                                        ),
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
                                        // Set field-specific errors
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
                  const SizedBox(height: 8),

                  // Nút Quên mật khẩu
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            themeData.brightness ==
                                    Brightness.dark
                                ? themeData.colorScheme.surface
                                : themeData.colorScheme.surface,
                        foregroundColor:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                        side: BorderSide(
                          color: themeData.dividerColor,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            24,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Không có tài khoản? ',
                        style: themeData.textTheme.bodyMedium
                            ?.copyWith(fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Đăng ký',
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    themeData
                                        .colorScheme
                                        .secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                        ),
                      ),
                    ],
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
