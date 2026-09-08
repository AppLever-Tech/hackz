import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../models/problem_model.dart';
import '../services/problem_status_helpers.dart';

/// Maps the Problem Statements workspace (already filtered) into export rows.
class ProblemStatementsExportProvider implements ExportDataProvider {
  const ProblemStatementsExportProvider({
    required this.problems,
    this.domainLabels = const <String, String>{},
  });

  final List<ProblemModel> problems;
  final Map<String, String> domainLabels;

  @override
  ExportModule get module => ExportModule.problemStatements;

  @override
  List<ExportFormat> get supportedFormats => const <ExportFormat>[ExportFormat.excel];

  @override
  bool get requiresEvent => false;

  @override
  bool canExport(UserModel actor) => ExportTenantGuard.actorMatchesBoundOrganisation(actor);

  @override
  Future<ExportTable> load(ExportRequest request) async {
    if (!canExport(request.actor)) {
      throw ExportException.unauthorized();
    }
    final String orgId = _resolvedOrgId(request.actor);
    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (final ProblemModel problem in problems) {
      if (orgId.isNotEmpty && problem.orgId.trim() != orgId) continue;
      rows.add(<String, String>{
        'number': problem.problemNumber,
        'title': problem.title,
        'department': problem.departmentCode,
        'domain': _domainLabel(problem.domainId),
        'status': ProblemStatusHelpers.label(problem.status),
        'category': problem.category,
        'theme': problem.theme,
        'source': ProblemStatusHelpers.sourceLabel(problem.createdSource),
        'created': formatDateTime(problem.createdAt),
      });
    }
    return ExportTable(
      sheetName: 'Problem Statements',
      columns: const <ExportColumn>[
        ExportColumn(key: 'number', header: 'Problem number'),
        ExportColumn(key: 'title', header: 'Title'),
        ExportColumn(key: 'department', header: 'Department'),
        ExportColumn(key: 'domain', header: 'Domain'),
        ExportColumn(key: 'status', header: 'Status'),
        ExportColumn(key: 'category', header: 'Category'),
        ExportColumn(key: 'theme', header: 'Theme'),
        ExportColumn(key: 'source', header: 'Source'),
        ExportColumn(key: 'created', header: 'Created'),
      ],
      rows: rows,
    );
  }

  String _domainLabel(String domainId) {
    final String id = domainId.trim();
    if (id.isEmpty) return '';
    return (domainLabels[id] ?? id).trim();
  }

  String _resolvedOrgId(UserModel actor) {
    final String actorOrg = actor.orgId.trim();
    if (actorOrg.isNotEmpty) return actorOrg;
    return ExportTenantGuard.boundOrganisationId();
  }
}
