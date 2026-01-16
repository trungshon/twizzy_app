import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_constants.dart';

/// Video Test Screen
///
/// Màn hình test video streaming từ backend
class VideoTestScreen extends StatefulWidget {
  const VideoTestScreen({super.key});

  @override
  State<VideoTestScreen> createState() =>
      _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen> {
  final TextEditingController _videoNameController =
      TextEditingController();
  VideoPlayerController? _controller;
  bool _isLoading = false;
  String? _error;

  // Sample video names from backend
  final List<String> _sampleVideos = [
    'je08dxjqj8j7n1y78o7azuc0h.mp4',
    'kr3fzgfj5xjf2t77uer4lbhtf.mp4',
    'nssd9bq9t2e3njn2h79d0mcrj.mp4',
    'tnkypwzk14c0ovgv2j2qtjd1y.mp4',
  ];

  @override
  void dispose() {
    _videoNameController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String videoName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Dispose old controller
    await _controller?.dispose();

    final videoUrl =
        '${ApiConstants.baseUrl}${ApiConstants.videoStream(videoName)}';
    debugPrint('Loading video from: $videoUrl');

    try {
      // Không cần set Range header - ExoPlayer tự động quản lý
      // Backend đã hỗ trợ cả request có và không có Range header
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await controller.initialize();

      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      // Auto play
      controller.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Lỗi load video: $e';
      });
      debugPrint('Error loading video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Video Stream Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Test Video Streaming từ Backend',
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: ${ApiConstants.baseUrl}/static/video-stream/<name>',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: themeData.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),

            // Sample videos
            Text(
              'Video có sẵn:',
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _sampleVideos.map((video) {
                    return ActionChip(
                      label: Text(
                        video.length > 20
                            ? '${video.substring(0, 17)}...'
                            : video,
                      ),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                _videoNameController.text =
                                    video;
                                _loadVideo(video);
                              },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // Custom video name input
            TextField(
              controller: _videoNameController,
              decoration: InputDecoration(
                labelText: 'Tên video (VD: video.mp4)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            if (_videoNameController
                                .text
                                .isNotEmpty) {
                              _loadVideo(
                                _videoNameController.text.trim(),
                              );
                            }
                          },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _loadVideo(value.trim());
                }
              },
            ),
            const SizedBox(height: 24),

            // Video Player
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: themeData.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_controller != null &&
                _controller!.value.isInitialized)
              Column(
                children: [
                  // Video
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Video info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildVideoInfo(
                            'Duration',
                            _formatDuration(
                              _controller!.value.duration,
                            ),
                          ),
                          _buildVideoInfo(
                            'Size',
                            '${_controller!.value.size.width.toInt()} x ${_controller!.value.size.height.toInt()}',
                          ),
                          _buildVideoInfo(
                            'Aspect Ratio',
                            _controller!.value.aspectRatio
                                .toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        onPressed: () {
                          final newPosition =
                              _controller!.value.position -
                              const Duration(seconds: 10);
                          _controller!.seekTo(
                            newPosition < Duration.zero
                                ? Duration.zero
                                : newPosition,
                          );
                        },
                      ),
                      // Play/Pause
                      IconButton(
                        iconSize: 48,
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                          });
                        },
                      ),
                      // Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        onPressed: () {
                          final newPosition =
                              _controller!.value.position +
                              const Duration(seconds: 10);
                          _controller!.seekTo(
                            newPosition >
                                    _controller!.value.duration
                                ? _controller!.value.duration
                                : newPosition,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: themeData.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chọn video để phát',
                        style: themeData.textTheme.bodyLarge
                            ?.copyWith(
                              color:
                                  themeData
                                      .colorScheme
                                      .secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
