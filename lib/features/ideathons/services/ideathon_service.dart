import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/evaluation_criterion.dart';
import '../../evaluations/services/evaluation_template_helpers.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../idea/models/idea_model.dart';
import '../../user/models/user_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../models/ideathon_type.dart';
import 'ideathon_participation_service.dart';
import 'ideathon_settings_service.dart';
import 'ideathon_team_eligibility.dart';

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
    this.ideathonType = IdeathonType.internal,
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
  final IdeathonType ideathonType;
}

abstract final class IdeathonService {
  IdeathonService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submitted ideas with a **verified** idea payment — eligible for Ideathon create.
  ///
  /// [ideathonType] filters teams: Internal = host-organisation only (no mixed
  /// members); External = host, other-organisation, and mixed teams.
  static Future<List<IdeathonEligibleIdea>> fetchEligibleIdeasForIdeathon({
    required String orgId,
    IdeathonType ideathonType = IdeathonType.internal,
  }) async {
    final List<IdeathonEligibleIdea> catalog =
        await IdeathonTeamEligibility.loadPaidIdeas(hostOrgId: orgId);
    return IdeathonTeamEligibility.filterForType(catalog, ideathonType);
  }

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
    if (input.ideaIds.isEmpty) throw StateError('Select at least one paid idea.');
    if (input.judgeIds.isEmpty) throw StateError('Assign at least one judge.');

    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final int minimumIdeas = IdeathonSettingsService.minimumIdeasForIdeathon(orgId);
    if (input.ideaIds.length < minimumIdeas) {
      throw StateError(
        '${input.ideaIds.length} of $minimumIdeas minimum paid ideas selected.',
      );
    }

    final String templateId = input.evaluationTemplateId.trim().isNotEmpty
        ? input.evaluationTemplateId.trim()
        : IdeathonSettingsService.ideathonEvaluationTemplateId(orgId);
    final resolved = EvaluationTemplatesService.resolveTemplate(templateId);
    if (resolved.templateId.trim().isEmpty) {
      throw StateError('Select an evaluation template.');
    }

    final List<IdeathonEligibleIdea> eligible = await fetchEligibleIdeasForIdeathon(
      orgId: orgId,
      ideathonType: input.ideathonType,
    );
    final Map<String, IdeathonEligibleIdea> eligibleById = <String, IdeathonEligibleIdea>{
      for (final IdeathonEligibleIdea row in eligible) row.idea.ideaId: row,
    };

    final List<IdeathonIdeaSnapshot> snapshots = <IdeathonIdeaSnapshot>[];
    for (final String rawId in input.ideaIds) {
      final String ideaId = rawId.trim();
      final IdeathonEligibleIdea? row = eligibleById[ideaId];
      if (row == null) {
        throw StateError(
          'Only paid ideas from teams eligible for this Ideathon type can be added.',
        );
      }
      final IdeaModel idea = row.idea;
      final String teamName = row.teamName;
      snapshots.add(
        IdeathonIdeaSnapshot(
          ideaId: idea.ideaId,
          ideaTitle: idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim(),
          problemTitle: idea.problemTitle.trim().isEmpty ? '—' : idea.problemTitle.trim(),
          teamName: teamName.isEmpty ? '—' : teamName,
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
      ideas: snapshots,
      evaluationTemplateId: resolved.templateId,
      evaluationCriteria: const <EvaluationCriterion>[],
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
    if (input.ideaIds.isEmpty) throw StateError('Select at least one paid idea.');
    if (input.judgeIds.isEmpty) throw StateError('Assign at least one judge.');

    await IdeathonSettingsService.ensureLoaded(orgId: existing.orgId);
    final int minimumIdeas = IdeathonSettingsService.minimumIdeasForIdeathon(existing.orgId);
    if (input.ideaIds.length < minimumIdeas) {
      throw StateError(
        '${input.ideaIds.length} of $minimumIdeas minimum paid ideas selected.',
      );
    }

    final String templateId = input.evaluationTemplateId.trim().isNotEmpty
        ? input.evaluationTemplateId.trim()
        : IdeathonSettingsService.ideathonEvaluationTemplateId(existing.orgId);
    final resolved = EvaluationTemplatesService.resolveTemplate(templateId);
    if (resolved.templateId.trim().isEmpty) {
      throw StateError('Select an evaluation template.');
    }

    final List<IdeathonEligibleIdea> eligible = await fetchEligibleIdeasForIdeathon(
      orgId: existing.orgId,
      ideathonType: input.ideathonType,
    );
    final Map<String, IdeathonEligibleIdea> eligibleById = <String, IdeathonEligibleIdea>{
      for (final IdeathonEligibleIdea row in eligible) row.idea.ideaId: row,
    };
    final Map<String, IdeathonIdeaSnapshot> previousById = <String, IdeathonIdeaSnapshot>{
      for (final IdeathonIdeaSnapshot s in existing.ideas)
        if (s.ideaId.trim().isNotEmpty) s.ideaId.trim(): s,
    };

    final List<IdeathonIdeaSnapshot> snapshots = <IdeathonIdeaSnapshot>[];
    for (final String rawId in input.ideaIds) {
      final String ideaId = rawId.trim();
      final IdeathonEligibleIdea? row = eligibleById[ideaId];
      final IdeathonIdeaSnapshot? previous = previousById[ideaId];
      if (row != null) {
        final IdeaModel idea = row.idea;
        snapshots.add(
          IdeathonIdeaSnapshot(
            ideaId: idea.ideaId,
            ideaTitle: idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim(),
            problemTitle: idea.problemTitle.trim().isEmpty ? '—' : idea.problemTitle.trim(),
            teamName: row.teamName.isEmpty ? '—' : row.teamName,
            addedAt: previous?.addedAt ?? DateTime.now(),
          ),
        );
      } else if (previous != null) {
        snapshots.add(previous);
      } else {
        throw StateError(
          'Only paid ideas from teams eligible for this Ideathon type can be added.',
        );
      }
    }

    final Set<String> nextIdeaIds = snapshots.map((IdeathonIdeaSnapshot s) => s.ideaId.trim()).toSet();
    final Set<String> prevIdeaIds = previousById.keys.toSet();
    final Set<String> addedIdeas = nextIdeaIds.difference(prevIdeaIds);
    final Set<String> removedIdeas = prevIdeaIds.difference(nextIdeaIds);

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
      ideas: snapshots,
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

    final WriteBatch batch = _db.batch();
    batch.set(_db.collection(FirestoreUtils.hkzIdeathons).doc(id), updated.toMap());
    if (addedIdeas.isNotEmpty) {
      await IdeathonParticipationService.createForIdeathon(
        orgId: existing.orgId,
        ideathonId: id,
        ideaIds: addedIdeas.toList(growable: false),
        batch: batch,
      );
    }
    await batch.commit();

    if (removedIdeas.isNotEmpty) {
      await IdeathonParticipationService.deleteForIdeathonIdeas(ideathonId: id, ideaIds: removedIdeas);
      await EvaluationAssignmentService.removeIdeathonAssignmentsMatching(
        ideathonId: id,
        ideaIds: removedIdeas,
      );
    }
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
