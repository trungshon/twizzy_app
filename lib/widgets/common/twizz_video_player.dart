import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shared Video Player Widget for Twizz
///
/// Used for playing videos in twizz items, quote previews, etc.
class TwizzVideoPlayer extends StatefulWidget {
  final String url;
  final double? height;
  final bool showDuration;
  final bool showControls;

  const TwizzVideoPlayer({
    super.key,
    required this.url,
    this.height,
    this.showDuration = true,
    this.showControls = true,
  });

  @override
  State<TwizzVideoPlayer> createState() =>
      _TwizzVideoPlayerState();
}

class _TwizzVideoPlayerState extends State<TwizzVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControlsOverlay = true;
  bool _isSeeking = false;

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
      _controller.addListener(_onVideoUpdate);
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

  void _onVideoUpdate() {
    if (mounted && !_isSeeking) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _showControlsOverlay = true;
    } else {
      _controller.play();
      // Hide controls after a delay when playing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControlsOverlay = false;
          });
        }
      });
    }
    setState(() {});
  }

  void _onTapVideo() {
    setState(() {
      _showControlsOverlay = !_showControlsOverlay;
    });
    // Auto-hide controls after 3 seconds if playing
    if (_showControlsOverlay && _controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControlsOverlay = false;
          });
        }
      });
    }
  }

  void _onSeekUpdate(double value) {
    final duration = _controller.value.duration;
    final position = Duration(
      milliseconds: (value * duration.inMilliseconds).toInt(),
    );
    _controller.seekTo(position);
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
          // Tap to show/hide controls
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: _onTapVideo,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          // Play/Pause overlay
          if (_isInitialized && widget.showControls)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showControlsOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControlsOverlay,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Seek bar and time display
          if (_isInitialized && widget.showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _showControlsOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControlsOverlay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Seek bar
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape:
                                const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                            overlayShape:
                                const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white38,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            value:
                                _controller
                                            .value
                                            .duration
                                            .inMilliseconds >
                                        0
                                    ? (_controller
                                                .value
                                                .position
                                                .inMilliseconds /
                                            _controller
                                                .value
                                                .duration
                                                .inMilliseconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                            onChangeStart: (value) {
                              _isSeeking = true;
                            },
                            onChanged: _onSeekUpdate,
                            onChangeEnd: (value) {
                              _isSeeking = false;
                            },
                          ),
                        ),
                        // Time display
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  _controller.value.position,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  _controller.value.duration,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Simple duration indicator (when controls are hidden)
          if (_isInitialized &&
              widget.showDuration &&
              !widget.showControls)
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
