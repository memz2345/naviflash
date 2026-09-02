// lib/services/playlist_cipher.dart
//
// 播放列表云端加密：口令派生密钥 + AES-256-GCM。
// - 密钥由用户口令经 PBKDF2(HMAC-SHA256, 100k 迭代) 派生，
//   多设备填入相同口令即可互相解密；
// - 每份密文带随机 salt + 随机 nonce，格式：
//   NAVPL1.<base64 salt>.<base64 nonce>.<base64 ciphertext+tag>
// - 纯 Dart 实现（package:cryptography），Android / Windows 通用。
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import '../l10n/l10n_helper.dart';

class PlaylistCipher {
  PlaylistCipher._();

  static const String magic = 'NAVPL1';

  /// 是否为加密数据（旧版明文 JSON 直接以 '{' 开头，无需迁移）。
  static bool isEncrypted(String text) => text.startsWith('$magic.');

  /// 加密：口令派生密钥后 AES-256-GCM 加密。
  static Future<String> encrypt(String plaintext, String passphrase) async {
    if (passphrase.isEmpty) {
      throw ArgumentError(L10n.current.syncPassphraseEmpty);
    }
    final random = Random.secure();
    final salt = Uint8List.fromList(
        List.generate(16, (_) => random.nextInt(256)));
    final nonce = Uint8List.fromList(
        List.generate(12, (_) => random.nextInt(256)));

    final key = await _deriveKey(passphrase, salt);
    final box = await AesGcm.with256bits()
        .encrypt(utf8.encode(plaintext), secretKey: key, nonce: nonce);

    final cipherText = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    return '$magic.${base64Encode(salt)}.${base64Encode(nonce)}.'
        '${base64Encode(cipherText)}';
  }

  /// 解密；口令错误或数据损坏时抛出异常。
  static Future<String> decrypt(String payload, String passphrase) async {
    final parts = payload.split('.');
    if (parts.length != 4 || parts[0] != magic) {
      throw const FormatException('同步数据格式无效');
    }
    final salt = base64Decode(parts[1]);
    final nonce = base64Decode(parts[2]);
    final full = base64Decode(parts[3]);
    if (salt.length != 16 || nonce.length != 12 || full.length < 17) {
      throw const FormatException('同步数据损坏');
    }

    final key = await _deriveKey(passphrase, salt);
    final box = SecretBox(
      full.sublist(0, full.length - 16),
      nonce: nonce,
      mac: Mac(full.sublist(full.length - 16)),
    );
    final clear = await AesGcm.with256bits().decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }

  /// PBKDF2 派生 256 位密钥。
  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }
}
