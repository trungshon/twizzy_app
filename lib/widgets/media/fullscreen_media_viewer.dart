import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_orientation/auto_orientation.dart';
import '../../models/twizz/twizz_models.dart';
import '../common/twizz_video_player.dart';

/// Fullscreen Media Viewer
///
/// Hiển thị ảnh hoặc video toàn màn hình, có hỗ trợ pinch-to-zoom cho ảnh
/// và vuốt để đóng (swipe to dismiss).
class FullscreenMediaViewer extends StatefulWidget {
  final List<Media> medias;
  final int initialIndex;
  final bool isFile;

  const FullscreenMediaViewer({
    super.key,
    required this.medias,
    this.initialIndex = 0,
    this.isFile = false,
  });

  @override
  State<FullscreenMediaViewer> createState() =>
      _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState
    extends State<FullscreenMediaViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );

    // Hide status bar and navigation bar for true fullscreen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Clear SystemChrome constraints to allow landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Enable all orientations (landscape & portrait)
    AutoOrientation.fullAutoMode();
  }

  @override
  void dispose() {
    _pageController.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Lock SystemChrome constraints back to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Lock back to portrait mode when leaving fullscreen
    AutoOrientation.portraitUpMode();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        itemCount: widget.medias.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final media = widget.medias[index];
          return _MediaItem(media: media, isFile: widget.isFile);
        },
      ),
    );
  }
}

class _MediaItem extends StatelessWidget {
  final Media media;
  final bool isFile;

  const _MediaItem({required this.media, this.isFile = false});

  @override
  Widget build(BuildContext context) {
    if (media.type == MediaType.video) {
      return isFile
          ? TwizzVideoPlayer(
            file: File(media.url),
            isFullScreen: true,
          )
          : TwizzVideoPlayer(url: media.url, isFullScreen: true);
    }

    // Default to image with InteractiveViewer for pinch-to-zoom
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child:
            isFile
                ? Image.file(
                  File(media.url),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                )
                : Image.network(
                  media.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                  ) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
