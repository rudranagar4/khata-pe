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

  /// Trigger biometric or system PIN authentication
  static Future<bool> authenticate({String reason = 'Authenticate to access Khata Pe'}) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return true; // If device does not support it, allow through

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException {
      return false;
    }
  }
}

