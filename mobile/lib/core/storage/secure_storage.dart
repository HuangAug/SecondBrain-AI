import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearAuth() async {
    await delete(AppConstants.tokenKey);
    await delete(AppConstants.userIdKey);
    await delete(AppConstants.nicknameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await read(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
