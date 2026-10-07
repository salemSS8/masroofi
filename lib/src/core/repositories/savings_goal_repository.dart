import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepository {
  final AppDatabase _dbProvider;

  SavingsGoalRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// جلب جميع أهداف الادخار
  Future<List<SavingsGoalModel>> getAll() async {
    final db = await _db;
    final maps = await db.query('savings_goals', orderBy: 'id DESC');
    return maps.map((map) => SavingsGoalModel.fromMap(map)).toList();
  }

  /// جلب هدف بالـ ID
  Future<SavingsGoalModel?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SavingsGoalModel.fromMap(maps.first);
  }

  /// إضافة هدف ادخار جديد
  Future<int> insert(SavingsGoalModel goal) async {
    final db = await _db;
    return await db.insert('savings_goals', goal.toMap());
  }

  /// تعديل هدف ادخار
  Future<int> update(SavingsGoalModel goal) async {
    if (goal.id == null) return 0;
    final db = await _db;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  /// إضافة مساهمة مالية للهدف (زيادة المبلغ الحالي المدخر)
  Future<int> addContribution(int goalId, double amount) async {
    final db = await _db;
    return await db.rawUpdate('''
      UPDATE savings_goals 
      SET current_amount = current_amount + ?
      WHERE id = ?
    ''', [amount, goalId]);
  }

  /// حذف هدف ادخار
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
