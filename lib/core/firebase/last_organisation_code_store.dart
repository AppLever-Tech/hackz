import 'package:shared_preferences/shared_preferences.dart';

import 'organisation_code.dart';

/// Remembers the last organisation code used to sign in, and whether the last
/// session was Platform Admin (Control Plane) rather than a college tenant.
///
/// Convenience only. Organisation Code remains the canonical college-user
/// routing mechanism. This never looks up phones.
abstract final class LastOrganisationCodeStore {
  LastOrganisationCodeStore._();

  static const String key = 'hackz.lastOrganisationCode';
  static const String platformAdminKey = 'hackz.platformAdminSession';

  static Future<void> save(String code) async {
    final String? parsed = OrganisationCode.tryParse(code);
    if (parsed == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, parsed);
    await prefs.setBool(platformAdminKey, false);
  }

  static Future<String?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return OrganisationCode.tryParse(prefs.getString(key) ?? '');
  }

  static Future<void> savePlatformAdminSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(platformAdminKey, true);
  }

  static Future<void> clearPlatformAdminSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(platformAdminKey, false);
  }

  static Future<bool> isPlatformAdminSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(platformAdminKey) ?? false;
  }
}
