import 'package:flutter/material.dart';
import '../../core/constants/asset_paths.dart';

/// App Logo Widget
///
/// Widget hiển thị logo của app
/// - logo: Logo có chữ (logo.png)
/// - logoImage: Logo chỉ có hình (logo_image.png)
class AppLogo extends StatelessWidget {
  final bool
  showText; // true = logo có chữ, false = logo chỉ có hình
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.showText = true,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final String logoPath =
        showText ? AssetPaths.logo : AssetPaths.logoImage;

    return Image.asset(
      logoPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported,
          size: width ?? height ?? 100,
          color: themeData.colorScheme.error,
        );
      },
    );
  }
}
