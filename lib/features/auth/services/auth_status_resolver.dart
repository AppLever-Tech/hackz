import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/enums/account_workspace_phase.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/user_model.dart';
import 'auth_utils.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';

enum SignInNextStep {
  signUp,
  verifyOtp,
  accountStatusWorkspace,
}

class SignInResolution {
  const SignInResolution({
    required this.step,
    required this.phone,
    this.user,
    this.workspacePhase,
  });

  final SignInNextStep step;
  final String phone;
  final UserModel? user;
  final AccountWorkspacePhase? workspacePhase;
}

class AuthStatusResolver {
  AuthStatusResolver._();

  static Future<SignInResolution> resolveSignInFlow(String rawPhone) async {
    final phone = normalizePhoneE164(rawPhone);
    final user = await FirestoreUtils.fetchUserByPhone(phone);
    if (user == null) {
      return SignInResolution(
        step: SignInNextStep.signUp,
        phone: phone,
      );
    }

    if (user.status == UserStatus.active) {
      return SignInResolution(
        step: SignInNextStep.verifyOtp,
        phone: phone,
        user: user,
      );
    }

    return SignInResolution(
      step: SignInNextStep.accountStatusWorkspace,
      phone: phone,
      user: user,
      workspacePhase: user.status.toWorkspacePhase,
    );
  }

  static Future<UserModel?> resolveSignedInUser(User firebaseUser) async {
    final byUid = await FirestoreUtils.fetchUser(firebaseUser.uid);
    if (byUid != null) return byUid;

    final phone = firebaseUser.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    final normalized = normalizePhoneE164(phone);
    final byPhone = await FirestoreUtils.fetchUserByPhone(normalized);
    if (byPhone != null) return byPhone;

    final whitelist = await AuthUtils.checkWhitelist(normalized);
    if (whitelist != null) {
      await AuthUtils.ensureSysAdminUserFromWhitelist(
        firebaseAuthUid: firebaseUser.uid,
        phone: normalized,
        whitelist: whitelist,
      );
      return FirestoreUtils.fetchUser(firebaseUser.uid) ??
          FirestoreUtils.fetchUserByPhone(normalized);
    }
    return null;
  }
}
