import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../user/models/enums/user_role.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../user/models/enums/user_status.dart';
import '../../organization/models/department_model.dart';
import '../../user/models/user_model.dart';
import '../../app_metadata/services/app_metadata_service.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/core/firebase/phone_auth_challenge.dart';

class AuthUtils {
  AuthUtils._();

  /// Organisation users: [HackzFirebase.current.auth] after tenant resolution.
  /// SysAdmin: Control Plane Auth. Never [FirebaseAuth.instance].
  static FirebaseAuth get _auth {
    if (HackzFirebase.isPlatformAdminSession) {
      return HackzFirebase.controlPlane.auth;
    }
    return HackzFirebase.current.auth;
  }

  static Future<UserModel?> checkUserExists(String phone) {
    return FirestoreUtils.fetchUserByPhone(normalizePhoneE164(phone));
  }

  static Future<Map<String, dynamic>?> checkWhitelist(String phone) {
    return FirestoreUtils.fetchWhitelistEntry(normalizePhoneE164(phone));
  }

  static Future<Map<String, dynamic>?> checkControlPlaneWhitelist(String phone) {
    return FirestoreUtils.fetchWhitelistEntry(
      normalizePhoneE164(phone),
      database: HackzFirebase.controlPlane.firestore,
    );
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
      database: HackzFirebase.isPlatformAdminSession
          ? HackzFirebase.controlPlane.firestore
          : null,
    );
    // First SysAdmin bootstrap: copy bundled App Metadata defaults into Firestore.
    await AppMetadataService.ensureSeeded();
  }

  static Future<void> sendOtp({
    required String phone,
    required VoidCallback onCodeSent,
  }) async {
    if (!HackzFirebase.isPlatformAdminSession && !HackzFirebase.isTenantBound) {
      throw StateError('Organisation sign-in requires a resolved tenant Firebase.');
    }

    PhoneAuthChallenge.clear();

    if (kIsWeb) {
      PhoneAuthChallenge.webConfirmation = await _auth.signInWithPhoneNumber(phone);
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
          PhoneAuthChallenge.verificationId = verificationId;
          onCodeSent();
          if (!sent.isCompleted) {
            sent.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          PhoneAuthChallenge.verificationId = verificationId;
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
      final ConfirmationResult? result = PhoneAuthChallenge.webConfirmation;
      if (result == null) {
        throw StateError('OTP was not requested yet.');
      }
      final UserCredential credential = await result.confirm(otpCode);
      PhoneAuthChallenge.clear();
      return credential;
    }

    final String? verificationId = PhoneAuthChallenge.verificationId;
    if (verificationId == null) {
      throw StateError('Verification ID is missing. Request OTP first.');
    }

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );
    final UserCredential signedIn = await _auth.signInWithCredential(credential);
    PhoneAuthChallenge.clear();
    return signedIn;
  }
}
