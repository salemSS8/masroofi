import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashnddof/src/core/security/encryption_service.dart';
import 'package:bashnddof/src/core/services/backup_service.dart';

void main() {
  group('EncryptionService Tests (AES-256-CBC)', () {
    const passphrase = 'MySuperSecretWalletKey123!';
    const plainText = '{"transactions":[{"id":1,"amount":250.0,"title":"بقالة"}]}';

    test('Encrypt and decrypt roundtrip succeeds', () {
      final encryptor = EncryptionService(passphrase);
      final cipherText = encryptor.encrypt(plainText);

      expect(cipherText, isNot(equals(plainText)));
      expect(cipherText.contains(':'), isTrue); // IV:ciphertext format

      final decrypted = encryptor.decrypt(cipherText);
      expect(decrypted, equals(plainText));
    });

    test('Two encryptions of the same plaintext produce different ciphertexts (random IV)', () {
      final encryptor = EncryptionService(passphrase);
      final cipher1 = encryptor.encrypt(plainText);
      final cipher2 = encryptor.encrypt(plainText);

      expect(cipher1, isNot(equals(cipher2)));

      // But both decrypt back to the original text
      expect(encryptor.decrypt(cipher1), equals(plainText));
      expect(encryptor.decrypt(cipher2), equals(plainText));
    });

    test('Decryption with wrong passphrase safely returns null via tryDecrypt', () {
      final encryptor = EncryptionService(passphrase);
      final cipherText = encryptor.encrypt(plainText);

      final wrongEncryptor = EncryptionService('WrongPassword123');
      final result = wrongEncryptor.tryDecrypt(cipherText);

      expect(result, isNull);
    });

    test('Corrupted or malformed ciphertext safely returns null via tryDecrypt', () {
      final encryptor = EncryptionService(passphrase);
      expect(encryptor.tryDecrypt('invalid_payload_without_colon'), isNull);
      expect(encryptor.tryDecrypt('abc:not_valid_base64_ciphertext!@#'), isNull);
    });
  });

  group('BackupService Validation Tests', () {
    test('Restoring with wrong passphrase fails safely without crash', () async {
      final encryptor = EncryptionService('CorrectPassword');
      final validPayload = jsonEncode({
        'app': 'BASHNDDOF',
        'schema_version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'tables': {
          'categories': [],
          'envelopes': [],
          'transactions': [],
          'savings_goals': [],
          'recurring_transactions': [],
        },
      });

      final encrypted = encryptor.encrypt(validPayload);

      final backupService = BackupService();
      final result = await backupService.restoreEncryptedBackup(
        encryptedPayload: encrypted,
        passphrase: 'WrongPassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message.contains('كلمة السر غير صحيحة'), isTrue);
    });

    test('Restoring malformed JSON schema fails safely', () async {
      final encryptor = EncryptionService('Pass123');
      // Payload missing 'tables' or wrong app
      final invalidPayload = jsonEncode({
        'app': 'OTHER_APP',
        'schema_version': 1,
      });

      final encrypted = encryptor.encrypt(invalidPayload);

      final backupService = BackupService();
      final result = await backupService.restoreEncryptedBackup(
        encryptedPayload: encrypted,
        passphrase: 'Pass123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message.contains('نسخة احتياطية صالحة'), isTrue);
    });
  });
}
