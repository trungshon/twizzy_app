/// Auth Models
///
/// Models cho authentication

/// Login Request Model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

/// Login Response Model
class LoginResponse {
  final String message;
  final TokenResponse result;

  LoginResponse({required this.message, required this.result});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      result: TokenResponse.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Refresh Token Request Model
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
    'refresh_token': refreshToken,
  };
}

/// Refresh Token Response Model
class RefreshTokenResponse {
  final String message;
  final TokenResponse result;

  RefreshTokenResponse({
    required this.message,
    required this.result,
  });

  factory RefreshTokenResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RefreshTokenResponse(
      message: json['message'] as String,
      result: TokenResponse.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Register Request Model
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String dateOfBirth; // ISO 8601 format: YYYY-MM-DD

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'confirm_password': confirmPassword,
    'date_of_birth': dateOfBirth,
  };
}

/// Token Response Model
class TokenResponse {
  final String accessToken;
  final String refreshToken;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}

/// Register Response Model
class RegisterResponse {
  final String message;
  final TokenResponse result;

  RegisterResponse({
    required this.message,
    required this.result,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String,
      result: TokenResponse.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Verify Email Request Model
class VerifyEmailRequest {
  final String email;
  final String emailVerifyOtp;

  VerifyEmailRequest({
    required this.email,
    required this.emailVerifyOtp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'email_verify_otp': emailVerifyOtp,
  };
}

/// Verify Email Response Model
class VerifyEmailResponse {
  final String message;
  final TokenResponse? result;

  VerifyEmailResponse({required this.message, this.result});

  factory VerifyEmailResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerifyEmailResponse(
      message: json['message'] as String,
      result:
          json['result'] != null
              ? TokenResponse.fromJson(
                json['result'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Validation Error Model
class ValidationError {
  final String msg;
  final String? value;
  final String? path;
  final String? location;

  ValidationError({
    required this.msg,
    this.value,
    this.path,
    this.location,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      msg: json['msg'] as String? ?? '',
      value: json['value'] as String?,
      path: json['path'] as String?,
      location: json['location'] as String?,
    );
  }
}

/// API Error Response Model
class ApiErrorResponse {
  final String message;
  final int? statusCode;
  final Map<String, ValidationError>?
  errors; // Validation errors by field

  ApiErrorResponse({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    Map<String, ValidationError>? errors;
    if (json['errors'] != null) {
      final errorsJson = json['errors'] as Map<String, dynamic>;
      errors = errorsJson.map(
        (key, value) => MapEntry(
          key,
          ValidationError.fromJson(
            value as Map<String, dynamic>,
          ),
        ),
      );
    }

    return ApiErrorResponse(
      message: json['message'] as String? ?? 'Có lỗi xảy ra',
      statusCode: json['statusCode'] as int?,
      errors: errors,
    );
  }

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    return errors?[fieldName]?.msg;
  }

  /// Check if there are validation errors
  bool hasValidationErrors() {
    return errors != null && errors!.isNotEmpty;
  }
}

/// User Model
class User {
  final String id;
  final String name;
  final String email;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String verify; // 'Unverified' or 'Verified'
  final String? bio;
  final String? location;
  final String? website;
  final String? username;
  final String? avatar;
  final String? coverPhoto;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.verify,
    this.bio,
    this.location,
    this.website,
    this.username,
    this.avatar,
    this.coverPhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle _id which can be ObjectId or String
    String id = '';
    if (json['_id'] != null) {
      if (json['_id'] is Map) {
        id =
            json['_id']['\$oid'] as String? ??
            json['_id'].toString();
      } else {
        id = json['_id'].toString();
      }
    }

    // Handle date_of_birth which can be Date or String
    DateTime dateOfBirth = DateTime.now();
    if (json['date_of_birth'] != null) {
      if (json['date_of_birth'] is String) {
        dateOfBirth = DateTime.parse(json['date_of_birth']);
      } else if (json['date_of_birth'] is Map) {
        // MongoDB Date format
        final dateStr =
            json['date_of_birth']['\$date'] as String?;
        if (dateStr != null) {
          dateOfBirth = DateTime.parse(dateStr);
        }
      }
    }

    // Handle created_at
    DateTime createdAt = DateTime.now();
    if (json['created_at'] != null) {
      if (json['created_at'] is String) {
        createdAt = DateTime.parse(json['created_at']);
      } else if (json['created_at'] is Map) {
        final dateStr = json['created_at']['\$date'] as String?;
        if (dateStr != null) {
          createdAt = DateTime.parse(dateStr);
        }
      }
    }

    // Handle updated_at
    DateTime updatedAt = DateTime.now();
    if (json['updated_at'] != null) {
      if (json['updated_at'] is String) {
        updatedAt = DateTime.parse(json['updated_at']);
      } else if (json['updated_at'] is Map) {
        final dateStr = json['updated_at']['\$date'] as String?;
        if (dateStr != null) {
          updatedAt = DateTime.parse(dateStr);
        }
      }
    }

    // Handle verify field - can be int (enum) or string
    String verify = 'Unverified';
    if (json['verify'] != null) {
      if (json['verify'] is int) {
        // Enum: 0 = Unverified, 1 = Verified, 2 = Banned
        final verifyInt = json['verify'] as int;
        switch (verifyInt) {
          case 0:
            verify = 'Unverified';
            break;
          case 1:
            verify = 'Verified';
            break;
          case 2:
            verify = 'Banned';
            break;
          default:
            verify = 'Unverified';
        }
      } else if (json['verify'] is String) {
        verify = json['verify'] as String;
      }
    }

    // Helper function to safely convert to String?
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    return User(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: dateOfBirth,
      createdAt: createdAt,
      updatedAt: updatedAt,
      verify: verify,
      bio: safeString(json['bio']),
      location: safeString(json['location']),
      website: safeString(json['website']),
      username: safeString(json['username']),
      avatar: safeString(json['avatar']),
      coverPhoto: safeString(json['cover_photo']),
    );
  }
}

/// Get Me Response Model
class GetMeResponse {
  final String message;
  final User result;

  GetMeResponse({required this.message, required this.result});

  factory GetMeResponse.fromJson(Map<String, dynamic> json) {
    return GetMeResponse(
      message: json['message'] as String,
      result: User.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Forgot Password Request Model
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// Forgot Password Response Model
class ForgotPasswordResponse {
  final String message;

  ForgotPasswordResponse({required this.message});

  factory ForgotPasswordResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ForgotPasswordResponse(
      message: json['message'] as String,
    );
  }
}

/// Verify Forgot Password Request Model
class VerifyForgotPasswordRequest {
  final String email;
  final String forgotPasswordOtp;

  VerifyForgotPasswordRequest({
    required this.email,
    required this.forgotPasswordOtp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'forgot_password_otp': forgotPasswordOtp,
  };
}

/// Verify Forgot Password Response Model
class VerifyForgotPasswordResponse {
  final String message;

  VerifyForgotPasswordResponse({required this.message});

  factory VerifyForgotPasswordResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerifyForgotPasswordResponse(
      message: json['message'] as String,
    );
  }
}

/// Reset Password Request Model
class ResetPasswordRequest {
  final String email;
  final String forgotPasswordOtp;
  final String password;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.email,
    required this.forgotPasswordOtp,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'forgot_password_otp': forgotPasswordOtp,
    'password': password,
    'confirm_password': confirmPassword,
  };
}

/// Reset Password Response Model
class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResetPasswordResponse(
      message: json['message'] as String,
    );
  }
}
