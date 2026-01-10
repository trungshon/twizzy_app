import 'storage_service.dart';
import '../../../core/constants/storage_keys.dart';

/// Token Storage Service
///
/// Service để lưu trữ và quản lý tokens
class TokenStorage {
  final StorageService _storageService;

  TokenStorage(this._storageService);

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storageService.write(StorageKeys.accessToken, token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storageService.read(StorageKeys.accessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storageService.write(StorageKeys.refreshToken, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storageService.read(StorageKeys.refreshToken);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await _storageService.delete(StorageKeys.accessToken);
    await _storageService.delete(StorageKeys.refreshToken);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
