import 'dart:io';
import 'package:flutter/material.dart';
import '../common/twizz_video_player.dart';
import '../media/fullscreen_media_viewer.dart';
import '../../models/twizz/twizz_models.dart';

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

  Widget _buildSingleImage(
    BuildContext context,
    File file,
    int index,
  ) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Chuyển danh sách File thành Media objects (dùng chung cho Viewer)
            final mediaList =
                images
                    .map(
                      (f) => Media(
                        url: f.path,
                        type: MediaType.image,
                      ),
                    )
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FullscreenMediaViewer(
                      medias: mediaList,
                      initialIndex: index,
                      isFile: true,
                    ),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(file, fit: BoxFit.cover),
            ),
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
        GestureDetector(
          onTap: () {
            final mediaList =
                images
                    .map(
                      (f) => Media(
                        url: f.path,
                        type: MediaType.image,
                      ),
                    )
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FullscreenMediaViewer(
                      medias: mediaList,
                      initialIndex: index,
                      isFile: true,
                    ),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                file,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
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
class TwizzCreateVideoPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          // Video container using the shared TwizzVideoPlayer
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FullscreenMediaViewer(
                        medias: [
                          Media(
                            url: video.path,
                            type: MediaType.video,
                          ),
                        ],
                        initialIndex: 0,
                        isFile: true,
                      ),
                ),
              );
            },
            child: Stack(
              children: [
                TwizzVideoPlayer(file: video, height: 280),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Remove button
          if (!isLoading)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
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
        ],
      ),
    );
  }
}
