import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Set Username Screen
///
/// Màn hình đặt username sau khi xác thực email
class SetUsernameScreen extends StatefulWidget {
  const SetUsernameScreen({super.key});

  @override
  State<SetUsernameScreen> createState() =>
      _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  final TextEditingController _usernameController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentUser();
      });
      _isInit = false;
    }
  }

  Future<void> _loadCurrentUser() async {
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );
    if (authViewModel.currentUser == null) {
      await authViewModel.getMe();
    }

    if (authViewModel.currentUser != null &&
        authViewModel.currentUser!.username != null) {
      _usernameController.text =
          authViewModel.currentUser!.username!;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Show warning dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận tên người dùng?'),
            content: Text.rich(
              TextSpan(
                text: 'Bạn đang chọn tên người dùng là ',
                children: [
                  TextSpan(
                    text: '@${_usernameController.text}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '\n\nLƯU Ý: Bạn sẽ KHÔNG THỂ thay đổi tên người dùng này sau khi xác nhận.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _updateUsername();
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateUsername() async {
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );
    final success = await authViewModel.updateUsername(
      _usernameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.home,
        (route) => false,
      );
    } else if (mounted && authViewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isDarkMode = themeData.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: AppLogo(
                    showText: false,
                    isDarkMode: isDarkMode,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Chúng tôi nên gọi bạn là gì?',
                  style: themeData.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cảnh báo: Bạn sẽ không thể thay đổi tên người dùng sau này.',
                  style: themeData.textTheme.bodyMedium
                      ?.copyWith(
                        color: themeData.colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên người dùng',
                    prefixText: '@',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên người dùng';
                    }
                    if (value.length < 3) {
                      return 'Tên người dùng phải có ít nhất 3 ký tự';
                    }
                    // Simple regex for username
                    if (!RegExp(
                      r'^[a-zA-Z0-9_]+$',
                    ).hasMatch(value)) {
                      return 'Chỉ cho phép chữ cái, số và dấu gạch dưới';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _usernameController.text.isEmpty ||
                                authViewModel.isLoading
                            ? null
                            : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child:
                        authViewModel.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Tiếp theo'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
