import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._();
  factory CryptoService() => _instance;
  CryptoService._();

  final _storage = const FlutterSecureStorage();
  Uint8List? _cachedKey;

  static const _keyStorageKey = 'crypto_master_key';

                                                  
                                      
                                           
  static const _keyFallbackStorageKey = 'crypto_master_key_backup';

  Future<Uint8List> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? stored;

                                  
    try {
      stored = await _storage.read(key: _keyStorageKey);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 安全存储读取失败，尝试备用密钥: $e');
    }

                                       
    if (stored == null || stored.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        stored = prefs.getString(_keyFallbackStorageKey);
      } catch (_) {}
    }

    if (stored != null && stored.isNotEmpty) {
      try {
        final key = base64Decode(stored);
        if (key.length == 32) {
          _cachedKey = key;
                                    
          await _tryWriteToSecureStorage(key);
                      
                                       
          await _tryWriteBackupKey(key);
          return key;
        }
      } catch (_) {
                            
      }
    }

    final random = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }

    await _tryWriteToSecureStorage(key);
    await _tryWriteBackupKey(key);
    _cachedKey = key;
    return key;
  }

  Future<void> _tryWriteBackupKey(Uint8List key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFallbackStorageKey, base64Encode(key));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 备用密钥写入失败: $e');
    }
  }

  Future<void> _tryWriteToSecureStorage(Uint8List key) async {
    try {
      await _storage.write(key: _keyStorageKey, value: base64Encode(key));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 安全存储写入失败: $e');
    }
  }

  Future<Uint8List> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    return _getOrCreateKey();
  }

                      
                                    
                                                               
                                                
                                           
  int _readNonce(Uint8List bytes, int offset) {
    int nonce = 0;
    for (int i = 7; i >= 0; i--) {
      nonce = (nonce << 8) | (bytes[offset + i] & 0xFF);
    }
    return nonce;
  }

  void _writeNonce(Uint8List bytes, int offset, int nonce) {
    for (int i = 0; i < 8; i++) {
      bytes[offset + i] = (nonce >> (8 * i)) & 0xFF;
    }
  }

  Uint8List _deriveKeyStream(Uint8List key, int nonce, int length) {
                                                    
                                                     
                                            
                         
    final output = Uint8List(length);

                                     
    final prefixStr = '$nonce:';
    final prefixLen = prefixStr.length;
    final prefix = Uint8List(prefixLen);
    for (int i = 0; i < prefixLen; i++) {
      prefix[i] = prefixStr.codeUnitAt(i);
    }

                                 
    final input = Uint8List(prefixLen + 10);
    input.setRange(0, prefixLen, prefix);

    final hmac = Hmac(sha256, key);
    int offset = 0;
    int counter = 0;
    while (offset < length) {
                                             
      final len = _writeDecimalAscii(input, prefixLen, counter);
      final digest = hmac.convert(Uint8List.sublistView(input, 0, prefixLen + len));
      final bytes = digest.bytes;
      final remaining = length - offset;
      final copyLen = remaining < bytes.length ? remaining : bytes.length;
      output.setRange(offset, offset + copyLen, bytes);
      offset += copyLen;
      counter++;
    }
    return output;
  }

                                                         
  int _writeDecimalAscii(Uint8List buf, int start, int value) {
    if (value == 0) {
      buf[start] = 0x30;
      return 1;
    }
    var v = value;
    int len = 0;
    while (v > 0) {
      len++;
      v ~/= 10;
    }
    v = value;
    for (int i = len - 1; i >= 0; i--) {
      buf[start + i] = 0x30 + (v % 10);
      v ~/= 10;
    }
    return len;
  }

  Future<String> encrypt(String plaintext) async {
    final key = await _getKey();
    final plainBytes = utf8.encode(plaintext);
    final nonce = DateTime.now().microsecondsSinceEpoch;

    final keyStream = _deriveKeyStream(key, nonce, plainBytes.length);
    final output = Uint8List(8 + plainBytes.length);
    _writeNonce(output, 0, nonce);

    for (int i = 0; i < plainBytes.length; i++) {
      output[i + 8] = plainBytes[i] ^ keyStream[i];
    }

    return base64Encode(output);
  }

  Future<String> decrypt(String cipherBase64) async {
    final key = await _getKey();
    final allBytes = base64Decode(cipherBase64);
    if (allBytes.length < 9) {
      throw const FormatException('密文过短，无法解密');
    }
    final nonce = _readNonce(allBytes, 0);
    final cipherBytes = allBytes.sublist(8);

    final keyStream = _deriveKeyStream(key, nonce, cipherBytes.length);
    final plainBytes = Uint8List(cipherBytes.length);
    for (int i = 0; i < cipherBytes.length; i++) {
      plainBytes[i] = cipherBytes[i] ^ keyStream[i];
    }

    return utf8.decode(plainBytes);
  }

  Future<bool> isEncrypted(String value) async {
    try {
      final bytes = base64Decode(value);
      return bytes.length > 4;
    } catch (_) {
      return false;
    }
  }

  void clearCachedKey() {
    _cachedKey = null;
  }
}
