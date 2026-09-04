import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/evaluation_criterion.dart';
import '../../evaluations/services/evaluation_template_helpers.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../idea/models/idea_model.dart';
import '../../organization/models/department_model.dart';
import '../../payment/models/payment_model.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_participation.dart';
import '../models/ideathon_status.dart';
import '../models/ideathon_type.dart';
import 'ideathon_participation_service.dart';
import 'ideathon_settings_service.dart';
import 'ideathon_team_eligibility.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class CreateIdeathonInput {
  const CreateIdeathonInput({
    required this.name,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.judgeIds,
    required this.coordinatorIds,
    required this.evaluationTemplateId,
    this.problemId = '',
    this.ideathonType = IdeathonType.internal,
  });

  final String name;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<String> judgeIds;
  final List<String> coordinatorIds;
  final String evaluationTemplateId;
  /// Optional — not required for creation; does not limit the Ideathon to one Problem.
  final String problemId;
  final IdeathonType ideathonType;
}

abstract final class IdeathonService {
  IdeathonService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<String> createIdeathon({
    required UserModel actor,
    required CreateIdeathonInput input,
  }) async {
    if (!RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(actor.role))) {
      throw StateError('Only department admins can create Ideathons.');
    }
    final String orgId = actor.orgId.trim();
    final String dept = actor.departmentCode.trim().toUpperCase();
    if (orgId.isEmpty) throw StateError('Organization is required.');
    if (input.name.trim().isEmpty) throw StateError('Event name is required.');
    if (!input.endDateTime.isAfter(input.startDateTime)) {
      throw StateError('End date/time must be after start date/time.');
    }
    if (input.judgeIds.isEmpty) throw StateError('Assign at least one judge.');
    if (input.coordinatorIds.isEmpty) throw StateError('Assign at least one coordinator.');

    await IdeathonSettingsService.ensureLoaded(orgId: orgId);

    final String templateId = input.evaluationTemplateId.trim().isNotEmpty
        ? input.evaluationTemplateId.trim()
        : IdeathonSettingsService.ideathonEvaluationTemplateId(orgId);
    final resolved = EvaluationTemplatesService.resolveTemplate(templateId);
    if (resolved.templateId.trim().isEmpty) {
      throw StateError('Select an evaluation template.');
    }

    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestoreUtils.hkzIdeathons).doc();
    final IdeathonModel ideathon = IdeathonModel(
      ideathonId: ref.id,
      orgId: orgId,
      ideathonType: input.ideathonType,
      name: input.name.trim(),
      description: input.description.trim(),
      departmentId: dept,
      startDateTime: input.startDateTime,
      endDateTime: input.endDateTime,
      status: IdeathonStatus.scheduled,
      judgeIds: input.judgeIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(),
      coordinatorIds:
          input.coordinatorIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(),
      ideas: const <IdeathonIdeaSnapshot>[],
      evaluationTemplateId: resolved.templateId,
      evaluationCriteria: const <EvaluationCriterion>[],
      problemId: input.problemId.trim(),
      createdBy: actor.userId,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(ideathon.toMap());
    return ideathon.ideathonId;
  }

  /// True when at least one judge score exists for this Ideathon.
  static Future<bool> hasEvaluationStarted(String ideathonId) async {
    return (await firstEvaluationAt(ideathonId)) != null;
  }

  static Future<DateTime?> firstEvaluationAt(String ideathonId) async {
    final String id = ideathonId.trim();
    if (id.isEmpty) return null;
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzScores)
        .where('ideathonId', isEqualTo: id)
        .get();
    DateTime? first;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final DateTime at = (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (first == null || at.isBefore(first)) first = at;
    }
    return first;
  }

  static Future<void> updateIdeathon({
    required UserModel actor,
    required String ideathonId,
    required CreateIdeathonInput input,
  }) async {
    if (!RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(actor.role))) {
      throw StateError('Only department admins can edit Ideathons.');
    }
    final String id = ideathonId.trim();
    if (id.isEmpty) throw StateError('Ideathon is required.');

    final IdeathonModel? existing = await fetchById(id);
    if (existing == null) throw StateError('Ideathon not found.');
    if (existing.orgId.trim() != actor.orgId.trim()) {
      throw StateError('You can only edit Ideathons in your organization.');
    }
    if (isEventCompleted(existing)) {
      throw StateError('This event is completed and can no longer be edited.');
    }
    if (await hasEvaluationStarted(id)) {
      throw StateError(
        'Event configuration is locked because evaluation has started. Submitted scores cannot be changed.',
      );
    }

    if (input.name.trim().isEmpty) throw StateError('Event name is required.');
    if (!input.endDateTime.isAfter(input.startDateTime)) {
      throw StateError('End date/time must be after start date/time.');
    }
    if (input.judgeIds.isEmpty) throw StateError('Assign at least one judge.');
    if (input.coordinatorIds.isEmpty) throw StateError('Assign at least one coordinator.');

    await IdeathonSettingsService.ensureLoaded(orgId: existing.orgId);

    final String templateId = input.evaluationTemplateId.trim().isNotEmpty
        ? input.evaluationTemplateId.trim()
        : IdeathonSettingsService.ideathonEvaluationTemplateId(existing.orgId);
    final resolved = EvaluationTemplatesService.resolveTemplate(templateId);
    if (resolved.templateId.trim().isEmpty) {
      throw StateError('Select an evaluation template.');
    }

    final List<String> nextJudges =
        input.judgeIds.map((String j) => j.trim()).where((String j) => j.isNotEmpty).toList();
    final Set<String> removedJudges = existing.judgeIds
        .map((String j) => j.trim())
        .where((String j) => j.isNotEmpty)
        .toSet()
        .difference(nextJudges.toSet());

    final DateTime now = DateTime.now();
    final IdeathonModel updated = IdeathonModel(
      ideathonId: existing.ideathonId,
      orgId: existing.orgId,
      ideathonType: input.ideathonType,
      name: input.name.trim(),
      description: input.description.trim(),
      departmentId: existing.departmentId,
      startDateTime: input.startDateTime,
      endDateTime: input.endDateTime,
      status: existing.status,
      judgeIds: nextJudges,
      coordinatorIds:
          input.coordinatorIds.map((String c) => c.trim()).where((String c) => c.isNotEmpty).toList(),
      ideas: existing.ideas,
      evaluationTemplateId: resolved.templateId,
      evaluationCriteria: existing.evaluationCriteria,
      problemId: input.problemId.trim(),
      winnerIdeaId: existing.winnerIdeaId,
      runnerUpIdeaId: existing.runnerUpIdeaId,
      resultsReviewedAt: existing.resultsReviewedAt,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    await _db.collection(FirestoreUtils.hkzIdeathons).doc(id).set(updated.toMap());

    if (removedJudges.isNotEmpty) {
      await EvaluationAssignmentService.removeIdeathonAssignmentsMatching(
        ideathonId: id,
        judgeIds: removedJudges,
      );
    }
  }

  /// Locked once the event start time has passed, a score exists, or the event is completed.
  static bool isEvaluationTemplateLocked(
    IdeathonModel event, {
    bool evaluationStarted = false,
  }) {
    if (isEventCompleted(event)) return true;
    if (evaluationStarted) return true;
    return !DateTime.now().isBefore(event.startDateTime);
  }

  static String evaluationTemplateLockMessage(
    IdeathonModel event, {
    bool evaluationStarted = false,
  }) {
    if (isEventCompleted(event)) {
      return 'This event is completed. The evaluation template is locked.';
    }
    if (evaluationStarted) {
      return 'Evaluation has started. The template can no longer be changed.';
    }
    if (!DateTime.now().isBefore(event.startDateTime)) {
      return 'The event has started. The evaluation template is locked.';
    }
    return '';
  }

  static bool isEventCompleted(IdeathonModel event) =>
      event.status == IdeathonStatus.completed || event.status == IdeathonStatus.archived;

  static bool teamMayJoin(IdeathonModel event, TeamModel team) {
    final IdeathonTeamOrigin origin = team.orgId.trim() == event.orgId.trim()
        ? IdeathonTeamOrigin.host
        : IdeathonTeamOrigin.otherOrganisation;
    return IdeathonTeamEligibility.isOriginEligible(event.ideathonType, origin);
  }

  static Future<void> assertAcceptingParticipation(String eventId) async {
    final IdeathonModel? event = await fetchById(eventId);
    if (event == null) throw StateError('Event not found.');
    if (isEventCompleted(event)) {
      throw StateError('This event is completed. New ideas cannot join.');
    }
    if (!event.isAcceptingSubmissions) {
      throw StateError('The submission cutoff has passed for this event.');
    }
    if (await hasEvaluationStarted(event.ideathonId)) {
      throw StateError('Evaluation has started. New ideas cannot join this event.');
    }
  }

  /// Ideathons this team may still submit/pay for (cutoff, type, problem, org).
  static Future<List<IdeathonModel>> listOpenForTeam({
    required TeamModel team,
    String problemId = '',
  }) async {
    final String orgId = team.orgId.trim();
    if (orgId.isEmpty) return const <IdeathonModel>[];
    final CollectionReference<Map<String, dynamic>> col = _db.collection(FirestoreUtils.hkzIdeathons);
    final List<QuerySnapshot<Map<String, dynamic>>> snaps = await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      col.where('orgId', isEqualTo: orgId).get(),
      col.where('ideathonType', isEqualTo: IdeathonType.external.value).get(),
    ]);
    final Map<String, IdeathonModel> byId = <String, IdeathonModel>{};
    for (final QuerySnapshot<Map<String, dynamic>> snap in snaps) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        byId.putIfAbsent(doc.id, () => IdeathonModel.fromMap(doc.id, doc.data()));
      }
    }
    final String teamDept = DepartmentModel.resolveCode(team.departmentCode);
    final String problem = problemId.trim();
    final List<IdeathonModel> open = <IdeathonModel>[];
    for (final IdeathonModel event in byId.values) {
      if (!event.isAcceptingSubmissions) continue;
      if (!teamMayJoin(event, team)) continue;
      if (problem.isNotEmpty && !event.acceptsProblem(problem)) continue;
      final bool sameOrg = team.orgId.trim() == event.orgId.trim();
      final String eventDept = event.departmentId.trim().toUpperCase();
      if (sameOrg && eventDept.isNotEmpty && teamDept.isNotEmpty && eventDept != teamDept) continue;
      open.add(event);
    }
    open.sort((IdeathonModel a, IdeathonModel b) => a.startDateTime.compareTo(b.startDateTime));
    return open;
  }

  /// Persist the canonical idea payment scoped to the Idea's event.
  static Future<void> saveTeamLeaderEventPayment({
    required PaymentModel payment,
  }) async {
    final String ideaId = payment.ideaId.trim();
    if (ideaId.isEmpty) throw StateError('ideaId is required for payment.');
    final IdeathonParticipation? membership =
        await IdeathonParticipationService.fetchForIdea(ideaId);
    final String eventId = membership?.ideathonId.trim() ?? '';
    if (eventId.isEmpty) {
      throw StateError(
        'This idea is not associated with an event. Submit the idea with an event selected.',
      );
    }
    if (payment.ideathonId.trim().isNotEmpty && payment.ideathonId.trim() != eventId) {
      throw StateError('Payment must use the same event as the idea.');
    }
    await assertAcceptingParticipation(eventId);
    final IdeathonModel event = await _requireEvent(eventId);
    if (!event.acceptsProblem(payment.problemId)) {
      throw StateError('This idea is not eligible for its event.');
    }
    await FirestoreUtils.saveIdeaPayment(
      payment.copyWith(
        ideathonId: eventId,
        participationId: membership!.participationId,
      ),
    );
  }

  /// After coordinator verification, add the canonical idea to the event roster.
  static Future<void> registerConfirmedIdea({
    required String eventId,
    required IdeaModel idea,
    String teamName = '',
  }) async {
    await assertAcceptingParticipation(eventId);
    final IdeathonModel? event = await fetchById(eventId);
    if (event == null) throw StateError('Event not found.');
    final String ideaId = idea.ideaId.trim();
    if (ideaId.isEmpty) return;
    if (event.ideas.any((IdeathonIdeaSnapshot s) => s.ideaId.trim() == ideaId)) return;

    final IdeathonIdeaSnapshot snapshot = IdeathonIdeaSnapshot(
      ideaId: ideaId,
      ideaTitle: idea.ideaTitle.trim().isEmpty ? ideaId : idea.ideaTitle.trim(),
      problemTitle: idea.problemTitle.trim().isEmpty ? '—' : idea.problemTitle.trim(),
      teamName: teamName.trim().isEmpty ? '—' : teamName.trim(),
      addedAt: DateTime.now(),
    );
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(event.ideathonId).update(<String, dynamic>{
      'ideas': <Map<String, dynamic>>[
        ...event.ideas.map((IdeathonIdeaSnapshot s) => s.toMap()),
        snapshot.toMap(),
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> confirmTeamLeaderPayment({
    required PaymentModel payment,
    required UserModel coordinator,
  }) async {
    final String eventId = payment.ideathonId.trim();
    if (eventId.isNotEmpty) {
      await assertAcceptingParticipation(eventId);
    }
    await FirestoreUtils.verifyIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: coordinator.userId,
    );
    if (eventId.isEmpty) return;
    final IdeaModel? idea = await _fetchIdea(payment.ideaId);
    if (idea == null) return;
    String teamName = '';
    final String teamId = idea.teamId.trim().isNotEmpty ? idea.teamId.trim() : payment.teamId.trim();
    if (teamId.isNotEmpty) {
      teamName = await _fetchTeamName(teamId);
    }
    await registerConfirmedIdea(eventId: eventId, idea: idea, teamName: teamName);
  }

  static Future<IdeaModel?> _fetchIdea(String ideaId) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdeaModel.fromMap(doc.id, doc.data()!);
  }

  static Future<String> _fetchTeamName(String teamId) async {
    final String id = teamId.trim();
    if (id.isEmpty) return '';
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzTeams).doc(id).get();
    if (!doc.exists || doc.data() == null) return '';
    return ((doc.data()!['teamName'] as String?) ?? '').trim();
  }

  static bool canManageEventOutcome(UserModel actor) =>
      RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(actor.role));

  static void _assertCanManageOutcome(UserModel actor, IdeathonModel event) {
    if (!canManageEventOutcome(actor)) {
      throw StateError('Only department admins can complete this event or select winners.');
    }
    if (event.orgId.trim() != actor.orgId.trim()) {
      throw StateError('You can only manage events in your organization.');
    }
  }

  static Future<IdeathonModel> _requireEvent(String ideathonId) async {
    final IdeathonModel? event = await fetchById(ideathonId);
    if (event == null) throw StateError('Event not found.');
    return event;
  }

  static Future<void> markResultsReviewed({
    required UserModel actor,
    required String ideathonId,
  }) async {
    final IdeathonModel event = await _requireEvent(ideathonId);
    _assertCanManageOutcome(actor, event);
    if (isEventCompleted(event)) return;
    if (event.resultsReviewedAt != null) return;
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(event.ideathonId).update(<String, dynamic>{
      'resultsReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> selectWinners({
    required UserModel actor,
    required String ideathonId,
    required String winnerIdeaId,
    String runnerUpIdeaId = '',
  }) async {
    final IdeathonModel event = await _requireEvent(ideathonId);
    _assertCanManageOutcome(actor, event);
    if (isEventCompleted(event)) {
      throw StateError('This event is completed. Winner selection is locked.');
    }
    final String winner = winnerIdeaId.trim();
    final String runner = runnerUpIdeaId.trim();
    if (winner.isEmpty) throw StateError('Select a winner.');
    final Set<String> ideaIds = event.ideas
        .map((IdeathonIdeaSnapshot s) => s.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    if (!ideaIds.contains(winner)) {
      throw StateError('Winner must be an idea registered on this event.');
    }
    if (runner.isNotEmpty && !ideaIds.contains(runner)) {
      throw StateError('Runner-up must be an idea registered on this event.');
    }
    if (runner.isNotEmpty && runner == winner) {
      throw StateError('Winner and runner-up must be different ideas.');
    }
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(event.ideathonId).update(<String, dynamic>{
      'winnerIdeaId': winner,
      'runnerUpIdeaId': runner,
      if (event.resultsReviewedAt == null) 'resultsReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> completeEvent({
    required UserModel actor,
    required String ideathonId,
  }) async {
    final IdeathonModel event = await _requireEvent(ideathonId);
    _assertCanManageOutcome(actor, event);
    if (isEventCompleted(event)) return;
    if (event.winnerIdeaId.trim().isEmpty) {
      throw StateError('Select winners before completing the event.');
    }
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(event.ideathonId).update(<String, dynamic>{
      'status': IdeathonStatus.completed.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markInProgressIfNeeded(String ideathonId) async {
    final IdeathonModel? event = await fetchById(ideathonId);
    if (event == null) return;
    if (event.status != IdeathonStatus.scheduled) return;
    await updateStatus(event.ideathonId, IdeathonStatus.inProgress);
  }

  /// Persists the event-scoped rubric. Does not mutate the org template.
  static Future<void> updateEvaluationCriteria({
    required UserModel actor,
    required String ideathonId,
    required List<EvaluationCriterion> criteria,
  }) async {
    if (!RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(actor.role))) {
      throw StateError('Only department admins can update the evaluation template.');
    }
    final String id = ideathonId.trim();
    if (id.isEmpty) throw StateError('Event is required.');

    final IdeathonModel? existing = await fetchById(id);
    if (existing == null) throw StateError('Event not found.');
    if (existing.orgId.trim() != actor.orgId.trim()) {
      throw StateError('You can only edit events in your organization.');
    }

    final bool evalStarted = await hasEvaluationStarted(id);
    if (isEventCompleted(existing)) {
      throw StateError('This event is completed. The evaluation template is locked.');
    }
    if (isEvaluationTemplateLocked(existing, evaluationStarted: evalStarted)) {
      throw StateError(
        evaluationTemplateLockMessage(existing, evaluationStarted: evalStarted),
      );
    }

    final String? weightErr = EvaluationTemplateHelpers.validateWeights(criteria);
    if (weightErr != null) throw StateError(weightErr);

    await _db.collection(FirestoreUtils.hkzIdeathons).doc(id).update(<String, dynamic>{
      'evaluationCriteria':
          criteria.map((EvaluationCriterion c) => c.toMap()).toList(growable: false),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
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
