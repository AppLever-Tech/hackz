import '../../domain/models/domain_model.dart';
import '../../domain/services/domain_department_resolver.dart';
import '../../domain/services/domain_service.dart';

/// A domain known to the organization (from Firestore).
class ImportDomainInfo {
  const ImportDomainInfo({
    required this.domainId,
    required this.code,
    required this.name,
    required this.departmentId,
    required this.departmentCode,
  });

  final String domainId;
  final String code;
  final String name;
  final String departmentId;
  final String departmentCode;

  String get displayLabel {
    final String n = name.isEmpty ? code : name;
    return departmentCode.isEmpty ? n : '$code – $n ($departmentCode)';
  }

  static const String domainCodesFileName = 'hackz_domain_codes.csv';
}

/// Org-scoped domain codes for import validation and reference UI.
class ImportDomainLookup {
  ImportDomainLookup({required List<ImportDomainInfo> domains})
      : domains = List<ImportDomainInfo>.unmodifiable(domains);

  final List<ImportDomainInfo> domains;

  /// Resolve domain by code within a department (by department code).
  ImportDomainInfo? findByCodeInDepartment({
    required String departmentCode,
    required String domainCode,
  }) {
    final String dept = departmentCode.trim().toUpperCase();
    final String code = domainCode.trim().toUpperCase();
    if (dept.isEmpty || code.isEmpty) return null;
    for (final ImportDomainInfo d in domains) {
      if (d.departmentCode == dept && d.code == code) return d;
    }
    return null;
  }

  /// CSV: `domainCode,domainName,departmentCode`
  String buildDomainCodesCsv() {
    final StringBuffer buffer = StringBuffer('domainCode,domainName,departmentCode');
    for (final ImportDomainInfo domain in domains) {
      buffer.write('\n');
      buffer.write(domain.code);
      buffer.write(',');
      buffer.write(_escapeCsvField(domain.name));
      buffer.write(',');
      buffer.write(domain.departmentCode);
    }
    return buffer.toString();
  }

  static String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<ImportDomainLookup> load(String orgId) async {
    final Map<String, String> idToCode = await DomainDepartmentResolver.idToCodeMap(orgId);
    final List<DomainModel> all = await DomainService.listByOrg(orgId: orgId, activeOnly: false);
    final List<ImportDomainInfo> list = <ImportDomainInfo>[];
    for (final DomainModel d in all) {
      if (d.code.isEmpty) continue;
      list.add(
        ImportDomainInfo(
          domainId: d.domainId,
          code: d.code,
          name: d.name,
          departmentId: d.departmentId,
          departmentCode: (idToCode[d.departmentId] ?? '').toUpperCase(),
        ),
      );
    }
    list.sort((ImportDomainInfo a, ImportDomainInfo b) {
      final int byDept = a.departmentCode.compareTo(b.departmentCode);
      if (byDept != 0) return byDept;
      return a.code.compareTo(b.code);
    });
    return ImportDomainLookup(domains: list);
  }
}
