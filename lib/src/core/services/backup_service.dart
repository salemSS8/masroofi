import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../security/encryption_service.dart';

/// نتيجة عملية استعادة النسخة الاحتياطية
class BackupRestoreResult {
  final bool isSuccess;
  final String message;
  final int transactionsCount;
  final int categoriesCount;
  final int envelopesCount;
  final int savingsCount;

  const BackupRestoreResult({
    required this.isSuccess,
    required this.message,
    this.transactionsCount = 0,
    this.categoriesCount = 0,
    this.envelopesCount = 0,
    this.savingsCount = 0,
  });
}

/// خدمة النسخ الاحتياطي المشفر والاستعادة الآمنة لقاعدة بيانات BASHNDDOF
class BackupService {
  final AppDatabase _dbProvider;

  BackupService({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// تصدير كامل قاعدة البيانات كملف نصي مشفر بكلمة سر المستخدم (AES-256)
  Future<String> exportEncryptedBackup(String passphrase) async {
    final db = await _db;

    final transactions = await db.query('transactions');
    final categories = await db.query('categories');
    final envelopes = await db.query('envelopes');
    final savingsGoals = await db.query('savings_goals');
    final recurringTransactions = await db.query('recurring_transactions');

    final backupPayload = {
      'app': 'MASROUFI',
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': {
        'categories': categories,
        'envelopes': envelopes,
        'transactions': transactions,
        'savings_goals': savingsGoals,
        'recurring_transactions': recurringTransactions,
      },
    };

    final jsonString = jsonEncode(backupPayload);
    final encryptor = EncryptionService(passphrase);
    return encryptor.encrypt(jsonString);
  }

  /// استعادة البيانات من النص المشفر بعد التحقق من كلمة السر وصحة الهيكل
  Future<BackupRestoreResult> restoreEncryptedBackup({
    required String encryptedPayload,
    required String passphrase,
  }) async {
    final encryptor = EncryptionService(passphrase);
    final decryptedJson = encryptor.tryDecrypt(encryptedPayload);

    if (decryptedJson == null) {
      return const BackupRestoreResult(
        isSuccess: false,
        message: 'كلمة السر غير صحيحة أو أن ملف النسخة الاحتياطية تالف.',
      );
    }

    try {
      final Map<String, dynamic> data = jsonDecode(decryptedJson);

      final appName = data['app'] as String?;
      if ((appName != 'MASROUFI' && appName != 'BASHNDDOF' && appName != 'مصروفي') || !data.containsKey('tables')) {
        return const BackupRestoreResult(
          isSuccess: false,
          message: 'الملف ليس نسخة احتياطية صالحة لتطبيق مصروفي.',
        );
      }

      final tables = data['tables'] as Map<String, dynamic>;
      final categories = (tables['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final envelopes = (tables['envelopes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final transactions = (tables['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final savings = (tables['savings_goals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final recurring = (tables['recurring_transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final db = await _db;

      // تطبيق الاستعادة داخل معاملة واحدة متكاملة (Transaction) لضمان عدم تلف البيانات
      await db.transaction((txn) async {
        // تفريغ الجداول القديمة
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('envelopes');
        await txn.delete('savings_goals');
        await txn.delete('recurring_transactions');

        // إدراج التصنيفات المستعادة
        for (final cat in categories) {
          await txn.insert('categories', cat);
        }

        // إدراج الأظرف المستعادة
        for (final env in envelopes) {
          await txn.insert('envelopes', env);
        }

        // إدراج المعاملات المستعادة
        for (final tx in transactions) {
          await txn.insert('transactions', tx);
        }

        // إدراج أهداف الادخار
        for (final s in savings) {
          await txn.insert('savings_goals', s);
        }

        // إدراج المعاملات الدورية
        for (final r in recurring) {
          await txn.insert('recurring_transactions', r);
        }
      });

      return BackupRestoreResult(
        isSuccess: true,
        message: 'تمت استعادة البيانات بنجاح!',
        transactionsCount: transactions.length,
        categoriesCount: categories.length,
        envelopesCount: envelopes.length,
        savingsCount: savings.length,
      );
    } catch (e) {
      return BackupRestoreResult(
        isSuccess: false,
        message: 'حدث خطأ أثناء قراءة البيانات المستعادة: $e',
      );
    }
  }
}
