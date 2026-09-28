import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/phone_auth_web_errors.dart';

void main() {
  test('maps hostname match errors to tenant web setup guidance', () {
    final String message = PhoneAuthWebErrors.formatMessage('Hostname match not found');
    expect(message, contains('Authorized domains'));
    expect(message, contains('HTTP referrers'));
    expect(message, contains('tenant'));
  });

  test('maps invalid-app-credential to tenant web setup guidance', () {
    final String message = PhoneAuthWebErrors.formatFirebaseAuthException(
      FirebaseAuthException(code: 'invalid-app-credential', message: 'bad'),
    );
    expect(message, contains('organisation'));
    expect(message, contains('Authorized domains'));
  });
}
