import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._();
  factory SecureStorageService() => _instance;
  SecureStorageService._();

  final _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> migrateFromPrefs(
      String oldPrefsKey, String newSecureKey) async {
    final existing = await _storage.read(key: newSecureKey);
    if (existing != null && existing.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final oldValue = prefs.getString(oldPrefsKey);
    if (oldValue != null && oldValue.isNotEmpty) {
      await _storage.write(key: newSecureKey, value: oldValue);
      await prefs.remove(oldPrefsKey);
    }
  }
}
