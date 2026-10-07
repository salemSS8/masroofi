import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final AppDatabase _dbProvider;

  TransactionRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  static const String _selectQueryWithCategory = '''
    SELECT 
      t.id, t.title, t.amount, t.type, t.category_id, t.envelope_id, 
      t.date, t.notes, t.created_at, t.is_recurring,
      c.name AS category_name, c.icon AS category_icon, c.color AS category_color
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
  ''';

  /// إضافة معاملة جديدة
  Future<int> insert(TransactionModel tx) async {
    final db = await _db;
    return await db.insert('transactions', tx.toMap());
  }

  /// تعديل معاملة موجودة
  Future<int> update(TransactionModel tx) async {
    if (tx.id == null) return 0;
    final db = await _db;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  /// حذف معاملة
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// جلب المعاملات مع تصفية ديناميكية وترتيب زمني تنازلي
  Future<List<TransactionModel>> getAll({
    DateTime? from,
    DateTime? to,
    String? type,
    int? categoryId,
    int? envelopeId,
    int? limit,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClauses.add('t.date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('t.date <= ?');
      whereArgs.add(to.toIso8601String());
    }
    if (type != null) {
      whereClauses.add('t.type = ?');
      whereArgs.add(type);
    }
    if (categoryId != null) {
      whereClauses.add('t.category_id = ?');
      whereArgs.add(categoryId);
    }
    if (envelopeId != null) {
      whereClauses.add('t.envelope_id = ?');
      whereArgs.add(envelopeId);
    }

    var query = _selectQueryWithCategory;
    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }
    query += ' ORDER BY t.date DESC, t.id DESC';
    if (limit != null) {
      query += ' LIMIT $limit';
    }

    final result = await db.rawQuery(query, whereArgs);
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// جلب أحدث المعاملات (للوحة التحكم الرئيسية)
  Future<List<TransactionModel>> getRecent({int limit = 10}) async {
    return await getAll(limit: limit);
  }

  /// حساب إجمالي الدخل لفترة معينة
  Future<double> getTotalIncome({DateTime? from, DateTime? to}) async {
    final db = await _db;
    final whereClauses = ["type = 'income'"];
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final query = '''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM transactions 
      WHERE ${whereClauses.join(' AND ')}
    ''';
    final result = await db.rawQuery(query, whereArgs);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب إجمالي المصروفات لفترة معينة
  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    final db = await _db;
    final whereClauses = ["type = 'expense'"];
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final query = '''
      SELECT COALESCE(SUM(amount), 0.0) as total 
      FROM transactions 
      WHERE ${whereClauses.join(' AND ')}
    ''';
    final result = await db.rawQuery(query, whereArgs);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب صافي الرصيد الحالي (إجمالي الدخل - إجمالي المصروفات)
  Future<double> getCurrentBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpenses();
    return income - expense;
  }

  /// تجميع المصروفات حسب التصنيف (للرسوم البيانية والتقارير)
  Future<List<Map<String, dynamic>>> getExpensesByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db;
    final whereClauses = ["t.type = 'expense'"];
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClauses.add('t.date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('t.date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final query = '''
      SELECT 
        COALESCE(c.id, 0) as category_id,
        COALESCE(c.name, 'أخرى') as category_name,
        COALESCE(c.icon, 'category') as category_icon,
        COALESCE(c.color, 4284769393) as category_color,
        SUM(t.amount) as total_amount
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY c.id, c.name, c.icon, c.color
      ORDER BY total_amount DESC
    ''';

    return await db.rawQuery(query, whereArgs);
  }

  /// حساب مجموع المبالغ المصروفة لظرف معين
  Future<double> getSpentForEnvelope(int envelopeId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as spent
      FROM transactions
      WHERE envelope_id = ? AND type = 'expense'
    ''', [envelopeId]);
    return (result.first['spent'] as num?)?.toDouble() ?? 0.0;
  }
}
