import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // 웹 호환성 옵션
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'ACCESS_TOKEN', value: accessToken);
    await _storage.write(key: 'REFRESH_TOKEN', value: refreshToken);
  }

  static Future<String?> getAccessToken() async => await _storage.read(key: 'ACCESS_TOKEN');
  static Future<String?> getRefreshToken() async => await _storage.read(key: 'REFRESH_TOKEN');
  static Future<void> deleteAll() async => await _storage.deleteAll();
}