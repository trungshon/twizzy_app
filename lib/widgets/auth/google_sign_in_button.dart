import 'package:flutter/material.dart';
import '../../core/constants/asset_paths.dart';

/// Google Sign In Button
///
/// Button đăng ký/đăng nhập bằng Google
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.text = 'Đăng ký bằng Google',
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDark = themeData.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.white,
          foregroundColor: isDark ? Colors.black : Colors.black,
          side: BorderSide(
            color: themeData.dividerColor,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Icon - Sử dụng Material Icon nếu không có asset
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Image.asset(
                AssetPaths.googleIcon,
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback: Sử dụng text "G" nếu không có icon
                  return const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
