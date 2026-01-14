import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageService {
  final _storage = const FlutterSecureStorage();
  
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  Future<void> saveSession({
    required String token, 
    String? userId,
    String? userName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId);
    if (userName != null) await _storage.write(key: _userNameKey, value: userName);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
  
  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
