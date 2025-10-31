import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error_codes;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthResult {
  final bool isSuccess;
  final String? message;

  const BiometricAuthResult._(this.isSuccess, this.message);

  const BiometricAuthResult.success() : this._(true, null);

  const BiometricAuthResult.failure(String message) : this._(false, message);
}

class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _refreshTokenKey = 'SECURE_REFRESH_TOKEN';

  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<BiometricAuthResult> authenticate({
    String reason = 'تأكيد الهوية بالبصمة',
  }) async {
    try {
      if (!await isDeviceSupported()) {
        return const BiometricAuthResult.failure(
          'جهازك لا يدعم تسجيل الدخول بالبصمة.',
        );
      }

      if (!await canCheckBiometrics()) {
        final available = await getAvailableBiometrics();
        if (available.isEmpty) {
          return const BiometricAuthResult.failure(
            'قم بإعداد بصمة الإصبع أو التعرف على الوجه في إعدادات الجهاز أولاً.',
          );
        }
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuth
          ? const BiometricAuthResult.success()
          : const BiometricAuthResult.failure('لم يتم تأكيد الهوية.');
    } on PlatformException catch (e) {
      return BiometricAuthResult.failure(_mapPlatformException(e));
    }
  }

  Future<void> saveRefreshTokenSecurely(String refreshToken) async {
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getSecureRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearSecureRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  String _mapPlatformException(PlatformException exception) {
    switch (exception.code) {
      case auth_error_codes.notAvailable:
        return 'ميزة البصمة غير متوفرة على هذا الجهاز.';
      case auth_error_codes.notEnrolled:
        return 'لم يتم تسجيل أي بصمة. يرجى إضافة بصمة في إعدادات الجهاز.';
      case auth_error_codes.lockedOut:
      case auth_error_codes.permanentlyLockedOut:
        return 'تجاوزت عدد المحاولات المسموح بها. استخدم كلمة المرور أو افتح قفل الجهاز أولاً.';
      default:
        return exception.message ?? 'فشل التحقق بالبصمة.';
    }
  }
}
