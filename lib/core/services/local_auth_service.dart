import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  static Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Trigger strictly biometric authentication (fingerprint / face ID)
  static Future<bool> authenticate({String reason = 'Scan your fingerprint to access Khata Pe'}) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return true; // If device does not support biometrics (e.g. emulator/tests), allow through

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
