import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

/// خدمة إدارة التكامل والتواصل المحلي الآمن بين (مصروفي) و (وصاة)
class WasaatIntegrationService {
  static final WasaatIntegrationService _instance = WasaatIntegrationService._internal();
  factory WasaatIntegrationService() => _instance;
  WasaatIntegrationService._internal();

  static const String providerAuthority = 'com.example.bashnddof.provider';
  static const String permissionName = 'com.example.bashnddof.permission.INTEGRATION';

  static const String _prefEnabledKey = 'wasaat_integration_enabled';
  static const String _prefTokenKey = 'wasaat_integration_token';

  /// فحص هل الربط مع تطبيق وصاة مفعّل
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabledKey) ?? true;
  }

  /// تفعيل أو تعطيل الربط
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, enabled);
  }

  /// جلب رمز الأمان المشفر المخصص للتكامل
  Future<String> getSecurityToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(_prefTokenKey);
    if (token == null || token.isEmpty) {
      token = _generateSecureToken();
      await prefs.setString(_prefTokenKey, token);
    }
    return token;
  }

  /// إعادة توليد رمز أمان جديد
  Future<String> regenerateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final newToken = _generateSecureToken();
    await prefs.setString(_prefTokenKey, newToken);
    return newToken;
  }

  /// جلب جميع المعاملات التي تم اعتمادها وخصمها عبر تطبيق وصاة
  Future<List<TransactionModel>> getWasaatTransactions() async {
    try {
      final repo = TransactionRepository();
      final all = await repo.getAll();
      return all.where((t) => t.notes?.contains('وصاة') == true).toList();
    } catch (_) {
      return [];
    }
  }

  String _generateSecureToken() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
