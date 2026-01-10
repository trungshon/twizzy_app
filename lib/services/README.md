# Services

Thư mục này chứa các **Services** - xử lý API calls và business logic phức tạp.

## Mục đích
- Xử lý các API calls với backend
- Xử lý local storage sử dụng **FlutterSecureStorage** (bảo mật cho tokens và sensitive data)
- Cung cấp interface cho ViewModels

## Cấu trúc
- `api/` - API services
  - `api_client.dart` - HTTP client (Dio/Http)
  - `api_endpoints.dart` - Định nghĩa các endpoints
  - `api_interceptor.dart` - Interceptor cho request/response
- `auth_service.dart` - Service xử lý authentication
- `local_storage/` - Local storage services
  - `storage_service.dart` - FlutterSecureStorage wrapper
  - `token_storage.dart` - Lưu trữ tokens (access_token, refresh_token)

## FlutterSecureStorage

Dự án sử dụng **FlutterSecureStorage** thay vì SharedPreferences vì:
- **Bảo mật cao hơn**: Dữ liệu được mã hóa và lưu trong Keychain (iOS) / Keystore (Android)
- **Phù hợp cho sensitive data**: Tokens, passwords, và thông tin nhạy cảm
- **Tự động mã hóa**: Không cần tự xử lý encryption

## Ví dụ

```dart
// services/local_storage/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

// services/local_storage/token_storage.dart
import '../local_storage/storage_service.dart';
import '../../core/constants/storage_keys.dart';

class TokenStorage {
  final StorageService _storageService;
  
  TokenStorage(this._storageService);
  
  Future<void> saveAccessToken(String token) async {
    await _storageService.write(StorageKeys.accessToken, token);
  }
  
  Future<String?> getAccessToken() async {
    return await _storageService.read(StorageKeys.accessToken);
  }
  
  Future<void> saveRefreshToken(String token) async {
    await _storageService.write(StorageKeys.refreshToken, token);
  }
  
  Future<String?> getRefreshToken() async {
    return await _storageService.read(StorageKeys.refreshToken);
  }
  
  Future<void> clearTokens() async {
    await _storageService.delete(StorageKeys.accessToken);
    await _storageService.delete(StorageKeys.refreshToken);
  }
}

// services/auth_service.dart
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  
  AuthService(this._apiClient, this._tokenStorage);
  
  Future<TokenResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    
    final tokenResponse = TokenResponse.fromJson(response.data);
    
    // Lưu tokens vào secure storage
    await _tokenStorage.saveAccessToken(tokenResponse.accessToken);
    await _tokenStorage.saveRefreshToken(tokenResponse.refreshToken);
    
    return tokenResponse;
  }
  
  Future<TokenResponse> register(RegisterRequest request) async {
    // Implementation
  }
  
  Future<void> logout(String refreshToken) async {
    try {
      await _apiClient.post(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
    } finally {
      // Xóa tokens khỏi storage dù API call thành công hay thất bại
      await _tokenStorage.clearTokens();
    }
  }
  
  Future<TokenResponse> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    
    final tokenResponse = TokenResponse.fromJson(response.data);
    
    // Lưu tokens mới
    await _tokenStorage.saveAccessToken(tokenResponse.accessToken);
    await _tokenStorage.saveRefreshToken(tokenResponse.refreshToken);
    
    return tokenResponse;
  }
}
```

## Lưu ý

### FlutterSecureStorage Configuration

```dart
// Android: Sử dụng EncryptedSharedPreferences
const AndroidOptions(
  encryptedSharedPreferences: true,
)

// iOS: Cấu hình Keychain accessibility
const IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
)
```

### Best Practices

1. **Chỉ lưu sensitive data**: Tokens, passwords, API keys
2. **Không lưu large data**: FlutterSecureStorage không phù hợp cho dữ liệu lớn
3. **Error handling**: Luôn xử lý lỗi khi đọc/ghi secure storage
4. **Clear on logout**: Luôn xóa tokens khi logout

### Storage Keys

Định nghĩa keys trong `core/constants/storage_keys.dart`:

```dart
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
}
```
