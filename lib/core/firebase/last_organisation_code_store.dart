import 'package:shared_preferences/shared_preferences.dart';

import 'organisation_code.dart';

/// Remembers the last organisation code used to sign in.
///
/// Convenience only. Organisation Code remains the canonical tenant-routing
/// mechanism; this never replaces entering a code, and never looks up phones.
abstract final class LastOrganisationCodeStore {
  LastOrganisationCodeStore._();

  static const String key = 'hackz.lastOrganisationCode';

  static Future<void> save(String code) async {
    final String? parsed = OrganisationCode.tryParse(code);
    if (parsed == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, parsed);
  }

  static Future<String?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return OrganisationCode.tryParse(prefs.getString(key) ?? '');
  }
}
