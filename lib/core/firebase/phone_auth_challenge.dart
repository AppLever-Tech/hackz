import 'package:firebase_auth/firebase_auth.dart';

/// In-flight phone OTP challenge for the active Auth instance.
///
/// Must be cleared when switching tenants or signing out so Tenant A
/// verification state cannot complete against Tenant B.
abstract final class PhoneAuthChallenge {
  PhoneAuthChallenge._();

  static String? verificationId;
  static ConfirmationResult? webConfirmation;

  static void clear() {
    verificationId = null;
    webConfirmation = null;
  }
}
