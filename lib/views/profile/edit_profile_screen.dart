import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/snackbar_utils.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/profile/edit_profile_viewmodel.dart';
import '../../viewmodels/newsfeed/newsfeed_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/auth/auth_models.dart';

/// Edit Profile Screen
///
/// Màn hình chỉnh sửa thông tin profile
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _usernameController;
  final ImagePicker _imagePicker = ImagePicker();

  // Location search state
  List<dynamic> _locationSuggestions = [];
  Timer? _debounceTimer;
  bool _isSearchingLocation = false;
  StateSetter? _dialogSetState; // To refresh dialog UI

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _usernameController = TextEditingController();

    // Initialize form with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final editProfileViewModel =
          context.read<EditProfileViewModel>();
      final user = authViewModel.currentUser;
      if (user != null) {
        editProfileViewModel.initialize(user);
        _nameController.text = user.name;
        _bioController.text = user.bio ?? '';
        _locationController.text = user.location ?? '';
        _websiteController.text = user.website ?? '';
        _usernameController.text = '@${user.username}';
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    final editProfileViewModel =
        context.read<EditProfileViewModel>();

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            message: 'Vui lòng bật dịch vụ vị trí trên thiết bị',
          );
        }
        return;
      }

      // 2. Check and request permissions
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackBarUtils.showWarning(
              context,
              message: 'Quyền vị trí bị từ chối',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackBarUtils.showWarning(
            context,
            message:
                'Quyền vị trí bị từ chối vĩnh viễn, vui lòng cài đặt lại',
          );
        }
        return;
      }

      // 3. Get current position
      if (mounted) {
        SnackBarUtils.showInfo(
          context,
          message: 'Đang lấy vị trí...',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Get address from coordinates
      String? locationStr;
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Format: City, Country
          String cityStr = '';
          if (place.locality != null &&
              place.locality!.isNotEmpty) {
            cityStr = place.locality!;
          } else if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            cityStr = place.subAdministrativeArea!;
          }

          if (place.country != null &&
              place.country!.isNotEmpty) {
            locationStr =
                cityStr.isEmpty
                    ? place.country!
                    : '$cityStr, ${place.country}';
          } else {
            locationStr = cityStr;
          }
        }
      } catch (e) {
        debugPrint(
          'System geocoding failed, trying fallback: $e',
        );
        // Fallback to Nominatim
        locationStr = await _reverseGeocodeNominatim(
          position.latitude,
          position.longitude,
        );
      }

      if (locationStr != null && locationStr.isNotEmpty) {
        if (mounted) {
          _locationController.text = locationStr;
          editProfileViewModel.updateLocation(locationStr);
          SnackBarUtils.showSuccess(
            context,
            message: 'Đã nhận diện: $locationStr',
          );
        }
      } else {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            message: 'Không thể xác định địa chỉ từ tọa độ này',
          );
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          message: 'Không thể lấy vị trí: ${e.toString()}',
        );
      }
    }
  }

  Future<String?> _reverseGeocodeNominatim(
    double lat,
    double lon,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
        ),
        headers: {'User-Agent': 'TwizzyApp'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          response.body,
        );
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          String city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              '';
          String country = address['country'] ?? '';

          if (city.isNotEmpty && country.isNotEmpty) {
            return '$city, $country';
          } else if (city.isNotEmpty) {
            return city;
          } else if (country.isNotEmpty) {
            return country;
          }
          return data['display_name']; // Fallback to full display name
        }
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocode error: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onLocationChanged(String query) {
    if (_debounceTimer?.isActive ?? false)
      _debounceTimer!.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        if (query.trim().length > 2) {
          _searchLocation(query);
        } else {
          if (_dialogSetState != null) {
            _dialogSetState!(() {
              _locationSuggestions = [];
            });
          }
        }
      },
    );
  }

  Future<void> _searchLocation(String query) async {
    if (_dialogSetState != null) {
      _dialogSetState!(() {
        _isSearchingLocation = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
        ),
        headers: {'User-Agent': 'TwizzyApp'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (_dialogSetState != null) {
          _dialogSetState!(() {
            _locationSuggestions = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      if (_dialogSetState != null) {
        _dialogSetState!(() {
          _isSearchingLocation = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMMM, yyyy', 'vi').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    final editProfileViewModel =
        context.read<EditProfileViewModel>();
    final user = authViewModel.currentUser;
    final initialDate =
        editProfileViewModel.dateOfBirth ??
        user?.dateOfBirth ??
        DateTime.now();
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      editProfileViewModel.updateDateOfBirth(picked);
    }
  }

  Future<void> _handleSave() async {
    final authViewModel = context.read<AuthViewModel>();
    final editProfileViewModel =
        context.read<EditProfileViewModel>();
    final user = authViewModel.currentUser;

    if (user == null) return;

    // Check if there are changes
    if (!editProfileViewModel.hasChanges(user)) {
      Navigator.pop(context);
      return;
    }

    // Update fields from controllers
    editProfileViewModel.updateName(
      _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );
    editProfileViewModel.updateBio(
      _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    );
    editProfileViewModel.updateLocation(
      _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    editProfileViewModel.updateWebsite(
      _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
    );

    final updatedUser = await editProfileViewModel.updateProfile(
      user,
    );

    if (updatedUser != null && mounted) {
      // Reload auth data to reflect profile changes
      await authViewModel.getMe();

      if (mounted) {
        // Refresh NewsFeed to update user info in posts
        final newsFeedViewModel =
            context.read<NewsFeedViewModel>();
        await newsFeedViewModel.refresh();

        if (mounted) {
          // Return true to signal profile screen to reload
          Navigator.pop(context, true);
        }
      }
    } else if (mounted) {
      // Show error
      SnackBarUtils.showError(
        context,
        message: editProfileViewModel.error ?? 'Có lỗi xảy ra',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Consumer2<AuthViewModel, EditProfileViewModel>(
      builder: (
        context,
        authViewModel,
        editProfileViewModel,
        child,
      ) {
        final user = authViewModel.currentUser;
        final hasChanges =
            user != null &&
            editProfileViewModel.hasChanges(user);

        return Scaffold(
          appBar: AppBar(
            leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ),
            title: Text(
              'Chỉnh sửa hồ sơ',
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed:
                    editProfileViewModel.isLoading || !hasChanges
                        ? null
                        : _handleSave,
                child:
                    editProfileViewModel.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'Lưu',
                          style: TextStyle(
                            color:
                                hasChanges
                                    ? themeData
                                        .colorScheme
                                        .primary
                                    : themeData
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
          body:
              user == null
                  ? const Center(
                    child: CircularProgressIndicator(),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Cover Photo Section
                        _buildCoverPhotoSection(
                          context,
                          themeData,
                          editProfileViewModel,
                          user,
                        ),
                        const SizedBox(height: 24),

                        // Avatar Section
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      themeData
                                          .scaffoldBackgroundColor,
                                  width: 4,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    editProfileViewModel
                                                .avatar !=
                                            null
                                        ? NetworkImage(
                                          editProfileViewModel
                                              .avatar!,
                                        )
                                        : null,
                                backgroundColor:
                                    themeData
                                        .colorScheme
                                        .primary,
                                child:
                                    editProfileViewModel
                                                .avatar ==
                                            null
                                        ? Text(
                                          user.name.isNotEmpty
                                              ? user.name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                themeData
                                                    .colorScheme
                                                    .onPrimary,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    editProfileViewModel
                                            .isUploadingImage
                                        ? null
                                        : () =>
                                            _showImagePickerDialog(
                                              context,
                                              editProfileViewModel,
                                              isAvatar: true,
                                            ),
                                icon:
                                    editProfileViewModel
                                            .isUploadingImage
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                        )
                                        : const Icon(
                                          Icons
                                              .camera_alt_outlined,
                                        ),
                                label: const Text(
                                  'Đổi ảnh đại diện',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        _buildTextField(
                          context,
                          controller: _nameController,
                          label: 'Tên',
                          hintText: 'Thêm tên của bạn',
                          onChanged: (value) {
                            editProfileViewModel.updateName(
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Username Field
                        _buildTextField(
                          context,
                          controller: _usernameController,
                          label: 'Username',
                          hintText: 'Thêm username của bạn',
                          enabled: false,
                          onChanged: (value) {
                            editProfileViewModel.updateUsername(
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Bio Field
                        _buildTextField(
                          context,
                          controller: _bioController,
                          label: 'Tiểu sử',
                          hintText:
                              'Thêm tiểu sử vào hồ sơ của bạn',
                          maxLines: 3,
                          onChanged: (value) {
                            editProfileViewModel.updateBio(
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location Field
                        _buildSelectableField(
                          context,
                          label: 'Vị trí',
                          value:
                              editProfileViewModel.location ??
                              '',
                          hintText: 'Thêm vị trí của bạn',
                          onTap: () {
                            _locationSuggestions = [];
                            showDialog(
                              context: context,
                              builder:
                                  (
                                    dialogContext,
                                  ) => StatefulBuilder(
                                    builder: (
                                      context,
                                      setDialogState,
                                    ) {
                                      _dialogSetState =
                                          setDialogState;
                                      return AlertDialog(
                                        title: const Text(
                                          'Chọn vị trí',
                                        ),
                                        content: SizedBox(
                                          width:
                                              double.maxFinite,
                                          child: Column(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller:
                                                    _locationController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Nhập vị trí',
                                                  prefixIcon:
                                                      const Icon(
                                                        Icons
                                                            .location_on,
                                                      ),
                                                  suffixIcon:
                                                      _isSearchingLocation
                                                          ? const SizedBox(
                                                            width:
                                                                20,
                                                            height:
                                                                20,
                                                            child: Padding(
                                                              padding: EdgeInsets.all(
                                                                12.0,
                                                              ),
                                                              child: CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2,
                                                              ),
                                                            ),
                                                          )
                                                          : null,
                                                ),
                                                onChanged:
                                                    _onLocationChanged,
                                              ),
                                              if (_locationSuggestions
                                                  .isNotEmpty)
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight:
                                                            200,
                                                      ),
                                                  child: ListView.builder(
                                                    shrinkWrap:
                                                        true,
                                                    itemCount:
                                                        _locationSuggestions
                                                            .length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final suggestion =
                                                          _locationSuggestions[index];
                                                      return ListTile(
                                                        dense:
                                                            true,
                                                        title: Text(
                                                          suggestion['display_name'],
                                                          maxLines:
                                                              2,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontSize:
                                                                13,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          _locationController.text =
                                                              suggestion['display_name'];
                                                          editProfileViewModel.updateLocation(
                                                            _locationController
                                                                .text,
                                                          );
                                                          setDialogState(() {
                                                            _locationSuggestions =
                                                                [];
                                                          });
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              const SizedBox(
                                                height: 16,
                                              ),
                                              SizedBox(
                                                width:
                                                    double
                                                        .infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    Navigator.pop(
                                                      dialogContext,
                                                    );
                                                    await _getCurrentLocation();
                                                  },
                                                  icon: const Icon(
                                                    Icons
                                                        .my_location,
                                                  ),
                                                  label: const Text(
                                                    'Lấy vị trí hiện tại',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              _dialogSetState =
                                                  null;
                                              Navigator.pop(
                                                dialogContext,
                                              );
                                            },
                                            child: const Text(
                                              'Hủy',
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              editProfileViewModel
                                                  .updateLocation(
                                                    _locationController
                                                        .text,
                                                  );
                                              _dialogSetState =
                                                  null;
                                              Navigator.pop(
                                                dialogContext,
                                              );
                                            },
                                            child: const Text(
                                              'Xong',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                            ).then(
                              (_) => _dialogSetState = null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Website Field
                        _buildTextField(
                          context,
                          controller: _websiteController,
                          label: 'Trang web',
                          hintText: 'Thêm website của bạn',
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            editProfileViewModel.updateWebsite(
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth Field
                        _buildSelectableField(
                          context,
                          label: 'Ngày sinh',
                          value: _formatDate(
                            editProfileViewModel.dateOfBirth,
                          ),
                          hintText: 'Thêm ngày sinh của bạn',
                          onTap: () => _selectDate(context),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    final themeData = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeData.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style:
              !enabled
                  ? themeData.textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  )
                  : null,
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintStyle: themeData.textTheme.bodyMedium?.copyWith(
              color: themeData.disabledColor,
            ),

            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor:
                enabled
                    ? themeData.colorScheme.surface
                    : themeData.disabledColor.withValues(
                      alpha: 0.07,
                    ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSelectableField(
    BuildContext context, {
    required String label,
    required String value,
    required String hintText,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    final displayText = value.isEmpty ? hintText : value;
    final textColor =
        value.isEmpty
            ? themeData.colorScheme.onSurface.withValues(
              alpha: 0.4,
            )
            : themeData.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: themeData.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: themeData.colorScheme.outline.withValues(
                  alpha: 0.2,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
              color: themeData.colorScheme.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(color: textColor),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: themeData.colorScheme.onSurface
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPhotoSection(
    BuildContext context,
    ThemeData themeData,
    EditProfileViewModel editProfileViewModel,
    User user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh bìa',
          style: themeData.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: themeData.colorScheme.surface,
              ),
              child:
                  editProfileViewModel.coverPhoto != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          editProfileViewModel.coverPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color: const Color(0xFF5C7A7A),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: themeData
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      : Container(
                        color: const Color(0xFF5C7A7A),
                        child: Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: themeData
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: OutlinedButton.icon(
                onPressed:
                    editProfileViewModel.isUploadingImage
                        ? null
                        : () => _showImagePickerDialog(
                          context,
                          editProfileViewModel,
                          isAvatar: false,
                        ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(
                    alpha: 0.6,
                  ),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Đổi ảnh bìa',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showImagePickerDialog(
    BuildContext context,
    EditProfileViewModel editProfileViewModel, {
    required bool isAvatar,
  }) async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                      context,
                      editProfileViewModel,
                      ImageSource.gallery,
                      isAvatar: isAvatar,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Chụp ảnh'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                      context,
                      editProfileViewModel,
                      ImageSource.camera,
                      isAvatar: isAvatar,
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    EditProfileViewModel editProfileViewModel,
    ImageSource source, {
    required bool isAvatar,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: isAvatar ? 400 : 1920,
        maxHeight: isAvatar ? 400 : 1080,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        String? imageUrl;
        if (isAvatar) {
          imageUrl = await editProfileViewModel.uploadAvatar(
            file,
          );
        } else {
          imageUrl = await editProfileViewModel.uploadCoverPhoto(
            file,
          );
        }

        if (imageUrl != null && mounted) {
          SnackBarUtils.showSuccess(
            this.context,
            message:
                isAvatar
                    ? 'Đã cập nhật ảnh đại diện'
                    : 'Đã cập nhật ảnh bìa',
          );
        } else if (mounted &&
            editProfileViewModel.error != null) {
          SnackBarUtils.showError(
            this.context,
            message:
                editProfileViewModel.error ?? 'Có lỗi xảy ra',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          this.context,
          message: 'Lỗi chọn ảnh: ${e.toString()}',
        );
      }
    }
  }
}
