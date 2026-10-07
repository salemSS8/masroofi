import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// خدمة التشفير المتقدمة (AES-256-CBC) لتأمين النسخ الاحتياطي والبيانات الحساسة
class EncryptionService {
  final Key _key;

  EncryptionService(String passphrase)
      : _key = Key(Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes));

  /// تشفير النص مع توليد IV عشوائي وإلحاقه مع الناتج
  String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// فك تشفير النص المشفر باستخدام الـ IV الملحق
  String decrypt(String cipherPayload) {
    final parts = cipherPayload.split(':');
    if (parts.length != 2) {
      throw const FormatException('صيغة البيانات المشفرة غير صالحة');
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// محاولة فك التشفير مع إرجاع null عند الخطأ أو عدم تطابق كلمة المرور
  String? tryDecrypt(String cipherPayload) {
    try {
      return decrypt(cipherPayload);
    } catch (_) {
      return null;
    }
  }
}
