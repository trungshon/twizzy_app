import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage Service
///
/// Wrapper cho FlutterSecureStorage
class StorageService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility:
              KeychainAccessibility.first_unlock_this_device,
        ),
      );

  /// Write value to secure storage
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read value from secure storage
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete value from secure storage
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
