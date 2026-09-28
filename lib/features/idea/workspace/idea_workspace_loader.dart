import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/idea_status_helpers.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import '../../team/models/enums/team_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../models/idea_event_participation_summary.dart';
import '../../organization/models/organization_model.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/models/problem_status.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../services/idea_event_participation_loader.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class IdeaWorkspaceViewModel {
  const IdeaWorkspaceViewModel({
    required this.idea,
    required this.problem,
    required this.team,
    required this.organizationName,
    required this.problemTitle,
    required this.teamName,
    required this.submittedByName,
    required this.submittedBy,
    required this.teamLeader,
    required this.teamMembers,
    required this.eventParticipations,
    required this.attachments,
  });

  final IdeaModel idea;
  final ProblemModel problem;
  final TeamModel team;
  final String organizationName;
  final String problemTitle;
  final String teamName;
  final String submittedByName;
  final UserModel? submittedBy;
  final UserModel? teamLeader;
  final List<UserModel> teamMembers;
  final List<IdeaEventParticipationSummary> eventParticipations;
  final List<AttachmentModel> attachments;
}

abstract final class IdeaWorkspaceLoader {
  static Future<IdeaWorkspaceViewModel> load(String ideaId) async {
    final String id = ideaId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ideaId must be non-empty');
    }

    final FirebaseFirestore db = HackzFirebase.current.firestore;
    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Idea not found');
    }

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final String orgId = idea.orgId.trim();

    final Future<DocumentSnapshot<Map<String, dynamic>>?> teamFuture = idea.teamId.trim().isEmpty
        ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : db.collection(FirestoreUtils.hkzTeams).doc(idea.teamId.trim()).get();

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      teamFuture,
      idea.problemId.trim().isEmpty
          ? Future<ProblemModel?>.value(null)
          : FirestoreUtils.fetchProblemById(idea.problemId.trim()),
      orgId.isEmpty ? Future<OrganizationModel?>.value(null) : FirestoreUtils.fetchOrganization(orgId),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzAttachments).limit(0).get(),
            )
          : db
              .collection(FirestoreUtils.hkzAttachments)
              .where('orgId', isEqualTo: orgId)
              .where('isActive', isEqualTo: true)
              .limit(300)
              .get(),
      FirestoreUtils.fetchUser(idea.createdBy.trim()),
      IdeaEventParticipationLoader.loadForIdea(ideaId: id, orgId: orgId),
    ]);

    final DocumentSnapshot<Map<String, dynamic>>? teamDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>?;
    final ProblemModel? fetchedProblem = results[1] as ProblemModel?;
    final OrganizationModel? org = results[2] as OrganizationModel?;
    final QuerySnapshot<Map<String, dynamic>> attachmentSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final UserModel? submittedBy = results[4] as UserModel?;
    final List<IdeaEventParticipationSummary> events = results[5] as List<IdeaEventParticipationSummary>;

    final TeamModel team = teamDoc != null && teamDoc.exists && teamDoc.data() != null
        ? TeamModel.fromMap(teamDoc.id, teamDoc.data()!)
        : TeamModel(
            teamId: idea.teamId,
            teamName: '',
            studentIds: const <String>[],
            orgId: idea.orgId,
            departmentCode: idea.teamDepartmentCode,
            status: TeamStatus.inactive,
            createdAt: idea.createdAt,
          );

    final ProblemModel problem = fetchedProblem ??
        ProblemModel(
          problemId: idea.problemId,
          problemNumber: idea.problemNumber,
          title: idea.problemTitle,
          description: '',
          orgId: idea.orgId,
          orgType: '',
          departmentCode: idea.problemDepartmentCode,
          createdBy: idea.createdBy,
          category: '',
          theme: '',
          tags: const <String>[],
          attachments: const <String>[],
          status: ProblemStatus.active,
          createdAt: idea.createdAt,
        );

    final List<AttachmentModel> attachments = attachmentSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => AttachmentModel.fromMap(d.id, d.data()))
        .where((AttachmentModel a) => a.entityType == AttachmentEntityType.idea && a.entityId == id)
        .toList(growable: false)
      ..sort((AttachmentModel a, AttachmentModel b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> memberIds = <String>{
      ...team.studentIds.map((String id) => id.trim()),
      team.teamLeaderId.trim(),
    }.where((String id) => id.isNotEmpty).toSet();
    final Map<String, UserModel> membersById = <String, UserModel>{};
    await Future.wait<void>(
      memberIds.map((String memberId) async {
        final UserModel? user = await FirestoreUtils.fetchUser(memberId);
        if (user != null) membersById[memberId] = user;
      }),
    );

    final String orgName = (org?.name.trim() ?? '').isEmpty ? (orgId.isEmpty ? '—' : orgId) : org!.name.trim();
    final String teamName = team.teamName.trim().isEmpty
        ? (team.teamId.trim().isEmpty ? '—' : team.teamId.trim())
        : team.teamName.trim();
    final String problemTitle = problem.title.trim().isEmpty
        ? (problem.problemNumber.trim().isEmpty ? 'Problem' : problem.problemNumber.trim())
        : problem.title.trim();
    final String submittedByName = submittedBy == null
        ? (idea.createdBy.trim().isEmpty ? '—' : idea.createdBy.trim())
        : userDisplayName(submittedBy);

    final List<UserModel> teamMembers = memberIds
        .map((String memberId) => membersById[memberId])
        .whereType<UserModel>()
        .toList(growable: false);
    final UserModel? teamLeader = membersById[team.teamLeaderId.trim()];

    return IdeaWorkspaceViewModel(
      idea: idea,
      problem: problem,
      team: team,
      organizationName: orgName,
      problemTitle: problemTitle,
      teamName: teamName,
      submittedByName: submittedByName,
      submittedBy: submittedBy,
      teamLeader: teamLeader,
      teamMembers: teamMembers,
      eventParticipations: events,
      attachments: attachments,
    );
  }
}

String ideaWorkspaceStatusLabel(IdeaStatus status) => IdeaStatusHelpers.label(status);

IconData ideaWorkspaceStatusIcon(IdeaStatus status) => IdeaStatusHelpers.icon(status);
