import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/envelope_model.dart';

class EnvelopeRepository {
  final AppDatabase _dbProvider;

  EnvelopeRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// جلب جميع الأظرف مع احتساب المبالغ المصروفة فعلياً لكل ظرف عبر JOIN
  Future<List<EnvelopeModel>> getAll() async {
    final db = await _db;
    final query = '''
      SELECT 
        e.id, e.name, e.allocated_amount, e.icon, e.color,
        COALESCE(SUM(t.amount), 0.0) as spent
      FROM envelopes e
      LEFT JOIN transactions t ON t.envelope_id = e.id AND t.type = 'expense'
      GROUP BY e.id, e.name, e.allocated_amount, e.icon, e.color
      ORDER BY e.name ASC
    ''';

    final result = await db.rawQuery(query);
    return result.map((map) {
      final spent = (map['spent'] as num?)?.toDouble() ?? 0.0;
      return EnvelopeModel.fromMap(map, spent: spent);
    }).toList();
  }

  /// جلب ظرف بالـ ID
  Future<EnvelopeModel?> getById(int id) async {
    final db = await _db;
    final query = '''
      SELECT 
        e.id, e.name, e.allocated_amount, e.icon, e.color,
        COALESCE(SUM(t.amount), 0.0) as spent
      FROM envelopes e
      LEFT JOIN transactions t ON t.envelope_id = e.id AND t.type = 'expense'
      WHERE e.id = ?
      GROUP BY e.id, e.name, e.allocated_amount, e.icon, e.color
    ''';

    final result = await db.rawQuery(query, [id]);
    if (result.isEmpty) return null;
    final map = result.first;
    final spent = (map['spent'] as num?)?.toDouble() ?? 0.0;
    return EnvelopeModel.fromMap(map, spent: spent);
  }

  /// إضافة ظرف جديد
  Future<int> insert(EnvelopeModel envelope) async {
    final db = await _db;
    return await db.insert('envelopes', envelope.toMap());
  }

  /// تعديل ظرف
  Future<int> update(EnvelopeModel envelope) async {
    if (envelope.id == null) return 0;
    final db = await _db;
    return await db.update(
      'envelopes',
      envelope.toMap(),
      where: 'id = ?',
      whereArgs: [envelope.id],
    );
  }

  /// حذف ظرف
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'envelopes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
