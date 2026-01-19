import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Media preview widget - Horizontal scrollable images
/// Reused from CreateTwizzScreen
class TwizzCreateMediaPreview extends StatelessWidget {
  final List<File> images;
  final void Function(int) onRemove;
  final bool isLoading;

  const TwizzCreateMediaPreview({
    super.key,
    required this.images,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Nếu chỉ có 1 ảnh, hiển thị lớn hơn
    if (images.length == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        child: _buildSingleImage(context, images.first, 0),
      );
    }

    // Nhiều ảnh - hiển thị danh sách ngang có thể vuốt
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder:
            (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _buildImageItem(context, images[index], index);
        },
      ),
    );
  }

  /// Build single image (larger display)
  Widget _buildSingleImage(
    BuildContext context,
    File file,
    int index,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        if (!isLoading)
          Positioned(
            top: 8,
            right: 8,
            child: _buildRemoveButton(index),
          ),
      ],
    );
  }

  /// Build image item for horizontal list
  Widget _buildImageItem(
    BuildContext context,
    File file,
    int index,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file,
            width: 140,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        if (!isLoading)
          Positioned(
            top: 8,
            right: 8,
            child: _buildRemoveButton(index),
          ),
      ],
    );
  }

  /// Build remove button
  Widget _buildRemoveButton(int index) {
    return GestureDetector(
      onTap: () => onRemove(index),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

/// Video preview widget with playback
/// Reused from CreateTwizzScreen
class TwizzCreateVideoPreview extends StatefulWidget {
  final File video;
  final VoidCallback onRemove;
  final bool isLoading;

  const TwizzCreateVideoPreview({
    super.key,
    required this.video,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  State<TwizzCreateVideoPreview> createState() =>
      _TwizzCreateVideoPreviewState();
}

class _TwizzCreateVideoPreviewState
    extends State<TwizzCreateVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.video);
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          // Video container
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 280,
              color: Colors.black,
              child: _buildVideoContent(themeData),
            ),
          ),
          // Play/Pause overlay
          if (_isInitialized && !widget.isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity:
                          _controller.value.isPlaying
                              ? 0.0
                              : 1.0,
                      duration: const Duration(
                        milliseconds: 200,
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Remove button
          if (!widget.isLoading)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          // Duration indicator
          if (_isInitialized)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_controller.value.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(ThemeData themeData) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: themeData.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Không thể tải video',
              style: TextStyle(
                color: themeData.colorScheme.error,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            themeData.colorScheme.primary,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
