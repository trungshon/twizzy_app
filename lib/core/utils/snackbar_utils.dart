import 'package:flutter/material.dart';
import '../../models/auth/auth_models.dart';

/// SnackBar Type enum
enum SnackBarType { success, error, warning, info }

/// SnackBar Utils
///
/// Utility class để hiển thị SnackBar trong toàn bộ app
class SnackBarUtils {
  /// Show a SnackBar with custom type
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Capture the ScaffoldMessengerState before showing
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any existing SnackBar first
    scaffoldMessenger.clearSnackBars();

    final themeData = Theme.of(context);
    final config = _getConfig(type, themeData);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color:
                  type == SnackBarType.error
                      ? Colors.white
                      : themeData.colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color:
                      type == SnackBarType.error
                          ? Colors.white
                          : themeData.colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: SnackBarAction(
          label: actionLabel ?? 'Đóng',
          textColor:
              type == SnackBarType.error
                  ? Colors.white
                  : themeData.colorScheme.onPrimary,
          onPressed:
              onAction ??
              () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
        ),
      ),
    );
  }

  /// Show success SnackBar
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
    );
  }

  /// Show error SnackBar
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
    );
  }

  /// Show error SnackBar from ApiErrorResponse
  /// Automatically extracts detailed validation error message
  static void showApiError(
    BuildContext context, {
    required ApiErrorResponse error,
    Duration duration = const Duration(seconds: 4),
  }) {
    String message;

    if (error.hasValidationErrors()) {
      // Get first validation error message
      final firstError = error.errors!.values.first;
      message = firstError.msg;
    } else {
      message = error.message;
    }

    showError(context, message: message, duration: duration);
  }

  /// Show warning SnackBar
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
    );
  }

  /// Show info SnackBar
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
    );
  }

  /// Show a toast message at the top of the screen
  /// Use this when a SnackBar might be covered by a BottomSheet
  static void showToast(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final themeData = Theme.of(context);
    final config = _getConfig(type, themeData);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      config.icon,
                      color: themeData.colorScheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: themeData.colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  /// Clear all SnackBars
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Get config based on type
  static _SnackBarConfig _getConfig(
    SnackBarType type,
    ThemeData themeData,
  ) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          icon: Icons.check_circle_outline,
          backgroundColor: themeData.colorScheme.primary,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          icon: Icons.error_outline,
          backgroundColor: themeData.colorScheme.error,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          icon: Icons.warning_amber_outlined,
          backgroundColor: Colors.orange.shade700,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          icon: Icons.info_outline,
          backgroundColor: const Color(0xFF1DA1F2),
        );
    }
  }
}

/// Internal config class
class _SnackBarConfig {
  final IconData icon;
  final Color backgroundColor;

  _SnackBarConfig({
    required this.icon,
    required this.backgroundColor,
  });
}
