import '../../../utils/firestore_utils.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_commercial_plan.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/services/commercial_access.dart';
import '../../organization/services/organisation_access.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import 'ideathon_service.dart';
import '../workspace/ideathon_workspace_loader.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Minimal data to render Event Details shell (header, nav counts, overview fields).
class IdeathonDetailsShellViewModel {
  const IdeathonDetailsShellViewModel({
    required this.ideathon,
    required this.organisationName,
    required this.departmentLabel,
    required this.evaluationTemplateName,
    required this.commercialPlan,
  });

  final IdeathonModel ideathon;
  final String organisationName;
  final String departmentLabel;
  final String evaluationTemplateName;
  final OrganizationCommercialPlan commercialPlan;

  int get ideaCount => ideathon.ideas.length;

  bool get requiresIdeaPayment => CommercialAccess.requiresIdeaPayment(commercialPlan);

  IdeathonWorkspaceViewModel minimalWorkspace() {
    final DepartmentModel? department = DepartmentModel.byCode(ideathon.departmentId);
    return IdeathonWorkspaceViewModel(
      ideathon: ideathon,
      judges: const <UserModel>[],
      coordinators: const <UserModel>[],
      evaluationProgressLabel: '—',
      evaluationProgressPct: 0,
      organisationName: organisationName,
      departmentName: (department?.name ?? ideathon.departmentId).trim(),
      evaluationTemplateName: evaluationTemplateName,
      commercialPlan: commercialPlan,
    );
  }
}

abstract final class IdeathonDetailsShellLoader {
  IdeathonDetailsShellLoader._();

  static Future<IdeathonDetailsShellViewModel> load(String ideathonId) async {
    final IdeathonModel? loaded = await IdeathonService.fetchById(ideathonId);
    if (loaded == null) throw StateError('Ideathon not found');
    final IdeathonModel ideathon = loaded;

    final OrganizationModel? controlPlaneOrg = ideathon.orgId.trim().isEmpty
        ? null
        : await OrganisationAccess.fetch(ideathon.orgId);
    final OrganizationCommercialPlan commercialPlan = CommercialAccess.planOf(controlPlaneOrg);

    OrganizationModel? tenantOrg;
    if (ideathon.orgId.trim().isNotEmpty) {
      tenantOrg = await FirestoreUtils.fetchOrganization(ideathon.orgId);
    }

    final String templateName =
        EvaluationTemplatesService.findTemplate(ideathon.evaluationTemplateId)?.templateName.trim() ??
            '';

    return IdeathonDetailsShellViewModel(
      ideathon: ideathon,
      organisationName: _organisationName(org: tenantOrg, orgId: ideathon.orgId),
      departmentLabel: DepartmentModel.labelFor(ideathon.departmentId),
      evaluationTemplateName: templateName,
      commercialPlan: commercialPlan,
    );
  }

  static String _organisationName({required OrganizationModel? org, required String orgId}) {
    final String id = orgId.trim();
    final String fromDoc = (org?.name ?? '').trim();
    if (fromDoc.isNotEmpty && fromDoc != id) return fromDoc;

    if (HackzFirebase.isOrganisationWorkspace) {
      final String boundName = HackzFirebase.current.context.organisationName.trim();
      final String boundId = HackzFirebase.current.context.organisationId.trim();
      if (boundName.isNotEmpty && boundName != id && boundName != boundId) {
        return boundName;
      }
    }

    return '';
  }
}
