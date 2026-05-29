import '../../../models/department_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/profiles/user_profile.dart';
import '../models/user_model.dart';

/// User persistence helpers (identity + optional profile on hkzUsers).
abstract final class UserService {
  static Future<String> createUser({
    required UserModel user,
    UserProfile? profile,
  }) async {
    final UserModel payload = user.copyWith(
      profile: profile == null || profile.isEmpty ? null : profile,
    );
    return FirestoreUtils.createUser(payload);
  }

  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> updates, {
    UserProfile? profile,
  }) async {
    final Map<String, dynamic> merged = Map<String, dynamic>.from(updates);
    if (profile != null) {
      if (profile.isEmpty) {
        merged['profile'] = null;
      } else {
        merged['profile'] = profile.toMap();
      }
    }
    await FirestoreUtils.updateUser(userId, merged);
  }

  static Future<UserModel?> fetchUser(String userId) => FirestoreUtils.fetchUser(userId);

  static String resolveDepartmentCode(String department) => DepartmentModel.resolveCode(department);
}
