import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_idea_snapshot.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_shell_loader.dart';
import 'package:hackz/features/organization/models/department_model.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_workspace_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/utils/firestore_utils.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

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

class IdeathonOverviewPeople {
  const IdeathonOverviewPeople({
    required this.judges,
    required this.coordinators,
  });

  final List<UserModel> judges;
  final List<UserModel> coordinators;
}

class IdeathonDetailsViewModel {
  const IdeathonDetailsViewModel({
    required this.workspace,
    required this.organisationName,
    required this.departmentLabel,
    required this.evaluationTemplateName,
    required this.ideas,
    this.unusedDeletable = false,
  });

  final IdeathonWorkspaceViewModel workspace;
  final String organisationName;
  final String departmentLabel;
  final String evaluationTemplateName;
  final List<IdeathonIdeaEntry> ideas;
  final bool unusedDeletable;

  IdeathonModel get ideathon => workspace.ideathon;
  List<UserModel> get judges => workspace.judges;
  List<UserModel> get coordinators => workspace.coordinators;
  bool get requiresIdeaPayment => workspace.requiresIdeaPayment;

  int get ideaCount => ideathon.ideas.length;

  static IdeathonDetailsViewModel fromShell({
    required IdeathonDetailsShellViewModel shell,
    required IdeathonWorkspaceViewModel workspace,
    List<IdeathonIdeaEntry> ideas = const <IdeathonIdeaEntry>[],
    bool unusedDeletable = false,
  }) {
    return IdeathonDetailsViewModel(
      workspace: workspace,
      organisationName: shell.organisationName,
      departmentLabel: shell.departmentLabel,
      evaluationTemplateName: shell.evaluationTemplateName,
      ideas: ideas,
      unusedDeletable: unusedDeletable,
    );
  }

  IdeathonDetailsViewModel copyWith({
    IdeathonWorkspaceViewModel? workspace,
    List<IdeathonIdeaEntry>? ideas,
    bool? unusedDeletable,
  }) {
    return IdeathonDetailsViewModel(
      workspace: workspace ?? this.workspace,
      organisationName: organisationName,
      departmentLabel: departmentLabel,
      evaluationTemplateName: evaluationTemplateName,
      ideas: ideas ?? this.ideas,
      unusedDeletable: unusedDeletable ?? this.unusedDeletable,
    );
  }
}

abstract final class IdeathonDetailsLoader {
  IdeathonDetailsLoader._();

  /// Full load (legacy / workspace panel). Event details pane uses shell + tab cache instead.
  static Future<IdeathonDetailsViewModel> load(String ideathonId) async {
    final IdeathonWorkspaceViewModel workspace = await IdeathonWorkspaceLoader.load(ideathonId);
    final IdeathonModel event = workspace.ideathon;
    final bool unusedDeletable = await IdeathonService.isUnusedEvent(event);

    return IdeathonDetailsViewModel(
      workspace: workspace,
      organisationName: workspace.organisationName,
      departmentLabel: DepartmentModel.labelFor(event.departmentId).isNotEmpty
          ? DepartmentModel.labelFor(event.departmentId)
          : workspace.departmentName,
      evaluationTemplateName: workspace.evaluationTemplateName,
      ideas: await loadIdeas(event.ideas),
      unusedDeletable: unusedDeletable,
    );
  }

  static Future<List<IdeathonIdeaEntry>> loadIdeas(List<IdeathonIdeaSnapshot> snapshots) {
    return Future.wait(snapshots.map(_loadIdea));
  }

  static Future<IdeathonOverviewPeople> loadOverviewPeople(IdeathonModel event) async {
    final List<UserModel> judges = await _fetchUsers(event.judgeIds);
    final List<UserModel> coordinators = await _fetchUsers(event.coordinatorIds);
    return IdeathonOverviewPeople(judges: judges, coordinators: coordinators);
  }

  static Future<IdeathonIdeaEntry> _loadIdea(IdeathonIdeaSnapshot snapshot) async {
    IdeaModel? idea;
    final String id = snapshot.ideaId.trim();
    if (id.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await HackzFirebase.current.firestore.collection(FirestoreUtils.hkzIdeas).doc(id).get();
      if (doc.exists && doc.data() != null) {
        idea = IdeaModel.fromMap(doc.id, doc.data()!);
      }
    }
    return IdeathonIdeaEntry(snapshot: snapshot, idea: idea);
  }

  static Future<List<UserModel>> _fetchUsers(List<String> ids) async {
    final List<UserModel> users = <UserModel>[];
    for (final String raw in ids) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      final UserModel? user = await FirestoreUtils.fetchUser(id);
      if (user != null) users.add(user);
    }
    users.sort((UserModel a, UserModel b) => userDisplayName(a).compareTo(userDisplayName(b)));
    return users;
  }
}
