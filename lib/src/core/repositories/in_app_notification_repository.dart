import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/in_app_notification_model.dart';

/// مستودع إدارة وتخزين الإشعارات والتنبيهات محلياً في SQLite
class InAppNotificationRepository {
  final AppDatabase _appDb = AppDatabase.instance;
  static bool _tableChecked = false;

  Future<Database> _getDb() async {
    final db = await _appDb.database;
    if (!_tableChecked) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS in_app_notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0
        )
      ''');
      _tableChecked = true;
    }
    return db;
  }

  /// جلب كافة الإشعارات المحفوظة مرتبة من الأحدث إلى الأقدم
  Future<List<InAppNotificationModel>> getAll() async {
    final db = await _getDb();
    final maps = await db.query(
      'in_app_notifications',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => InAppNotificationModel.fromMap(m)).toList();
  }

  /// حساب عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount() async {
    final db = await _getDb();
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM in_app_notifications WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// إضافة إشعار جديد إلى السجل
  Future<int> insert(InAppNotificationModel notification) async {
    final db = await _getDb();
    return await db.insert('in_app_notifications', notification.toMap());
  }

  /// تمييز إشعار محدد كمقروء
  Future<void> markAsRead(int id) async {
    final db = await _getDb();
    await db.update(
      'in_app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// تمييز كافة الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final db = await _getDb();
    await db.update('in_app_notifications', {'is_read': 1});
  }

  /// حذف إشعار محدد
  Future<void> delete(int id) async {
    final db = await _getDb();
    await db.delete('in_app_notifications', where: 'id = ?', whereArgs: [id]);
  }

  /// مسح سجل الإشعارات بالكامل
  Future<void> deleteAll() async {
    final db = await _getDb();
    await db.delete('in_app_notifications');
  }
}
