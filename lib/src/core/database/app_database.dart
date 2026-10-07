import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// النواة المركزية الموحدة لقاعدة بيانات تطبيق BASHNDDOF (SQLite)
class AppDatabase {
  static const String _databaseName = 'bashnddof.db';
  static const int _databaseVersion = 2;

  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // تفعيل المفاتيح الأجنبية (Foreign Keys)
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول التصنيفات (Categories)
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_income INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. جدول الأظرف والميزانيات (Envelopes)
    await db.execute('''
      CREATE TABLE envelopes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        allocated_amount REAL NOT NULL,
        icon TEXT,
        color INTEGER
      )
    ''');

    // 3. جدول المعاملات المالية (Transactions)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        envelope_id INTEGER,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (envelope_id) REFERENCES envelopes (id) ON DELETE SET NULL
      )
    ''');

    // 4. جدول أهداف الادخار (Savings Goals)
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date TEXT,
        icon TEXT,
        color INTEGER
      )
    ''');

    // 5. جدول المعاملات الدورية المتكررة (Recurring Transactions)
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        frequency TEXT NOT NULL,
        day_of_month INTEGER,
        next_run_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // بذر البيانات الافتراضية الأولية (Default Seeds)
    await _seedDefaultCategories(db);
  }

  /// بذر التصنيفات الافتراضية الشائعة للمصروفات والدخل
  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      // تصنيفات الدخل (is_income = 1)
      {'name': 'الراتب', 'icon': 'payments', 'color': 0xFF10B981, 'is_income': 1},
      {'name': 'عمل حر', 'icon': 'laptop_mac', 'color': 0xFF059669, 'is_income': 1},
      {'name': 'استثمارات', 'icon': 'trending_up', 'color': 0xFF047857, 'is_income': 1},
      {'name': 'أخرى (دخل)', 'icon': 'savings', 'color': 0xFF34D399, 'is_income': 1},

      // تصنيفات المصروفات (is_income = 0)
      {'name': 'طعام ومشروبات', 'icon': 'restaurant', 'color': 0xFFEF4444, 'is_income': 0},
      {'name': 'سكن وإيجار', 'icon': 'home', 'color': 0xFFF59E0B, 'is_income': 0},
      {'name': 'فواتير وخدمات', 'icon': 'receipt_long', 'color': 0xFF6366F1, 'is_income': 0},
      {'name': 'مواصلات ووقود', 'icon': 'directions_car', 'color': 0xFF3B82F6, 'is_income': 0},
      {'name': 'تسوق ومشتريات', 'icon': 'shopping_bag', 'color': 0xFFEC4899, 'is_income': 0},
      {'name': 'صحة وأدوية', 'icon': 'medical_services', 'color': 0xFF14B8A6, 'is_income': 0},
      {'name': 'ترفيه وسياحة', 'icon': 'movie', 'color': 0xFF8B5CF6, 'is_income': 0},
      {'name': 'تعليم وتطوير', 'icon': 'school', 'color': 0xFF0EA5E9, 'is_income': 0},
      {'name': 'أخرى (مصروف)', 'icon': 'category', 'color': 0xFF64748B, 'is_income': 0},
    ];

    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert('categories', cat);
    }
    await batch.commit(noResult: true);
  }

  /// إغلاق اتصال قاعدة البيانات
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// حذف قاعدة البيانات بالكامل (عند إعادة الضبط الشاملة من الإعدادات)
  Future<void> resetDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await deleteDatabase(path);
  }
}
