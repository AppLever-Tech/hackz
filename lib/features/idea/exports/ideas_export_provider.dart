import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../../../utils/common_helpers.dart';
import '../models/idea_event_participation_summary.dart';
import '../services/idea_query_service.dart';
import '../services/idea_status_helpers.dart';

/// Maps the Ideas workspace (already filtered) into export rows.
class IdeasExportProvider implements ExportDataProvider {
  const IdeasExportProvider({required this.items});

  final List<IdeaListItem> items;

  @override
  ExportModule get module => ExportModule.ideas;

  @override
  List<ExportFormat> get supportedFormats => ExportFormat.reportFormats;

  @override
  bool get requiresEvent => false;

  @override
  bool canExport(UserModel actor) {
    if (!ExportTenantGuard.actorMatchesBoundOrganisation(actor)) return false;
    return RoleVisibilityHelpers.canViewIdeas(UserRole.fromCode(actor.role));
  }

  @override
  Future<ExportTable> load(ExportRequest request) async {
    if (!canExport(request.actor)) {
      throw ExportException.unauthorized();
    }
    final String orgId = ExportTenantGuard.resolvedOrgId(request.actor);
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final IdeaListItem item in items) {
      if (orgId.isNotEmpty && item.idea.orgId.trim() != orgId) continue;
      rows.add(<String, Object?>{
        'title': item.idea.ideaTitle.trim().isEmpty
            ? item.idea.ideaId
            : item.idea.ideaTitle.trim(),
        'team': item.teamName.trim(),
        'problemNumber': item.idea.problemNumber.trim(),
        'problem': item.idea.problemTitle.trim(),
        'department': item.idea.teamDepartmentCode.trim(),
        'status': IdeaStatusHelpers.label(item.idea.status),
        'events': item.events
            .map(_eventCell)
            .where((String s) => s.isNotEmpty)
            .join('; '),
        'submitted': formatDateTime(item.idea.createdAt),
      });
    }
    return ExportTable(
      sheetName: 'Ideas',
      columns: const <ExportColumn>[
        ExportColumn(key: 'title', header: 'Idea'),
        ExportColumn(key: 'team', header: 'Team'),
        ExportColumn(key: 'problemNumber', header: 'Problem number'),
        ExportColumn(key: 'problem', header: 'Problem'),
        ExportColumn(key: 'department', header: 'Department'),
        ExportColumn(key: 'status', header: 'Status'),
        ExportColumn(key: 'events', header: 'Events'),
        ExportColumn(key: 'submitted', header: 'Submitted'),
      ],
      rows: rows,
    );
  }

  static String _eventCell(IdeaEventParticipationSummary event) {
    final String name = event.eventName.trim();
    if (name.isEmpty) return '';
    return '$name (${event.paymentLabel})';
  }
}
