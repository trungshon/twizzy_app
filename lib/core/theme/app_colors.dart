import 'package:flutter/material.dart';

/// App Colors
///
/// Định nghĩa màu sắc cho Light và Dark theme
class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(
    0xFFFFFFFF,
  ); // White
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF000000); // Black
  static const Color lightSecondary = Color(
    0xFF1DA1F2,
  ); // Blue accent
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF536471);
  static const Color lightDivider = Color(0xFFD1D9DD); // Đậm hơn

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF000000); // Black
  static const Color darkSurface = Color(0xFF16181C);
  static const Color darkPrimary = Color(0xFFFFFFFF); // White
  static const Color darkSecondary = Color(
    0xFF1DA1F2,
  ); // Blue accent
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF71767A);
  static const Color darkDivider = Color(
    0xFF3F4346,
  ); // Đậm hơn (sáng hơn một chút)

  // Common Colors (dùng cho cả light và dark)
  static const Color accent = Color(0xFF1DA1F2); // Blue
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}
