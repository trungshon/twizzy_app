import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/twizz/twizz_models.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/twizz/create_twizz_viewmodel.dart';
import '../../viewmodels/newsfeed/newsfeed_viewmodel.dart';

/// Create Twizz Screen
///
/// Màn hình tạo bài viết mới
class CreateTwizzScreen extends StatefulWidget {
  const CreateTwizzScreen({super.key});

  @override
  State<CreateTwizzScreen> createState() =>
      _CreateTwizzScreenState();
}

class _CreateTwizzScreenState extends State<CreateTwizzScreen> {
  late final _HighlightTextController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  // Mention state
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    // Initialize highlight controller
    _contentController = _HighlightTextController();

    // Clear all data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearAllData();
      _contentFocusNode.requestFocus();
    });

    // Listen to text changes for mention detection
    _contentController.addListener(_onTextChanged);
  }

  /// Clear all data (viewmodel + text controller)
  void _clearAllData() {
    final viewModel = context.read<CreateTwizzViewModel>();
    viewModel.clear();
    _contentController.clear();
    _hideMentionSuggestions();
  }

  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  /// Detect @ mention and trigger search
  void _onTextChanged() {
    final text = _contentController.text;
    final cursorPosition =
        _contentController.selection.baseOffset;

    if (cursorPosition < 0 || cursorPosition > text.length) {
      _hideMentionSuggestions();
      return;
    }

    // Find the last @ before cursor
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      // Stop if we hit whitespace or another special char
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex >= 0) {
      // Extract query after @
      final query = text.substring(atIndex + 1, cursorPosition);

      // Check if query is valid (no spaces)
      if (!query.contains(' ') && !query.contains('\n')) {
        setState(() {
          _showMentionSuggestions = true;
          _mentionQuery = query;
          _mentionStartIndex = atIndex;
        });

        // Search users
        final viewModel = context.read<CreateTwizzViewModel>();
        viewModel.searchUsers(query);
        return;
      }
    }

    _hideMentionSuggestions();
  }

  void _hideMentionSuggestions() {
    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionQuery = '';
        _mentionStartIndex = -1;
      });
      context.read<CreateTwizzViewModel>().clearSearchResults();
    }
  }

  /// Insert mention into text
  void _insertMention(SearchUserResult user) {
    final text = _contentController.text;
    final cursorPosition =
        _contentController.selection.baseOffset;

    // Replace @query with @username
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(cursorPosition);
    final newText =
        '$beforeMention@${user.username} $afterMention';

    _contentController.text = newText;

    // Move cursor after the mention
    final newCursorPosition =
        _mentionStartIndex + user.username.length + 2;
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPosition),
    );

    // Add to mentioned users
    final viewModel = context.read<CreateTwizzViewModel>();
    viewModel.addMention(user);
    viewModel.updateContent(newText);

    _hideMentionSuggestions();
  }

  /// Pick images from gallery
  Future<void> _pickImages(
    CreateTwizzViewModel viewModel,
  ) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        final files =
            images.map((xFile) => File(xFile.path)).toList();
        await viewModel.addImages(files);
        _showErrorIfAny(viewModel);
      }
    } catch (e) {
      debugPrint('Pick images error: $e');
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto(CreateTwizzViewModel viewModel) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        await viewModel.addImages([File(image.path)]);
        _showErrorIfAny(viewModel);
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  /// Pick video from gallery
  Future<void> _pickVideo(CreateTwizzViewModel viewModel) async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          minutes: CreateTwizzViewModel.maxVideoDurationMinutes,
        ),
      );

      if (video != null) {
        await viewModel.setVideo(File(video.path));
        _showErrorIfAny(viewModel);
      }
    } catch (e) {
      debugPrint('Pick video error: $e');
    }
  }

  /// Show error from viewmodel if any
  void _showErrorIfAny(CreateTwizzViewModel viewModel) {
    if (viewModel.error != null && mounted) {
      SnackBarUtils.showWarning(
        context,
        message: viewModel.error!,
      );
      viewModel.clearError();
    }
  }

  /// Show audience selector bottom sheet
  void _showAudienceSelector(
    BuildContext context,
    CreateTwizzViewModel viewModel,
  ) {
    final themeData = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: themeData.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chọn đối tượng',
                  style: themeData.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              // Everyone option
              _AudienceOption(
                icon: Icons.public,
                iconColor: themeData.colorScheme.primary,
                title: 'Tất cả mọi người',
                isSelected:
                    viewModel.audience == TwizzAudience.everyone,
                onTap: () {
                  viewModel.setAudience(TwizzAudience.everyone);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              // My Communities section
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cộng đồng của tôi',
                    style: themeData.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Twizz Circle option
              _AudienceOption(
                icon: Icons.group,
                iconColor: themeData.colorScheme.primary,
                title: 'Những người bạn cho phép',
                isSelected:
                    viewModel.audience ==
                    TwizzAudience.twizzCircle,
                onTap: () {
                  viewModel.setAudience(
                    TwizzAudience.twizzCircle,
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Create twizz
  Future<void> _createTwizz(
    CreateTwizzViewModel viewModel,
  ) async {
    final result = await viewModel.createTwizz();
    if (result != null && mounted) {
      // Add new twizz to newsfeed
      context.read<NewsFeedViewModel>().addTwizz(result);

      SnackBarUtils.showSuccess(
        context,
        message: 'Đăng bài thành công',
      );
      Navigator.pop(context, result);
    } else if (viewModel.apiError != null && mounted) {
      // Use ApiErrorResponse for detailed error
      SnackBarUtils.showApiError(
        context,
        error: viewModel.apiError!,
      );
    } else if (viewModel.error != null && mounted) {
      // Fallback to simple error message
      SnackBarUtils.showError(
        context,
        message: viewModel.error!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Consumer2<CreateTwizzViewModel, AuthViewModel>(
      builder: (context, viewModel, authViewModel, child) {
        final user = authViewModel.currentUser;
        final name = user?.name ?? 'User';
        final avatar = user?.avatar;

        return Scaffold(
          backgroundColor: themeData.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: themeData.scaffoldBackgroundColor,
            elevation: 0,
            leading: TextButton(
              onPressed:
                  viewModel.isLoading
                      ? null
                      : () {
                        _clearAllData();
                        Navigator.pop(context);
                      },
              child: Text(
                'Hủy',
                style: TextStyle(
                  color:
                      viewModel.isLoading
                          ? themeData.colorScheme.onSurface
                              .withValues(alpha: 0.4)
                          : themeData.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            leadingWidth: 80,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed:
                      viewModel.canPost
                          ? () => _createTwizz(viewModel)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        themeData.colorScheme.primary,
                    foregroundColor:
                        themeData.colorScheme.onPrimary,
                    disabledBackgroundColor: themeData
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    disabledForegroundColor: themeData
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                  ),
                  child:
                      viewModel.isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<
                                Color
                              >(themeData.colorScheme.onPrimary),
                            ),
                          )
                          : const Text(
                            'Đăng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User row with avatar and audience selector
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          avatar != null
                              ? CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(
                                  avatar,
                                ),
                                onBackgroundImageError:
                                    (e, s) {},
                              )
                              : CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    themeData
                                        .colorScheme
                                        .secondary,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeData
                                            .colorScheme
                                            .onSecondary,
                                  ),
                                ),
                              ),
                          const SizedBox(width: 12),
                          // Audience selector
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Audience button
                                InkWell(
                                  onTap:
                                      viewModel.isLoading
                                          ? null
                                          : () =>
                                              _showAudienceSelector(
                                                context,
                                                viewModel,
                                              ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            themeData
                                                .colorScheme
                                                .primary,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                            20,
                                          ),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Text(
                                          viewModel
                                              .audienceDisplayText,
                                          style: TextStyle(
                                            color:
                                                themeData
                                                    .colorScheme
                                                    .primary,
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons
                                              .keyboard_arrow_down,
                                          color:
                                              themeData
                                                  .colorScheme
                                                  .primary,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Text input
                                TextField(
                                  controller: _contentController,
                                  focusNode: _contentFocusNode,
                                  maxLines: null,
                                  minLines: 1,
                                  enabled: !viewModel.isLoading,
                                  style: themeData
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontSize: 20,
                                        height: 1.4,
                                      ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Chuyện gì đang xảy ra?',
                                    hintStyle: TextStyle(
                                      color: themeData
                                          .colorScheme
                                          .onSurface
                                          .withValues(
                                            alpha: 0.4,
                                          ),
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.normal,
                                    ),
                                    // Tùy chỉnh border cho các trạng thái
                                    border: InputBorder.none,
                                    fillColor:
                                        themeData
                                            .colorScheme
                                            .surface,
                                    enabledBorder:
                                        InputBorder.none,
                                    focusedBorder:
                                        InputBorder.none,
                                    disabledBorder:
                                        InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    viewModel.updateContent(
                                      value,
                                    );
                                  },
                                ),

                                // Mention suggestions
                                if (_showMentionSuggestions)
                                  _MentionSuggestions(
                                    query: _mentionQuery,
                                    results:
                                        viewModel.searchResults,
                                    isLoading:
                                        viewModel
                                            .isSearchingUsers,
                                    onSelect: _insertMention,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Selected media preview
                      if (viewModel.selectedImages.isNotEmpty)
                        _MediaPreview(
                          images: viewModel.selectedImages,
                          onRemove: viewModel.removeImage,
                          isLoading: viewModel.isLoading,
                        ),

                      if (viewModel.selectedVideo != null)
                        _VideoPreview(
                          video: viewModel.selectedVideo!,
                          onRemove: viewModel.removeVideo,
                          isLoading: viewModel.isLoading,
                        ),

                      // Upload progress
                      if (viewModel.isUploading)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                        Color
                                      >(
                                        themeData
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đang tải media...',
                                style: TextStyle(
                                  color: themeData
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom toolbar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: themeData.dividerColor.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        // Gallery (disabled when video selected or max images reached)
                        IconButton(
                          onPressed:
                              viewModel.isLoading ||
                                      viewModel.selectedVideo !=
                                          null ||
                                      viewModel
                                              .selectedImages
                                              .length >=
                                          CreateTwizzViewModel
                                              .maxImages
                                  ? null
                                  : () => _pickImages(viewModel),
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color:
                                viewModel.selectedVideo !=
                                            null ||
                                        viewModel
                                                .selectedImages
                                                .length >=
                                            CreateTwizzViewModel
                                                .maxImages
                                    ? themeData
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3)
                                    : themeData
                                        .colorScheme
                                        .primary,
                          ),
                        ),
                        // Camera (disabled when video selected or max images reached)
                        IconButton(
                          onPressed:
                              viewModel.isLoading ||
                                      viewModel.selectedVideo !=
                                          null ||
                                      viewModel
                                              .selectedImages
                                              .length >=
                                          CreateTwizzViewModel
                                              .maxImages
                                  ? null
                                  : () => _takePhoto(viewModel),
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            color:
                                viewModel.selectedVideo !=
                                            null ||
                                        viewModel
                                                .selectedImages
                                                .length >=
                                            CreateTwizzViewModel
                                                .maxImages
                                    ? themeData
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3)
                                        .withValues(alpha: 0.3)
                                    : themeData
                                        .colorScheme
                                        .primary,
                          ),
                        ),
                        // Video (disabled when images selected or already has video)
                        IconButton(
                          onPressed:
                              viewModel.isLoading ||
                                      viewModel
                                          .selectedImages
                                          .isNotEmpty ||
                                      viewModel.selectedVideo !=
                                          null
                                  ? null
                                  : () => _pickVideo(viewModel),
                          icon: Icon(
                            Icons.videocam_outlined,
                            color:
                                viewModel
                                            .selectedImages
                                            .isNotEmpty ||
                                        viewModel
                                                .selectedVideo !=
                                            null
                                    ? themeData
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3)
                                    : themeData
                                        .colorScheme
                                        .primary,
                          ),
                        ),
                        const Spacer(),
                        // Media count indicator
                        if (viewModel.selectedImages.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeData
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${viewModel.selectedImages.length}/${CreateTwizzViewModel.maxImages} ảnh',
                              style: TextStyle(
                                color:
                                    themeData
                                        .colorScheme
                                        .primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (viewModel.selectedVideo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeData
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              '1 video',
                              style: TextStyle(
                                color:
                                    themeData
                                        .colorScheme
                                        .primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Audience option widget
class _AudienceOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudienceOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: iconColor)),
            if (isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeData.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: themeData.colorScheme.onPrimary,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        title,
        style: themeData.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Media preview widget - Horizontal scrollable images
class _MediaPreview extends StatelessWidget {
  final List<File> images;
  final void Function(int) onRemove;
  final bool isLoading;

  const _MediaPreview({
    required this.images,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
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
class _VideoPreview extends StatefulWidget {
  final File video;
  final VoidCallback onRemove;
  final bool isLoading;

  const _VideoPreview({
    required this.video,
    required this.onRemove,
    required this.isLoading,
  });

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
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
                          color: Colors.black.withValues(
                            alpha: 0.6,
                          ),
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

/// Mention suggestions widget
class _MentionSuggestions extends StatelessWidget {
  final String query;
  final List<SearchUserResult> results;
  final bool isLoading;
  final void Function(SearchUserResult) onSelect;

  const _MentionSuggestions({
    required this.query,
    required this.results,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeData.dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(context, themeData),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData themeData,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      if (query.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nhập tên hoặc @username để tìm kiếm',
            style: themeData.textTheme.bodySmall?.copyWith(
              color: themeData.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không tìm thấy "@$query"',
          style: themeData.textTheme.bodySmall?.copyWith(
            color: themeData.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return _MentionUserTile(
          user: user,
          onTap: () => onSelect(user),
        );
      },
    );
  }
}

/// Mention user tile widget
class _MentionUserTile extends StatelessWidget {
  final SearchUserResult user;
  final VoidCallback onTap;

  const _MentionUserTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            // Avatar
            user.avatar != null
                ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(user.avatar!),
                  onBackgroundImageError: (e, s) {},
                )
                : CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      themeData.colorScheme.secondary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onSecondary,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF1DA1F2),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: themeData.textTheme.bodySmall
                        ?.copyWith(
                          color: themeData.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom TextEditingController to highlight hashtags and mentions
class _HighlightTextController extends TextEditingController {
  // Regex patterns
  static final RegExp _hashtagRegex = RegExp(r'#\w+');
  static final RegExp _mentionRegex = RegExp(r'@\w+');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final text = this.text;

    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    const highlightColor = Color(0xFF1DA1F2);

    // Find all matches
    final List<_TextMatch> matches = [];

    // Find hashtags
    for (final match in _hashtagRegex.allMatches(text)) {
      matches.add(
        _TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.hashtag,
        ),
      );
    }

    // Find mentions
    for (final match in _mentionRegex.allMatches(text)) {
      matches.add(
        _TextMatch(
          start: match.start,
          end: match.end,
          type: _MatchType.mention,
        ),
      );
    }

    // Sort by start position
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Build text spans
    int currentIndex = 0;

    for (final match in matches) {
      // Skip overlapping matches
      if (match.start < currentIndex) continue;

      // Add normal text before match
      if (match.start > currentIndex) {
        children.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: style,
          ),
        );
      }

      // Add highlighted text
      children.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style:
              style?.copyWith(color: highlightColor) ??
              TextStyle(color: highlightColor),
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      children.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: style,
        ),
      );
    }

    return TextSpan(children: children, style: style);
  }
}

/// Match type enum
enum _MatchType { hashtag, mention }

/// Text match helper class
class _TextMatch {
  final int start;
  final int end;
  final _MatchType type;

  _TextMatch({
    required this.start,
    required this.end,
    required this.type,
  });
}
