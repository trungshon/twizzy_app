/// Number Formatter
///
/// Utilities để format số
class NumberFormatter {
  /// Format số thành K (nghìn) hoặc M (triệu) với dấu +
  /// Ví dụ: 1500 -> 1.5K+, 1500000 -> 1.5M+
  static String formatCount(int count) {
    if (count >= 1000000) {
      final millions = count / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()}M+';
      }
      return '${millions.toStringAsFixed(1)}M+';
    } else if (count >= 1000) {
      final thousands = count / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}K+';
      }
      return '${thousands.toStringAsFixed(1)}K+';
    }
    return count.toString();
  }
}
