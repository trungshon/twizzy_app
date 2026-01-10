import 'package:flutter/material.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/common/divider_with_text.dart';
import 'login_screen.dart';
import 'create_account_screen.dart';

/// Register Screen
///
/// Màn hình đăng ký tài khoản
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                showText: true, // Logo chỉ có hình
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
              GoogleSignInButton(
                onPressed: () {
                  // TODO: Implement Google sign in
                  debugPrint('Google sign in pressed');
                },
              ),
              const SizedBox(height: 8),

              // Divider "hoặc"
              const DividerWithText(text: 'hoặc'),
              const SizedBox(height: 8),

              // Nút Tạo tài khoản
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const CreateAccountScreen(),
                      ),
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
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (context) => const LoginScreen(),
                        ),
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
