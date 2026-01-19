import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shared Video Player Widget for Twizz
///
/// Used for playing videos in twizz items, quote previews, etc.
class TwizzVideoPlayer extends StatefulWidget {
  final String url;
  final double? height;
  final bool showDuration;

  const TwizzVideoPlayer({
    super.key,
    required this.url,
    this.height,
    this.showDuration = true,
  });

  @override
  State<TwizzVideoPlayer> createState() =>
      _TwizzVideoPlayerState();
}

class _TwizzVideoPlayerState extends State<TwizzVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
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
    final content = Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else if (_hasError)
            const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white54,
                size: 48,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          // Play/Pause overlay
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity:
                      _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.6,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Duration indicator
          if (_isInitialized && widget.showDuration)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_controller.value.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.height != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(height: widget.height, child: content),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 9, child: content),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
