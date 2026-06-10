import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../user/models/enums/user_role.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../user/models/enums/user_status.dart';
import '../../organization/models/department_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';

class AuthUtils {
  AuthUtils._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _verificationId;
  static ConfirmationResult? _webConfirmationResult;

  static Future<UserModel?> checkUserExists(String phone) {
    return FirestoreUtils.fetchUserByPhone(normalizePhoneE164(phone));
  }

  static Future<Map<String, dynamic>?> checkWhitelist(String phone) {
    return FirestoreUtils.fetchWhitelistEntry(normalizePhoneE164(phone));
  }

  static Future<void> ensureSysAdminUserFromWhitelist({
    required String firebaseAuthUid,
    required String phone,
    required Map<String, dynamic> whitelist,
  }) async {
    final uid = firebaseAuthUid.trim();
    if (uid.isEmpty) return;

    final user = UserModel(
      userId: uid,
      phone: phone,
      firstName: (whitelist['firstName'] as String?) ?? '',
      lastName: (whitelist['lastName'] as String?) ?? '',
      email: (whitelist['email'] as String?) ?? '',
      role: UserRole.sysAdmin.code,
      orgType: OrganizationType.fromFirestoreValue(whitelist['orgType']),
      orgId: '',
      department: '',
      departmentCode: DepartmentModel.resolveCode(''),
      status: UserStatus.active,
      createdAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );
    await FirestoreUtils.ensureWhitelistedSysAdminProfile(
      firebaseAuthUid: uid,
      profile: user,
    );
  }

  static Future<void> sendOtp({
    required String phone,
    required VoidCallback onCodeSent,
  }) async {
    if (kIsWeb) {
      _webConfirmationResult = await _auth.signInWithPhoneNumber(phone);
      onCodeSent();
      return;
    }

    final sent = Completer<void>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (!sent.isCompleted) {
              sent.complete();
            }
          } catch (e, st) {
            if (!sent.isCompleted) {
              sent.completeError(e, st);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!sent.isCompleted) {
            sent.completeError(
              FirebaseAuthException(code: e.code, message: e.message),
            );
          }
        },
        codeSent: (String verificationId, int? _) {
          _verificationId = verificationId;
          onCodeSent();
          if (!sent.isCompleted) {
            sent.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e, st) {
      if (!sent.isCompleted) {
        sent.completeError(e, st);
      }
    }

    await sent.future;
  }

  static Future<UserCredential> verifyOtp(String otpCode) async {
    if (kIsWeb) {
      final result = _webConfirmationResult;
      if (result == null) {
        throw StateError('OTP was not requested yet.');
      }
      return result.confirm(otpCode);
    }

    if (_verificationId == null) {
      throw StateError('Verification ID is missing. Request OTP first.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otpCode,
    );
    return _auth.signInWithCredential(credential);
  }
}
