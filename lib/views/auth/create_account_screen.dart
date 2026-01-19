import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../routes/route_names.dart';

/// Create Account Screen
///
/// Màn hình tạo tài khoản
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState
    extends State<CreateAccountScreen> {
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dateOfBirthController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _nameError = null; // Will be validated on submit
      } else if (trimmed.isEmpty) {
        _nameError = 'Tên phải có ít nhất 1 ký tự';
      } else if (trimmed.length > 100) {
        _nameError = 'Tên không được vượt quá 100 ký tự';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _emailError = null; // Will be validated on submit
      } else {
        // Basic email validation
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailRegex.hasMatch(trimmed)) {
          _emailError = 'Email không hợp lệ';
        } else {
          _emailError = null;
        }
      }
    });
  }

  bool _isStrongPassword(String password) {
    // At least 6 characters, 1 lowercase, 1 uppercase, 1 number, 1 symbol
    if (password.length < 6 || password.length > 50) {
      return false;
    }
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );
    return hasLowercase &&
        hasUppercase &&
        hasNumber &&
        hasSymbol;
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = null; // Will be validated on submit
      } else if (value.length < 6) {
        _passwordError = 'Mật khẩu phải có từ 6 đến 50 ký tự';
      } else if (value.length > 50) {
        _passwordError = 'Mật khẩu không được vượt quá 50 ký tự';
      } else if (!_isStrongPassword(value)) {
        _passwordError =
            'Mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
      } else {
        _passwordError = null;
        // Re-validate confirm password if it's already filled
        if (_confirmPasswordController.text.isNotEmpty) {
          _validateConfirmPassword(
            _confirmPasswordController.text,
          );
        }
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError =
            null; // Will be validated on submit
      } else if (value.length < 6) {
        _confirmPasswordError =
            'Xác nhận mật khẩu phải có từ 6 đến 50 ký tự';
      } else if (value.length > 50) {
        _confirmPasswordError =
            'Xác nhận mật khẩu không được vượt quá 50 ký tự';
      } else if (!_isStrongPassword(value)) {
        _confirmPasswordError =
            'Xác nhận mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
      } else if (value != _passwordController.text) {
        _confirmPasswordError =
            'Xác nhận mật khẩu và mật khẩu phải giống nhau';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Tiêu đề
                  Text(
                    'Tạo tài khoản của bạn',
                    style: themeData.textTheme.headlineLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Input field Tên
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      errorText: _nameError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    maxLength: 100,
                    onChanged: _validateName,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$currentLength / $maxLength',
                            style: TextStyle(
                              color: themeData
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input field Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      errorText: _emailError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Input field Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      errorText: _passwordError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    onChanged: (value) {
                      _validatePassword(value);
                      // Re-validate confirm password if it's already filled
                      if (_confirmPasswordController
                          .text
                          .isNotEmpty) {
                        _validateConfirmPassword(
                          _confirmPasswordController.text,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input field Confirm Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.error,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      errorText: _confirmPasswordError,
                      errorMaxLines: 3,
                    ),
                    style: themeData.textTheme.bodyMedium,
                    onChanged: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 24),

                  // Text giải thích về Ngày sinh
                  Text(
                    'Điều này sẽ không được hiển thị công khai. Xác nhận tuổi của bạn, ngay cả khi tài khoản này dành cho doanh nghiệp, thú cưng hoặc thứ gì khác.',
                    style: themeData.textTheme.bodySmall
                        ?.copyWith(fontSize: 13),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 16),

                  // Input field Ngày sinh
                  TextField(
                    controller: _dateOfBirthController,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      labelStyle: TextStyle(
                        color:
                            themeData
                                .textTheme
                                .bodyMedium
                                ?.color,
                      ),
                      filled: true,
                      fillColor: themeData.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeData.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: themeData.textTheme.bodyMedium,
                    readOnly: true,
                    onTap: () async {
                      // TODO: Show date picker
                      final DateTime? picked =
                          await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            locale: const Locale('vi', 'VN'),
                          );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _dateOfBirthController.text =
                              '${picked.day}/${picked.month}/${picked.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Nút Tiếp theo
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              authViewModel.isLoading
                                  ? null
                                  : () async {
                                    // Validate all fields
                                    final name =
                                        _nameController.text
                                            .trim();
                                    final email =
                                        _emailController.text
                                            .trim();
                                    final password =
                                        _passwordController.text;
                                    final confirmPassword =
                                        _confirmPasswordController
                                            .text;

                                    // Validate name
                                    if (name.isEmpty) {
                                      setState(() {
                                        _nameError =
                                            'Tên không được để trống';
                                      });
                                      return;
                                    }
                                    if (name.isEmpty ||
                                        name.length > 100) {
                                      setState(() {
                                        _nameError =
                                            'Tên phải có từ 1 đến 100 ký tự';
                                      });
                                      return;
                                    }

                                    // Validate email
                                    if (email.isEmpty) {
                                      setState(() {
                                        _emailError =
                                            'Email không được để trống';
                                      });
                                      return;
                                    }
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );
                                    if (!emailRegex.hasMatch(
                                      email,
                                    )) {
                                      setState(() {
                                        _emailError =
                                            'Email không hợp lệ';
                                      });
                                      return;
                                    }

                                    // Validate password
                                    if (password.isEmpty) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu không được để trống';
                                      });
                                      return;
                                    }
                                    if (password.length < 6 ||
                                        password.length > 50) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu phải có từ 6 đến 50 ký tự';
                                      });
                                      return;
                                    }
                                    if (!_isStrongPassword(
                                      password,
                                    )) {
                                      setState(() {
                                        _passwordError =
                                            'Mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
                                      });
                                      return;
                                    }

                                    // Validate confirm password
                                    if (confirmPassword
                                        .isEmpty) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu không được để trống';
                                      });
                                      return;
                                    }
                                    if (confirmPassword.length <
                                            6 ||
                                        confirmPassword.length >
                                            50) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu phải có từ 6 đến 50 ký tự';
                                      });
                                      return;
                                    }
                                    if (!_isStrongPassword(
                                      confirmPassword,
                                    )) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu phải có ít nhất 6 ký tự và chứa ít nhất một chữ cái viết hoa, một chữ cái viết thường, một số và một ký tự đặc biệt';
                                      });
                                      return;
                                    }
                                    if (confirmPassword !=
                                        password) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Xác nhận mật khẩu và mật khẩu phải giống nhau';
                                      });
                                      return;
                                    }

                                    // Validate date of birth
                                    if (_selectedDate == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).clearSnackBars();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Vui lòng chọn ngày sinh',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Format date to ISO 8601 (YYYY-MM-DD)
                                    final dateOfBirth =
                                        _selectedDate!
                                            .toIso8601String()
                                            .split('T')[0];

                                    // Call register
                                    final success =
                                        await authViewModel
                                            .register(
                                              name: name,
                                              email: email,
                                              password: password,
                                              confirmPassword:
                                                  confirmPassword,
                                              dateOfBirth:
                                                  dateOfBirth,
                                            );

                                    if (success &&
                                        context.mounted) {
                                      // Navigate to verify email screen
                                      Navigator.of(
                                        context,
                                      ).pushNamed(
                                        RouteNames.verifyEmail,
                                        arguments:
                                            _emailController.text
                                                .trim(),
                                      );
                                    } else if (context.mounted &&
                                        authViewModel.error !=
                                            null) {
                                      // Handle validation errors from backend
                                      final apiError =
                                          authViewModel.apiError;
                                      if (apiError != null &&
                                          apiError
                                              .hasValidationErrors()) {
                                        // Set field-specific errors
                                        setState(() {
                                          // Map backend field names to local field names
                                          final emailError =
                                              apiError
                                                  .getFieldError(
                                                    'email',
                                                  );
                                          if (emailError !=
                                              null) {
                                            _emailError =
                                                emailError;
                                          }

                                          final nameError =
                                              apiError
                                                  .getFieldError(
                                                    'name',
                                                  );
                                          if (nameError !=
                                              null) {
                                            _nameError =
                                                nameError;
                                          }

                                          final passwordError =
                                              apiError
                                                  .getFieldError(
                                                    'password',
                                                  );
                                          if (passwordError !=
                                              null) {
                                            _passwordError =
                                                passwordError;
                                          }

                                          final confirmPasswordError =
                                              apiError.getFieldError(
                                                'confirm_password',
                                              );
                                          if (confirmPasswordError !=
                                              null) {
                                            _confirmPasswordError =
                                                confirmPasswordError;
                                          }

                                          final dateOfBirthError =
                                              apiError
                                                  .getFieldError(
                                                    'date_of_birth',
                                                  );
                                          if (dateOfBirthError !=
                                              null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).clearSnackBars();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  dateOfBirthError,
                                                  style: const TextStyle(
                                                    color:
                                                        Colors
                                                            .white,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    themeData
                                                        .colorScheme
                                                        .error,
                                              ),
                                            );
                                          }
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).clearSnackBars();
                                        // Show general error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              authViewModel
                                                  .error!,
                                              style:
                                                  const TextStyle(
                                                    color:
                                                        Colors
                                                            .white,
                                                  ),
                                            ),
                                            backgroundColor:
                                                themeData
                                                    .colorScheme
                                                    .error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(24),
                            ),
                          ),
                          child:
                              authViewModel.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                            Color
                                          >(Colors.white),
                                    ),
                                  )
                                  : const Text(
                                    'Tiếp theo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
