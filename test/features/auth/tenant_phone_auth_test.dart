import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/core/firebase/phone_auth_challenge.dart';
import 'package:hackz/core/firebase/tenant_connection_exception.dart';
import 'package:hackz/core/firebase/tenant_firebase.dart';
import 'package:hackz/features/auth/services/auth_utils.dart';

void main() {
  tearDown(PhoneAuthChallenge.clear);

  test('pending OTP state is dropped when switching tenants or signing out', () {
    PhoneAuthChallenge.verificationId = 'tenant-a-verification';
    PhoneAuthChallenge.clear();
    expect(PhoneAuthChallenge.verificationId, isNull);
    expect(PhoneAuthChallenge.webConfirmation, isNull);
  });

  test('organisation OTP is refused until a tenant is resolved', () async {
    HackzFirebase.endPlatformAdminSession();
    expect(HackzFirebase.isPlatformAdminSession, isFalse);
    expect(HackzFirebase.isTenantBound, isFalse);
    await expectLater(
      AuthUtils.sendOtp(phone: '+911234567890', onCodeSent: () {}),
      throwsA(isA<StateError>()),
    );
  });

  test('invalid organisation codes never initialize tenant Auth', () async {
    await expectLater(
      TenantFirebase.connect('not-a-code'),
      throwsA(
        isA<TenantConnectionException>().having(
          (TenantConnectionException e) => e.failure,
          'failure',
          TenantConnectionFailure.invalidCode,
        ),
      ),
    );
    expect(HackzFirebase.isTenantBound, isFalse);
  });
}
