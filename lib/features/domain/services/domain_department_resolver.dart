import '../../../utils/firestore_utils.dart';

/// Resolves the Firestore department document id for [departmentCode] within [orgId].
abstract final class DomainDepartmentResolver {
  DomainDepartmentResolver._();

  static Future<String?> departmentIdForCode({
    required String orgId,
    required String departmentCode,
  }) async {
    final String code = departmentCode.trim().toUpperCase();
    if (orgId.trim().isEmpty || code.isEmpty) return null;
    final List<Map<String, dynamic>> rows = await FirestoreUtils.getDepartmentsByCollege(orgId);
    for (final Map<String, dynamic> row in rows) {
      final String rowCode = ((row['code'] as String?) ?? '').trim().toUpperCase();
      if (rowCode == code) {
        final String id = ((row['id'] as String?) ?? '').trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  static Future<Map<String, String>> codeToIdMap(String orgId) async {
    final List<Map<String, dynamic>> rows = await FirestoreUtils.getDepartmentsByCollege(orgId);
    final Map<String, String> map = <String, String>{};
    for (final Map<String, dynamic> row in rows) {
      final String code = ((row['code'] as String?) ?? '').trim().toUpperCase();
      final String id = ((row['id'] as String?) ?? '').trim();
      if (code.isNotEmpty && id.isNotEmpty) map[code] = id;
    }
    return map;
  }

  static Future<Map<String, String>> idToCodeMap(String orgId) async {
    final List<Map<String, dynamic>> rows = await FirestoreUtils.getDepartmentsByCollege(orgId);
    final Map<String, String> map = <String, String>{};
    for (final Map<String, dynamic> row in rows) {
      final String code = ((row['code'] as String?) ?? '').trim().toUpperCase();
      final String id = ((row['id'] as String?) ?? '').trim();
      if (code.isNotEmpty && id.isNotEmpty) map[id] = code;
    }
    return map;
  }
}
