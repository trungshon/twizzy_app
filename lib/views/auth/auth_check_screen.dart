import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/local_storage/token_storage.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Auth Check Screen
///
/// Màn hình kiểm tra trạng thái đăng nhập
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() =>
      _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Get tokenStorage from context
    final tokenStorage = Provider.of<TokenStorage>(
      context,
      listen: false,
    );

    // Check if user is logged in
    final isLoggedIn = await tokenStorage.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // User is logged in, navigate to home
      // Also try to load user info
      final authViewModel = Provider.of<AuthViewModel>(
        context,
        listen: false,
      );
      final success = await authViewModel.getMe();

      if (!mounted) return;

      // If getMe failed (token expired), navigate to register
      if (!success) {
        Navigator.of(
          context,
        ).pushReplacementNamed(RouteNames.register);
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(RouteNames.home);
    } else {
      // User is not logged in, navigate to register screen
      Navigator.of(
        context,
      ).pushReplacementNamed(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
