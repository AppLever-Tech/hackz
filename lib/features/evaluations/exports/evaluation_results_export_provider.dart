import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../user/models/user_model.dart';
import '../services/evaluation_ranking_service.dart';

/// Maps Evaluation Results workspace rows (already filtered) into export rows.
class EvaluationResultsExportProvider implements ExportDataProvider {
  const EvaluationResultsExportProvider({
    required this.rows,
    this.eventScoped = false,
  });

  final List<EvaluationResultsRow> rows;
  final bool eventScoped;

  @override
  ExportModule get module => ExportModule.evaluationResults;

  @override
  List<ExportFormat> get supportedFormats => const <ExportFormat>[ExportFormat.excel];

  @override
  bool get requiresEvent => eventScoped;

  @override
  bool canExport(UserModel actor) => ExportTenantGuard.actorMatchesBoundOrganisation(actor);

  @override
  Future<ExportTable> load(ExportRequest request) async {
    if (!canExport(request.actor)) {
      throw ExportException.unauthorized();
    }
    if (requiresEvent && !request.hasEventScope) {
      throw ExportException.missingEvent();
    }
    final String orgId = ExportTenantGuard.resolvedOrgId(request.actor);
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    for (final EvaluationResultsRow row in rows) {
      if (orgId.isNotEmpty && row.idea.orgId.trim() != orgId) continue;
      final bool hideFinalAverage = eventScoped && !row.evaluationComplete;
      out.add(<String, Object?>{
        'order': row.rank > 0 ? row.rank : null,
        'idea': row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim(),
        'department': row.idea.teamDepartmentCode.trim(),
        'problem': row.problemTitle.trim(),
        'category': row.category.trim(),
        'average': hideFinalAverage ? null : row.aggregate.averageScore,
        'highest': row.aggregate.highestScore,
        'lowest': row.aggregate.lowestScore,
        'submitted': row.aggregate.totalEvaluators,
        'assigned': eventScoped ? row.assignedJudges : null,
        'status': eventScoped
            ? (row.evaluationComplete ? 'Evaluated' : 'Pending')
            : IdeaStatusHelpers.label(row.idea.status),
      });
    }
    return ExportTable(
      sheetName: 'Evaluation Results',
      columns: <ExportColumn>[
        ExportColumn(key: 'order', header: eventScoped ? 'Order' : 'Rank'),
        const ExportColumn(key: 'idea', header: 'Idea'),
        const ExportColumn(key: 'department', header: 'Department'),
        const ExportColumn(key: 'problem', header: 'Problem'),
        const ExportColumn(key: 'category', header: 'Category'),
        const ExportColumn(key: 'average', header: 'Average score'),
        const ExportColumn(key: 'highest', header: 'Highest'),
        const ExportColumn(key: 'lowest', header: 'Lowest'),
        ExportColumn(key: 'submitted', header: eventScoped ? 'Submitted' : 'Evaluators'),
        if (eventScoped) const ExportColumn(key: 'assigned', header: 'Assigned judges'),
        const ExportColumn(key: 'status', header: 'Status'),
      ],
      rows: out,
    );
  }
}
