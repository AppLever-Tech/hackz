import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hackz/features/evaluations/services/evaluation_templates_service.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_idea_snapshot.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_workspace_loader.dart';
import 'package:hackz/features/organization/models/department_model.dart';
import 'package:hackz/features/org_settings/services/org_settings_service.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/utils/firestore_utils.dart';

class IdeathonIdeaEntry {
  const IdeathonIdeaEntry({
    required this.snapshot,
    this.idea,
  });

  final IdeathonIdeaSnapshot snapshot;
  final IdeaModel? idea;

  String get ideaId => snapshot.ideaId;
  String get ideaTitle {
    final String live = (idea?.ideaTitle ?? '').trim();
    return live.isNotEmpty ? live : snapshot.ideaTitle;
  }

  String get problemTitle {
    final String live = (idea?.problemTitle ?? '').trim();
    return live.isNotEmpty ? live : snapshot.problemTitle;
  }

  String get problemId => (idea?.problemId ?? '').trim();
  String get teamId => (idea?.teamId ?? '').trim();
  String get teamName => snapshot.teamName.trim();
}

class IdeathonDetailsViewModel {
  const IdeathonDetailsViewModel({
    required this.workspace,
    required this.organisationName,
    required this.departmentLabel,
    required this.evaluationTemplateName,
    required this.ideas,
  });

  final IdeathonWorkspaceViewModel workspace;
  final String organisationName;
  final String departmentLabel;
  final String evaluationTemplateName;
  final List<IdeathonIdeaEntry> ideas;

  IdeathonModel get ideathon => workspace.ideathon;
  List<UserModel> get judges => workspace.judges;
  List<UserModel> get coordinators => workspace.coordinators;
}

abstract final class IdeathonDetailsLoader {
  IdeathonDetailsLoader._();

  static Future<IdeathonDetailsViewModel> load(String ideathonId) async {
    final IdeathonWorkspaceViewModel workspace = await IdeathonWorkspaceLoader.load(ideathonId);
    final IdeathonModel event = workspace.ideathon;

    await OrgSettingsService.instance.ensureLoaded(orgId: event.orgId);

    final org = event.orgId.trim().isEmpty ? null : await FirestoreUtils.fetchOrganization(event.orgId);
    final DepartmentModel? department = DepartmentModel.byCode(event.departmentId);
    final String templateName =
        EvaluationTemplatesService.findTemplate(event.evaluationTemplateId)?.templateName.trim() ?? '';

    return IdeathonDetailsViewModel(
      workspace: workspace,
      organisationName: (org?.name ?? '').trim(),
      departmentLabel: department == null
          ? event.departmentId.trim()
          : '${department.code} · ${department.name}',
      evaluationTemplateName: templateName,
      ideas: await _loadIdeas(event.ideas),
    );
  }

  static Future<List<IdeathonIdeaEntry>> _loadIdeas(List<IdeathonIdeaSnapshot> snapshots) {
    return Future.wait(snapshots.map(_loadIdea));
  }

  static Future<IdeathonIdeaEntry> _loadIdea(IdeathonIdeaSnapshot snapshot) async {
    IdeaModel? idea;
    final String id = snapshot.ideaId.trim();
    if (id.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection(FirestoreUtils.hkzIdeas).doc(id).get();
      if (doc.exists && doc.data() != null) {
        idea = IdeaModel.fromMap(doc.id, doc.data()!);
      }
    }
    return IdeathonIdeaEntry(snapshot: snapshot, idea: idea);
  }
}
