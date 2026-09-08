import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../services/ideathon_details_loader.dart';

/// Event-scoped ideas already loaded on Event Details → Entries.
class EventIdeasExportProvider implements ExportDataProvider {
  const EventIdeasExportProvider({required this.entries});

  final List<IdeathonIdeaEntry> entries;

  @override
  ExportModule get module => ExportModule.ideas;

  @override
  List<ExportFormat> get supportedFormats => const <ExportFormat>[ExportFormat.excel];

  @override
  bool get requiresEvent => true;

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
    if (!request.hasEventScope) {
      throw ExportException.missingEvent();
    }
    final String orgId = ExportTenantGuard.resolvedOrgId(request.actor);
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final IdeathonIdeaEntry entry in entries) {
      final String ideaOrg = (entry.idea?.orgId ?? '').trim();
      if (orgId.isNotEmpty && ideaOrg.isNotEmpty && ideaOrg != orgId) continue;
      rows.add(<String, Object?>{
        'title': entry.ideaTitle.trim().isEmpty ? entry.ideaId : entry.ideaTitle.trim(),
        'problem': entry.problemTitle.trim(),
        'team': entry.teamName.trim(),
        'department': (entry.idea?.teamDepartmentCode ?? '').trim(),
        'status': entry.idea == null
            ? 'Registered'
            : IdeaStatusHelpers.label(entry.idea!.status),
      });
    }
    return ExportTable(
      sheetName: 'Ideas',
      columns: const <ExportColumn>[
        ExportColumn(key: 'title', header: 'Idea'),
        ExportColumn(key: 'problem', header: 'Problem'),
        ExportColumn(key: 'team', header: 'Team'),
        ExportColumn(key: 'department', header: 'Department'),
        ExportColumn(key: 'status', header: 'Status'),
      ],
      rows: rows,
    );
  }
}
