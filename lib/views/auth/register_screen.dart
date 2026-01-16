import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/common/divider_with_text.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Register Screen
///
/// Màn hình đăng ký tài khoản
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    final result = await authViewModel.googleSignIn();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    if (result == 'success') {
      // Existing user - go to home
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.home,
        (route) => false,
      );
    } else if (result == 'new_user') {
      // New user registered via Google - may need email verification
      final email = authViewModel.registeredEmail;
      if (email != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.verifyEmail,
          (route) => false,
          arguments: email,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.home,
          (route) => false,
        );
      }
    } else if (result == 'cancelled') {
      // User cancelled - do nothing
    } else {
      // Error occurred
      if (mounted && authViewModel.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authViewModel.error!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                'Tham gia Twizzy ngay hôm nay',
                style: themeData.textTheme.headlineLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 40),

              // Nút đăng ký bằng Google
              _isGoogleLoading
                  ? const SizedBox(
                    height: 44,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : GoogleSignInButton(
                    onPressed: _handleGoogleSignIn,
                  ),
              const SizedBox(height: 8),

              // Divider "hoặc"
              const DividerWithText(text: 'hoặc'),
              const SizedBox(height: 8),

              // Nút Tạo tài khoản
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isGoogleLoading
                          ? null
                          : () {
                            Navigator.of(context).pushNamed(
                              RouteNames.createAccount,
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Link đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bạn đã có tài khoản? ',
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap:
                        _isGoogleLoading
                            ? null
                            : () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(
                                RouteNames.login,
                              );
                            },
                    child: Text(
                      'Đăng nhập',
                      style: themeData.textTheme.bodyMedium
                          ?.copyWith(
                            color:
                                themeData.colorScheme.secondary,
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
    );
  }
}
