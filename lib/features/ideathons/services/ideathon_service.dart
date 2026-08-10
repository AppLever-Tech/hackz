import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_conflict.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import 'ideathon_participation_service.dart';
import 'ideathon_settings_service.dart';

class CreateIdeathonInput {
  const CreateIdeathonInput({
    required this.name,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.ideaIds,
    required this.judgeIds,
    required this.coordinatorIds,
    required this.evaluationTemplateId,
    this.problemId = '',
  });

  final String name;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<String> ideaIds;
  final List<String> judgeIds;
  final List<String> coordinatorIds;
  final String evaluationTemplateId;
  /// Optional — not required for creation; does not limit the Ideathon to one Problem.
  final String problemId;
}

abstract final class IdeathonService {
  IdeathonService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submitted ideas that can be selected when creating an Ideathon.
  ///
  /// Returns all eligible ideas in the organization (any department). Faculty
  /// may submit across departments, so Ideathon creation is not dept-scoped.
  static Future<List<IdeaModel>> fetchEligibleIdeasForIdeathon({
    required String orgId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: orgId.trim())
        .get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .where((IdeaModel idea) => IdeaStatusHelpers.isEligibleForIdeathon(idea.status))
        .toList(growable: false)
      ..sort((IdeaModel a, IdeaModel b) => a.ideaTitle.compareTo(b.ideaTitle));
  }

  static Future<String> createIdeathon({
    required UserModel actor,
    required CreateIdeathonInput input,
  }) async {
    final String orgId = actor.orgId.trim();
    final String dept = actor.departmentCode.trim().toUpperCase();
    if (orgId.isEmpty) throw StateError('Organization is required.');
    if (input.name.trim().isEmpty) throw StateError('Event name is required.');
    if (!input.endDateTime.isAfter(input.startDateTime)) {
      throw StateError('End date/time must be after start date/time.');
    }
    if (input.ideaIds.isEmpty) throw StateError('Select at least one idea.');
    if (input.judgeIds.isEmpty) throw StateError('Assign at least one judge.');

    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final int minimumIdeas = IdeathonSettingsService.minimumIdeasForIdeathon(orgId);
    if (input.ideaIds.length < minimumIdeas) {
      throw StateError('${input.ideaIds.length} of $minimumIdeas minimum ideas selected.');
    }

    final String templateId = input.evaluationTemplateId.trim().isNotEmpty
        ? input.evaluationTemplateId.trim()
        : IdeathonSettingsService.ideathonEvaluationTemplateId(orgId);
    final resolved = EvaluationTemplatesService.resolveTemplate(templateId);
    if (resolved.templateId.trim().isEmpty) {
      throw StateError('Select an evaluation template.');
    }

    final List<IdeaModel> eligible = await fetchEligibleIdeasForIdeathon(orgId: orgId);
    final Map<String, IdeaModel> eligibleById = <String, IdeaModel>{
      for (final IdeaModel idea in eligible) idea.ideaId: idea,
    };

    final List<IdeathonIdeaSnapshot> snapshots = <IdeathonIdeaSnapshot>[];
    for (final String rawId in input.ideaIds) {
      final String ideaId = rawId.trim();
      final IdeaModel? idea = eligibleById[ideaId];
      if (idea == null) {
        throw StateError('Only submitted ideas can be added to an Ideathon.');
      }
      final TeamModel? team = idea.teamId.trim().isEmpty
          ? null
          : await _db.collection(FirestoreUtils.hkzTeams).doc(idea.teamId.trim()).get().then(
                (DocumentSnapshot<Map<String, dynamic>> doc) {
                  if (!doc.exists || doc.data() == null) return null;
                  return TeamModel.fromMap(doc.id, doc.data()!);
                },
              );
      snapshots.add(
        IdeathonIdeaSnapshot(
          ideaId: idea.ideaId,
          ideaTitle: idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim(),
          problemTitle: idea.problemTitle.trim().isEmpty ? '—' : idea.problemTitle.trim(),
          teamName: team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : '—',
          addedAt: DateTime.now(),
        ),
      );
    }

    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestoreUtils.hkzIdeathons).doc();
    final IdeathonModel ideathon = IdeathonModel(
      ideathonId: ref.id,
      orgId: orgId,
      name: input.name.trim(),
      description: input.description.trim(),
      departmentId: dept,
      startDateTime: input.startDateTime,
      endDateTime: input.endDateTime,
      status: IdeathonStatus.draft,
      judgeIds: input.judgeIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(),
      coordinatorIds:
          input.coordinatorIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(),
      ideas: snapshots,
      evaluationTemplateId: resolved.templateId,
      problemId: input.problemId.trim(),
      createdBy: actor.userId,
      createdAt: now,
      updatedAt: now,
    );

    final WriteBatch batch = _db.batch();
    batch.set(ref, ideathon.toMap());
    await IdeathonParticipationService.createForIdeathon(
      orgId: orgId,
      ideathonId: ideathon.ideathonId,
      ideaIds: snapshots.map((IdeathonIdeaSnapshot s) => s.ideaId).toList(growable: false),
      batch: batch,
    );
    await batch.commit();

    await _assignJudges(
      orgId: orgId,
      actorUserId: actor.userId,
      ideathonId: ideathon.ideathonId,
      ideas: snapshots.map((IdeathonIdeaSnapshot s) => eligibleById[s.ideaId]!).toList(),
      judgeIds: ideathon.judgeIds,
    );

    return ideathon.ideathonId;
  }

  static Future<void> _assignJudges({
    required String orgId,
    required String actorUserId,
    required String ideathonId,
    required List<IdeaModel> ideas,
    required List<String> judgeIds,
  }) async {
    if (ideas.isEmpty || judgeIds.isEmpty) return;

    final List<UserModel> judges = <UserModel>[];
    for (final String judgeId in judgeIds) {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(FirestoreUtils.hkzUsers).doc(judgeId).get();
      if (!doc.exists || doc.data() == null) continue;
      judges.add(UserModel.fromMap(doc.data()!).copyWith(userId: doc.id));
    }
    if (judges.isEmpty) return;

    final Map<String, TeamModel> teamsById = <String, TeamModel>{};
    for (final IdeaModel idea in ideas) {
      final String teamId = idea.teamId.trim();
      if (teamId.isEmpty || teamsById.containsKey(teamId)) continue;
      final DocumentSnapshot<Map<String, dynamic>> teamDoc =
          await _db.collection(FirestoreUtils.hkzTeams).doc(teamId).get();
      if (teamDoc.exists && teamDoc.data() != null) {
        teamsById[teamId] = TeamModel.fromMap(teamDoc.id, teamDoc.data()!);
      }
    }

    final CollectionReference<Map<String, dynamic>> col =
        _db.collection(FirestoreUtils.hkzEvaluationAssignments);
    final WriteBatch batch = _db.batch();
    final DateTime now = DateTime.now();
    for (final IdeaModel idea in ideas) {
      final TeamModel? team = teamsById[idea.teamId.trim()];
      for (final UserModel judge in judges) {
        final EvaluationAssignmentConflict conflict = EvaluationAssignmentService.validateConflict(
          judge: judge,
          idea: idea,
          team: team,
        );
        if (conflict.isConflict) continue;
        final DocumentReference<Map<String, dynamic>> ref = col.doc();
        final EvaluationAssignmentModel assignment = EvaluationAssignmentModel(
          assignmentId: ref.id,
          orgId: orgId,
          problemId: idea.problemId,
          ideaId: idea.ideaId,
          judgeId: judge.userId,
          status: EvaluationAssignmentStatus.active,
          assignedBy: actorUserId,
          assignedAt: now,
          updatedAt: now,
          ideathonId: ideathonId,
        );
        batch.set(ref, assignment.toMap());
      }
    }
    await batch.commit();
  }

  static Future<IdeathonModel?> fetchById(String ideathonId) async {
    final String id = ideathonId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeathons).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdeathonModel.fromMap(doc.id, doc.data()!);
  }

  static Future<void> updateStatus(String ideathonId, IdeathonStatus status) async {
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(ideathonId.trim()).update(<String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
