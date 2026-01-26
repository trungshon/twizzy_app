import 'package:flutter/material.dart';
import '../models/twizz/twizz_models.dart';
import 'route_names.dart';
import '../views/auth/auth_check_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/create_account_screen.dart';
import '../views/auth/verify_email_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/auth/verify_forgot_password_screen.dart';
import '../views/auth/reset_password_screen.dart';
import '../views/auth/change_password_screen.dart';
import '../views/auth/set_username_screen.dart';
import '../views/main/main_screen.dart';
import '../views/profile/my_profile_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/user_profile_screen.dart';
import '../views/profile/follower_list_screen.dart';
import '../views/twizz/create_twizz_screen.dart';
import '../views/twizz/twizz_interaction_screen.dart';
import '../views/twizz/twizz_detail_screen.dart';
import '../views/chat/chat_detail_screen.dart';
import '../views/test/video_test_screen.dart';

/// App Router
///
/// Quản lý navigation và routing trong ứng dụng
class AppRouter {
  /// Generate route từ RouteSettings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth Routes
      case RouteNames.authCheck:
        return MaterialPageRoute(
          builder: (_) => const AuthCheckScreen(),
        );

      case RouteNames.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case RouteNames.createAccount:
        return MaterialPageRoute(
          builder: (_) => const CreateAccountScreen(),
        );

      case RouteNames.verifyEmail:
        if (args is String) {
          // args là email
          return MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: args),
          );
        } else if (args is Map<String, dynamic> &&
            args.containsKey('email')) {
          return MaterialPageRoute(
            builder:
                (_) => VerifyEmailScreen(
                  email: args['email'] as String,
                ),
          );
        }
        return _errorRoute(
          'Email is required for VerifyEmailScreen',
        );

      case RouteNames.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );

      case RouteNames.verifyForgotPassword:
        if (args is String) {
          // args là email
          return MaterialPageRoute(
            builder:
                (_) => VerifyForgotPasswordScreen(email: args),
          );
        } else if (args is Map<String, dynamic> &&
            args.containsKey('email')) {
          return MaterialPageRoute(
            builder:
                (_) => VerifyForgotPasswordScreen(
                  email: args['email'] as String,
                ),
          );
        }
        return _errorRoute(
          'Email is required for VerifyForgotPasswordScreen',
        );

      case RouteNames.resetPassword:
        if (args is Map<String, dynamic>) {
          final email = args['email'] as String?;
          final otp = args['otp'] as String?;
          if (email != null && otp != null) {
            return MaterialPageRoute(
              builder:
                  (_) => ResetPasswordScreen(
                    email: email,
                    otp: otp,
                  ),
            );
          }
        }
        return _errorRoute(
          'Email and OTP are required for ResetPasswordScreen',
        );

      case RouteNames.changePassword:
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
        );

      case RouteNames.setUsername:
        return MaterialPageRoute(
          builder: (_) => const SetUsernameScreen(),
        );

      // Main Routes
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );

      // Profile Routes
      case RouteNames.myProfile:
        return MaterialPageRoute(
          builder: (_) => const MyProfileScreen(),
        );

      case RouteNames.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );

      case RouteNames.userProfile:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => UserProfileScreen(username: args),
          );
        } else if (args is Map<String, dynamic> &&
            args.containsKey('username')) {
          return MaterialPageRoute(
            builder:
                (_) => UserProfileScreen(
                  username: args['username'] as String,
                ),
          );
        }
        return _errorRoute(
          'Username is required for UserProfileScreen',
        );

      case RouteNames.followerList:
        if (args is FollowerListScreenArgs) {
          return MaterialPageRoute(
            builder: (_) => FollowerListScreen(args: args),
          );
        }
        return _errorRoute(
          'Invalid args for FollowerListScreen',
        );

      // Twizz Routes
      case RouteNames.createTwizz:
        // Accept optional Twizz for quote mode
        final parentTwizz = args is Twizz ? args : null;
        return MaterialPageRoute(
          builder:
              (_) => CreateTwizzScreen(parentTwizz: parentTwizz),
          fullscreenDialog: true,
        );

      case RouteNames.twizzInteraction:
        if (args is TwizzInteractionScreenArgs) {
          return MaterialPageRoute(
            builder: (_) => TwizzInteractionScreen(args: args),
          );
        }
        return _errorRoute(
          'Invalid args for TwizzInteractionScreen',
        );

      case RouteNames.twizzDetail:
        if (args is TwizzDetailScreenArgs) {
          return MaterialPageRoute(
            builder: (_) => TwizzDetailScreen(args: args),
          );
        }
        return _errorRoute('Invalid args for TwizzDetailScreen');

      case RouteNames.videoTest:
        return MaterialPageRoute(
          builder: (_) => const VideoTestScreen(),
        );

      case RouteNames.chatDetail:
        if (args is ChatDetailScreenArgs) {
          return MaterialPageRoute(
            builder: (_) => ChatDetailScreen(args: args),
          );
        }
        return _errorRoute('Invalid args for ChatDetailScreen');

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Error route khi không tìm thấy route hoặc thiếu arguments
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(message)),
          ),
    );
  }
}
