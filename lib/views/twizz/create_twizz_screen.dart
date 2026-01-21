import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/auth/auth_models.dart';
import '../../models/twizz/twizz_models.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/twizz/create_twizz_viewmodel.dart';
import '../../widgets/common/twizz_video_player.dart';
import '../../widgets/twizz/twizz_create_media_preview.dart';
import '../../widgets/twizz/twizz_text_input_utils.dart';

/// Create Twizz Screen
///
/// Màn hình tạo bài viết mới
class CreateTwizzScreen extends StatefulWidget {
  final Twizz? parentTwizz; // For quote mode

  const CreateTwizzScreen({super.key, this.parentTwizz});

  @override
  State<CreateTwizzScreen> createState() =>
      _CreateTwizzScreenState();
}

class _CreateTwizzScreenState extends State<CreateTwizzScreen> {
  late final HighlightTextController _contentController;
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
    _contentController = HighlightTextController();

    // Clear all data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearAllData();
      // Set parent twizz for quote mode
      if (widget.parentTwizz != null) {
        context.read<CreateTwizzViewModel>().setParentTwizz(
          widget.parentTwizz,
        );
      }
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
    AuthViewModel authViewModel,
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
          child: SingleChildScrollView(
            child: Column(
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
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Chọn đối tượng',
                    style: themeData.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Everyone option
                _AudienceOption(
                  icon: Icons.public,
                  iconColor: themeData.colorScheme.primary,
                  title: 'Tất cả mọi người',
                  isSelected:
                      viewModel.audience ==
                      TwizzAudience.everyone,
                  onTap: () {
                    viewModel.setAudience(
                      TwizzAudience.everyone,
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

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

                // Twizz Circle Members Section
                const SizedBox(height: 8),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách người được xem',
                        style: themeData.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.person_add,
                          color: themeData.colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddToCircleBottomSheet(
                            context,
                            authViewModel,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Circle members list
                Consumer<AuthViewModel>(
                  builder: (context, auth, child) {
                    final twizzCircle =
                        auth.currentUser?.twizzCircle ?? [];
                    if (twizzCircle.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Chưa có ai trong danh sách',
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                color: themeData
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: twizzCircle.length,
                      itemBuilder: (context, index) {
                        final user = twizzCircle[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user.avatar != null
                                    ? NetworkImage(user.avatar!)
                                    : null,
                            child:
                                user.avatar == null
                                    ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0]
                                          : 'U',
                                    )
                                    : null,
                          ),
                          title: Text(user.name),
                          subtitle: Text(
                            '@${user.username ?? ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final success = await auth
                                  .removeFromTwizzCircle(user);
                              if (success && context.mounted) {
                                SnackBarUtils.showToast(
                                  context,
                                  message:
                                      'Đã xóa ${user.name} khỏi danh sách người xem',
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show bottom sheet to add user to Twizz Circle
  void _showAddToCircleBottomSheet(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    final themeData = Theme.of(context);
    final searchController = TextEditingController();
    final viewModel = context.read<CreateTwizzViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeData.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
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
                    'Thêm người vào danh sách',
                    style: themeData.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm người dùng...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        viewModel.searchUsers(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Search results
                Expanded(
                  child: Consumer2<
                    CreateTwizzViewModel,
                    AuthViewModel
                  >(
                    builder: (context, vm, auth, child) {
                      if (vm.isSearchingUsers) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (vm.searchResults.isEmpty) {
                        return Center(
                          child: Text(
                            searchController.text.isEmpty
                                ? 'Nhập tên để tìm kiếm'
                                : 'Không tìm thấy người dùng',
                            style: themeData.textTheme.bodyMedium
                                ?.copyWith(
                                  color: themeData
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: vm.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = vm.searchResults[index];
                          final isInCircle =
                              auth.currentUser?.twizzCircle?.any(
                                (u) => u.id == user.id,
                              ) ??
                              false;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  user.avatar != null
                                      ? NetworkImage(
                                        user.avatar!,
                                      )
                                      : null,
                              child:
                                  user.avatar == null
                                      ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0]
                                            : 'U',
                                      )
                                      : null,
                            ),
                            title: Text(user.name),
                            subtitle: Text('@${user.username}'),
                            trailing:
                                isInCircle
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color:
                                            themeData
                                                .colorScheme
                                                .primary,
                                      ),
                                      onPressed: () async {
                                        // Convert SearchUserResult to User
                                        final userToAdd = User(
                                          id: user.id,
                                          name: user.name,
                                          email: '',
                                          dateOfBirth:
                                              DateTime.now(),
                                          createdAt:
                                              DateTime.now(),
                                          updatedAt:
                                              DateTime.now(),
                                          verify:
                                              user.isVerified
                                                  ? 'Verified'
                                                  : 'Unverified',
                                          username:
                                              user.username,
                                          avatar: user.avatar,
                                        );
                                        final success = await auth
                                            .addToTwizzCircle(
                                              userToAdd,
                                            );
                                        if (success &&
                                            context.mounted) {
                                          SnackBarUtils.showToast(
                                            context,
                                            message:
                                                'Đã thêm ${user.name} vào danh sách người xem',
                                          );
                                        }
                                      },
                                    ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
      // Logic addTwizz removed as it is now handled by TwizzSyncService

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
                                                authViewModel,
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
                                        viewModel.isQuoteMode
                                            ? 'Thêm bình luận'
                                            : 'Chuyện gì đang xảy ra?',
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
                                  MentionSuggestions(
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

                      // Quote preview (parent twizz)
                      if (viewModel.isQuoteMode &&
                          viewModel.parentTwizz != null)
                        _QuoteTwizzPreview(
                          twizz: viewModel.parentTwizz!,
                        ),

                      // Selected media preview
                      if (viewModel.selectedImages.isNotEmpty)
                        TwizzCreateMediaPreview(
                          images: viewModel.selectedImages,
                          onRemove: viewModel.removeImage,
                          isLoading: viewModel.isLoading,
                        ),

                      if (viewModel.selectedVideo != null)
                        TwizzCreateVideoPreview(
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

/// Quote Twizz Preview - displays parent twizz in quote mode
class _QuoteTwizzPreview extends StatelessWidget {
  final Twizz twizz;

  const _QuoteTwizzPreview({required this.twizz});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final user = twizz.user;
    final name = user?.name ?? 'Người dùng';
    final username = user?.username ?? '';
    final avatar = user?.avatar;

    return Container(
      margin: const EdgeInsets.only(top: 16, left: 56),
      decoration: BoxDecoration(
        border: Border.all(
          color: themeData.colorScheme.onSurface.withValues(
            alpha: 0.2,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row
                  Row(
                    children: [
                      // Avatar
                      if (avatar != null)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(avatar),
                          onBackgroundImageError: (e, s) {},
                        )
                      else
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              themeData.colorScheme.secondary,
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  themeData
                                      .colorScheme
                                      .onSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Name
                      Flexible(
                        child: Text(
                          name,
                          style: themeData.textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Username
                      Flexible(
                        child: Text(
                          '@$username',
                          style: themeData.textTheme.bodySmall
                              ?.copyWith(
                                color: themeData
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Content
                  if (twizz.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      twizz.content,
                      style: themeData.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Nested parent preview
                  if (twizz.parentTwizz != null)
                    _QuoteTwizzPreview(
                      twizz: twizz.parentTwizz!,
                    ),
                ],
              ),
            ),
            // Media preview
            if (twizz.medias.isNotEmpty)
              _QuoteMediaPreview(medias: twizz.medias),
          ],
        ),
      ),
    );
  }
}

/// Quote Media Preview - displays media grid for quote preview
class _QuoteMediaPreview extends StatelessWidget {
  final List<Media> medias;

  const _QuoteMediaPreview({required this.medias});

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) return const SizedBox.shrink();

    final count = medias.length;
    final themeData = Theme.of(context);

    // Single image or video
    if (count == 1) {
      final media = medias.first;
      if (media.type == MediaType.video) {
        return TwizzVideoPlayer(url: media.url);
      }
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          media.url,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => _buildErrorPlaceholder(themeData),
        ),
      );
    }

    // Multiple images grid
    if (count == 2) {
      return AspectRatio(
        aspectRatio: 2 / 1,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(medias[0], themeData),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _buildGridImage(medias[1], themeData),
            ),
          ],
        ),
      );
    }

    if (count == 3) {
      return AspectRatio(
        aspectRatio: 2 / 1,
        child: Row(
          children: [
            Expanded(
              child: _buildGridImage(medias[0], themeData),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildGridImage(medias[1], themeData),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: _buildGridImage(medias[2], themeData),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ images
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildGridImage(medias[0], themeData),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildGridImage(medias[2], themeData),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildGridImage(medias[1], themeData),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildGridImage(medias[3], themeData),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImage(Media media, ThemeData themeData) {
    return SizedBox(
      width: double.infinity,
      child: Image.network(
        media.url,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => _buildErrorPlaceholder(themeData),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData themeData) {
    return Container(
      color: themeData.colorScheme.surface,
      child: Icon(
        Icons.broken_image_outlined,
        color: themeData.colorScheme.onSurface.withValues(
          alpha: 0.4,
        ),
      ),
    );
  }
}
