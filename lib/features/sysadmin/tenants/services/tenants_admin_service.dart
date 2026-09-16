import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/approved_tenant_project.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/firebase/tenant_registry.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../utils/firestore_utils.dart';

class RegisteredTenantRow {
  const RegisteredTenantRow({
    required this.project,
    required this.linkedOrganisations,
  });

  final ApprovedTenantProject project;
  final List<TenantRecord> linkedOrganisations;

  bool get inUse => linkedOrganisations.isNotEmpty;

  String get organisationSummary {
    if (linkedOrganisations.isEmpty) return '—';
    final List<String> labels = linkedOrganisations
        .map((TenantRecord r) {
          final String name = r.organisationName.trim();
          final String code = r.organisationCode.trim();
          if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
          if (name.isNotEmpty) return name;
          if (code.isNotEmpty) return code;
          return r.tenantId;
        })
        .toList(growable: false);
    return labels.join(', ');
  }
}

abstract final class TenantsAdminService {
  TenantsAdminService._();

  static Future<({Set<String> ids, Set<String> namesLower})> _liveOrganisationKeys() async {
    final List<OrganizationModel> orgs = await FirestoreUtils.getOrganizations(
      database: HackzFirebase.controlPlane.firestore,
    );
    final Set<String> ids = orgs.map((OrganizationModel o) => o.id).toSet();
    final Set<String> namesLower = orgs
        .map((OrganizationModel o) => o.name.trim().toLowerCase())
        .where((String name) => name.isNotEmpty)
        .toSet();
    return (ids: ids, namesLower: namesLower);
  }

  static List<TenantRecord> _linkedOrganisations(
    Iterable<TenantRecord> routing, {
    required Set<String> liveOrganisationIds,
    required Set<String> liveOrganisationNamesLower,
  }) {
    return routing
        .where(
          (TenantRecord record) => TenantRegistry.isLinkedToLiveOrganisation(
            record,
            liveOrganisationIds: liveOrganisationIds,
            liveOrganisationNamesLower: liveOrganisationNamesLower,
          ),
        )
        .toList(growable: false);
  }

  static Future<List<RegisteredTenantRow>> loadRegisteredTenants() async {
    await ApprovedTenantFirebase.refresh();
    final List<ApprovedTenantProject> projects = ApprovedTenantFirebase.registeredTenants;
    final List<TenantRecord> routing = await TenantRegistry.listAll();
    final ({Set<String> ids, Set<String> namesLower}) live = await _liveOrganisationKeys();
    final Map<String, List<TenantRecord>> byProject = <String, List<TenantRecord>>{};
    for (final TenantRecord record in routing) {
      final String projectId = record.firebaseProjectId.trim();
      if (projectId.isEmpty) continue;
      if (!TenantRegistry.isLinkedToLiveOrganisation(
        record,
        liveOrganisationIds: live.ids,
        liveOrganisationNamesLower: live.namesLower,
      )) {
        continue;
      }
      byProject.putIfAbsent(projectId, () => <TenantRecord>[]).add(record);
    }
    return projects
        .map(
          (ApprovedTenantProject project) => RegisteredTenantRow(
            project: project,
            linkedOrganisations: byProject[project.projectId] ?? const <TenantRecord>[],
          ),
        )
        .toList(growable: false);
  }

  static Future<void> deleteRegistration(String projectId) async {
    final String id = projectId.trim();
    final List<TenantRecord> routing = await TenantRegistry.listByFirebaseProjectId(id);
    final ({Set<String> ids, Set<String> namesLower}) live = await _liveOrganisationKeys();
    final List<TenantRecord> linked = _linkedOrganisations(
      routing,
      liveOrganisationIds: live.ids,
      liveOrganisationNamesLower: live.namesLower,
    );
    if (linked.isNotEmpty) {
      final List<String> labels = linked
          .map((TenantRecord r) {
            final String name = r.organisationName.trim();
            final String code = r.organisationCode.trim();
            if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
            if (name.isNotEmpty) return name;
            if (code.isNotEmpty) return code;
            return r.tenantId;
          })
          .toList(growable: false);
      throw StateError(
        'Cannot delete this tenant while organisations still reference it: ${labels.join(', ')}. '
        'Remove or reassign those organisations first. This only removes Hackz Control Plane registration — '
        'it does not delete the external Firebase project or tenant data.',
      );
    }
    await ApprovedTenantFirebase.deleteRegistration(id);
  }
}
