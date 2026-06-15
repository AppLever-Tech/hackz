import '../../../utils/firestore_utils.dart';

/// A department known to the organization (from Firestore — not hardcoded).
class ImportDepartmentInfo {
  const ImportDepartmentInfo({required this.code, required this.name});

  final String code;
  final String name;

  String get displayLabel => name.isEmpty ? code : '$code – $name';

  static const String departmentCodesFileName = 'hackz_department_codes.csv';
}

/// Org-scoped department codes loaded for import validation and reference UI.
class ImportDepartmentLookup {
  ImportDepartmentLookup({required List<ImportDepartmentInfo> departments})
      : departments = List<ImportDepartmentInfo>.unmodifiable(departments),
        codes = departments.map((ImportDepartmentInfo d) => d.code).toSet(),
        codeToName = <String, String>{
          for (final ImportDepartmentInfo d in departments) d.code: d.name,
        };

  final List<ImportDepartmentInfo> departments;
  final Set<String> codes;
  final Map<String, String> codeToName;

  /// CSV content: `departmentCode,departmentName` — shared by download and reference UI.
  String buildDepartmentCodesCsv() {
    final StringBuffer buffer = StringBuffer('departmentCode,departmentName');
    for (final ImportDepartmentInfo department in departments) {
      buffer.write('\n');
      buffer.write(department.code);
      buffer.write(',');
      buffer.write(_escapeCsvField(department.name));
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<ImportDepartmentLookup> load(String orgId) async {
    final List<Map<String, dynamic>> raw = await FirestoreUtils.getDepartmentsByCollege(orgId);
    final List<ImportDepartmentInfo> list = <ImportDepartmentInfo>[];
    for (final Map<String, dynamic> doc in raw) {
      final String code = ((doc['code'] as String?) ?? '').trim().toUpperCase();
      if (code.isEmpty) continue;
      final String name = ((doc['name'] as String?) ?? '').trim();
      list.add(ImportDepartmentInfo(code: code, name: name));
    }
    list.sort((ImportDepartmentInfo a, ImportDepartmentInfo b) => a.code.compareTo(b.code));
    return ImportDepartmentLookup(departments: list);
  }
}
