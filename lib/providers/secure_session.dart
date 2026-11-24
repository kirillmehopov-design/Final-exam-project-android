import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Session secrets belong in native encrypted KeyStore / Keychain, not in
/// SharedPreferences. Web uses platform WebCrypto on secure origins.
class SecureSession {
  static const _tokenKey = 'sneakerhub.session.token';
  final FlutterSecureStorage storage;

  const SecureSession({this.storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  )});

  Future<String?> readToken() async {
    try {
      return await storage.read(key: _tokenKey);
    } catch (error) {
      // Browsers without secure storage still allow a fresh login.
      debugPrint('Secure session restore unavailable: $error');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await storage.write(key: _tokenKey, value: token);
    } catch (error) {
      debugPrint('Secure session save unavailable: $error');
    }
  }

  Future<void> clearToken() async {
    try {
      await storage.delete(key: _tokenKey);
    } catch (error) {
      debugPrint('Secure session clear unavailable: $error');
    }
  }
}
