//import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      print("Error checking biometric availability: $e");
      return false;
    }
  }

  // Authenticate using fingerprint or face recognition
  Future<bool> authenticate() async {
    try {
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep authentication session active
        ),
      );
      return isAuthenticated;
    } catch (e) {
      print("Authentication error: $e");
      return false;
    }
  }
}
