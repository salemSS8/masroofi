import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionRepository {
  final AppDatabase _dbProvider;

  RecurringTransactionRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// جلب جميع المعاملات المتكررة
  Future<List<RecurringTransactionModel>> getAll() async {
    final db = await _db;
    final maps = await db.query('recurring_transactions', orderBy: 'id DESC');
    return maps.map((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  /// جلب المعاملات المتكررة النشطة فقط
  Future<List<RecurringTransactionModel>> getActive() async {
    final db = await _db;
    final maps = await db.query(
      'recurring_transactions',
      where: 'is_active = 1',
      orderBy: 'next_run_date ASC',
    );
    return maps.map((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  /// جلب المعاملات المستحقة التنفيذ حالياً (تاريخها يسبق أو يوافق الآن)
  Future<List<RecurringTransactionModel>> getDueTransactions() async {
    final db = await _db;
    final nowIso = DateTime.now().toIso8601String();
    final maps = await db.query(
      'recurring_transactions',
      where: 'is_active = 1 AND next_run_date <= ?',
      whereArgs: [nowIso],
    );
    return maps.map((map) => RecurringTransactionModel.fromMap(map)).toList();
  }

  /// إضافة معاملة متكررة
  Future<int> insert(RecurringTransactionModel model) async {
    final db = await _db;
    return await db.insert('recurring_transactions', model.toMap());
  }

  /// تعديل معاملة متكررة
  Future<int> update(RecurringTransactionModel model) async {
    if (model.id == null) return 0;
    final db = await _db;
    return await db.update(
      'recurring_transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  /// تحديث تاريخ التنفيذ القادم بعد تطبيق المعاملة
  Future<int> advanceNextRunDate(int id, DateTime nextDate) async {
    final db = await _db;
    return await db.update(
      'recurring_transactions',
      {'next_run_date': nextDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حذف معاملة متكررة
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
