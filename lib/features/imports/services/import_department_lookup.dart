import '../../organization/models/department_model.dart';
import '../../../utils/firestore_utils.dart';

/// Session mapping from a normalized CSV department value to an org department.
class ImportDepartmentMapping {
  const ImportDepartmentMapping({
    required this.code,
    required this.name,
    this.id = '',
  });

  final String code;
  final String name;
  final String id;
}

/// A department known to the organization (from Firestore — not hardcoded).
class ImportDepartmentInfo {
  const ImportDepartmentInfo({
    required this.code,
    required this.name,
    this.id = '',
    this.adminUserId = '',
    this.aliases = const <String>[],
  });

  final String id;
  final String code;
  final String name;
  final String adminUserId;
  final List<String> aliases;

  bool get hasAdministrator => adminUserId.trim().isNotEmpty;

  String get displayLabel => name.isEmpty ? code : '$code – $name';

  ImportDepartmentMapping toMapping() => ImportDepartmentMapping(code: code, name: name, id: id);

  static const String departmentCodesFileName = 'hackz_department_codes.csv';
}

/// Org-scoped department codes loaded for import validation and reference UI.
class ImportDepartmentLookup {
  ImportDepartmentLookup({required List<ImportDepartmentInfo> departments})
      : departments = List<ImportDepartmentInfo>.unmodifiable(departments),
        codes = departments.map((ImportDepartmentInfo d) => d.code).toSet(),
        codeToName = <String, String>{
          for (final ImportDepartmentInfo d in departments) d.code: d.name,
        } {
    for (final ImportDepartmentInfo department in departments) {
      final String codeKey = department.code.trim().toUpperCase();
      if (codeKey.isNotEmpty) {
        _byCode.putIfAbsent(codeKey, () => department);
        _byNormalized.putIfAbsent(DepartmentModel.normalizeKey(department.code), () => department);
      }
      final String nameKey = DepartmentModel.normalizeKey(department.name);
      if (nameKey.isNotEmpty) {
        _byNormalized.putIfAbsent(nameKey, () => department);
      }
    }
    for (final ImportDepartmentInfo department in departments) {
      for (final String alias in department.aliases) {
        final String aliasKey = DepartmentModel.normalizeKey(alias);
        if (aliasKey.isEmpty) continue;
        _byNormalized.putIfAbsent(aliasKey, () => department);
      }
    }
  }

  final List<ImportDepartmentInfo> departments;
  final Set<String> codes;
  final Map<String, String> codeToName;
  final Map<String, ImportDepartmentInfo> _byCode = <String, ImportDepartmentInfo>{};
  final Map<String, ImportDepartmentInfo> _byNormalized = <String, ImportDepartmentInfo>{};

  /// Resolves a non-empty CSV department via code, name, normalized match, then aliases.
  ImportDepartmentInfo? resolve(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final ImportDepartmentInfo? exactCode = _byCode[trimmed.toUpperCase()];
    if (exactCode != null) return exactCode;

    final String key = DepartmentModel.normalizeKey(trimmed);
    if (key.isEmpty) return null;
    return _byNormalized[key];
  }

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
      list.add(
        ImportDepartmentInfo(
          id: ((doc['id'] as String?) ?? '').trim(),
          code: code,
          name: name,
          adminUserId: ((doc['adminUserId'] as String?) ?? '').trim(),
          aliases: DepartmentModel.parseAliases(doc['aliases']),
        ),
      );
    }
    list.sort((ImportDepartmentInfo a, ImportDepartmentInfo b) => a.code.compareTo(b.code));
    return ImportDepartmentLookup(departments: list);
  }
}
