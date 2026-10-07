import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة التخزين المشفر والآمن لمفاتيح الأمان والرموز الحساسة
class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _pinKey = 'user_pin';
  static const _failedAttemptsKey = 'pin_failed_attempts';
  static const _lockoutUntilKey = 'pin_lockout_until';
  static const _biometricsKey = 'biometrics_enabled';

  // --- إدارة الرمز السري ---

  Future<void> savePin(String hashedPin) async {
    await _storage.write(key: _pinKey, value: hashedPin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  // --- إدارة محاولات الدخول الخاطئة والحظر الزمني ---

  Future<int> getFailedAttempts() async {
    final str = await _storage.read(key: _failedAttemptsKey);
    return str != null ? int.tryParse(str) ?? 0 : 0;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    await _storage.write(key: _failedAttemptsKey, value: (current + 1).toString());
  }

  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  Future<void> setLockoutDuration(Duration duration) async {
    final lockoutTime = DateTime.now().add(duration);
    await _storage.write(key: _lockoutUntilKey, value: lockoutTime.toIso8601String());
  }

  Future<DateTime?> getLockoutUntil() async {
    final str = await _storage.read(key: _lockoutUntilKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<bool> isLockedOut() async {
    final until = await getLockoutUntil();
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  Future<int> getLockoutRemainingSeconds() async {
    final until = await getLockoutUntil();
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  // --- تفضيلات المقاييس الحيوية (Biometrics) ---

  Future<bool> isBiometricsEnabled() async {
    final str = await _storage.read(key: _biometricsKey);
    // افتراضياً مفعلة إذا لم يقم المستخدم بتعطيلها صراحة
    return str == null || str == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsKey, value: enabled.toString());
  }

  // --- إعادة الضبط الشاملة ---

  Future<void> resetAll() async {
    await _storage.deleteAll();
  }
}
