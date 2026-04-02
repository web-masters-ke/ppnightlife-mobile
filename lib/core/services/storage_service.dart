import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Tokens (secure)
  Future<void> saveAccessToken(String token) => _secure.write(key: 'access_token', value: token);
  Future<void> saveRefreshToken(String token) => _secure.write(key: 'refresh_token', value: token);
  Future<String?> getAccessToken() => _secure.read(key: 'access_token');
  Future<String?> getRefreshToken() => _secure.read(key: 'refresh_token');
  Future<void> clearTokens() async {
    await _secure.delete(key: 'access_token');
    await _secure.delete(key: 'refresh_token');
  }

  // User data (SharedPreferences)
  Future<void> saveUserId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_id', id);
  }
  Future<void> saveUserRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_role', role);
  }
  Future<void> saveUserName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_name', name);
  }
  Future<String?> getUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_id');
  }
  Future<String?> getUserRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_role');
  }
  Future<String?> getUserName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_name');
  }
  Future<void> clearUserData() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('user_id');
    await p.remove('user_role');
    await p.remove('user_name');
  }
  Future<void> clearAll() async {
    await clearTokens();
    await clearUserData();
  }
}
