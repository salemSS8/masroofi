import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final AppDatabase _dbProvider;

  CategoryRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  /// جلب جميع التصنيفات مع إمكانية التصفية (دخل أو مصروف)
  Future<List<CategoryModel>> getAll({bool? isIncome}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps;

    if (isIncome != null) {
      maps = await db.query(
        'categories',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('categories', orderBy: 'is_income DESC, name ASC');
    }

    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  /// جلب تصنيف بواسطة الـ ID
  Future<CategoryModel?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  /// إضافة تصنيف جديد
  Future<int> insert(CategoryModel category) async {
    final db = await _db;
    return await db.insert('categories', category.toMap());
  }

  /// تعديل تصنيف موجود
  Future<int> update(CategoryModel category) async {
    if (category.id == null) return 0;
    final db = await _db;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// حذف تصنيف
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
