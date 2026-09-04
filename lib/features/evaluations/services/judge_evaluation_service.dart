import 'package:cloud_firestore/cloud_firestore.dart';

import '../assignments/models/evaluation_assignment_model.dart';
import '../assignments/services/evaluation_assignment_service.dart';
import '../models/evaluation_template.dart';
import '../models/score_model.dart';
import 'evaluation_aggregation_sync_service.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../../ideathons/models/ideathon_status.dart';
import '../../ideathons/services/ideathon_evaluation_sync_service.dart';
import '../../ideathons/services/ideathon_service.dart';
import '../../ideathons/services/ideathon_status_helpers.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import '../../user/models/enums/user_role.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../problems/models/problem_model.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import 'judge_evaluation_feedback_codec.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Centralized judge-scoped evaluation queries and persistence.
abstract final class JudgeEvaluationService {
  static FirebaseFirestore get _db => HackzFirebase.current.firestore;
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static const Duration _ttl = Duration(seconds: 45);

  static String _key(UserModel judge, {String ideathonId = ''}) =>
      '${judge.userId.trim()}|${judge.orgId.trim()}|${ideathonId.trim()}';

  static void clearCache() => _cache.clear();

  static bool _isJudge(UserModel user) => UserRole.fromCode(user.role) == UserRole.judge;

  /// Persists a template-driven evaluation.
  ///
  /// The overall score (`ScoreModel.score`) is **always** the
  /// weight-normalized average computed by [template.computeOverall] — judges
  /// can no longer override it manually. Per-criterion answers live on
  /// [ScoreModel.criteriaScores]; per-criterion comments (only for criteria
  /// with `commentsEnabled: true`) live on [ScoreModel.criteriaComments];
  /// overall remarks live on [ScoreModel.feedback].
  ///
  /// When [ideathonId] is set, the score is event-scoped and the template must
  /// be the Ideathon's configured template (enforced by the caller).
  static Future<void> saveEvaluation({
    required UserModel judge,
    required IdeaModel idea,
    required EvaluationTemplate template,
    required Map<String, double> criteriaScores,
    Map<String, String> criteriaComments = const <String, String>{},
    String overallFeedback = '',
    String ideathonId = '',
  }) async {
    if (!_isJudge(judge)) {
      throw StateError('Only judges can save evaluations.');
    }
    if (idea.status == IdeaStatus.draft) {
      throw StateError('Idea is pending payment verification.');
    }
    final String trimmedIdeathonId = ideathonId.trim();
    if (trimmedIdeathonId.isNotEmpty) {
      final IdeathonModel? event = await IdeathonService.fetchById(trimmedIdeathonId);
      if (event != null && IdeathonService.isEventCompleted(event)) {
        throw StateError('This event is completed. Evaluations are locked.');
      }
    }
    final List<EvaluationAssignmentModel> assignments =
        await EvaluationAssignmentService.listAssignmentsForJudge(
      orgId: judge.orgId,
      judgeId: judge.userId,
      ideathonId: trimmedIdeathonId,
    );
    final bool assigned = assignments.any((EvaluationAssignmentModel a) {
      if (a.ideaId.trim() != idea.ideaId.trim()) return false;
      if (trimmedIdeathonId.isEmpty) return !a.isIdeathonAssignment;
      return a.ideathonId.trim() == trimmedIdeathonId;
    });
    if (!assigned) {
      throw StateError(
        trimmedIdeathonId.isEmpty
            ? 'Idea is not assigned to this judge.'
            : 'Idea is not assigned to this judge for this Ideathon.',
      );
    }
    if (template.criteria.isEmpty) {
      throw StateError('Evaluation template has no criteria.');
    }

    // Filter the maps down to the template's own criterion ids and drop
    // out-of-range values. Comments are kept only for criteria that allow them.
    final Set<String> allowedIds = <String>{
      for (final c in template.criteria) c.criterionId,
    };
    final Set<String> commentEnabledIds = <String>{
      for (final c in template.criteria)
        if (c.commentsEnabled) c.criterionId,
    };
    final Map<String, double> cleanedScores = <String, double>{};
    for (final entry in criteriaScores.entries) {
      if (!allowedIds.contains(entry.key)) continue;
      cleanedScores[entry.key] = entry.value;
    }
    final Map<String, String> cleanedComments = <String, String>{};
    for (final entry in criteriaComments.entries) {
      if (!commentEnabledIds.contains(entry.key)) continue;
      final String trimmed = entry.value.trim();
      if (trimmed.isEmpty) continue;
      cleanedComments[entry.key] = trimmed;
    }

    final double overall = template.computeOverall(cleanedScores);
    final double normalized = template.scoringScale <= 0
        ? 0
        : ((overall / template.scoringScale) * 100).clamp(0.0, 100.0);
    final col = _db.collection(FirestoreUtils.hkzScores);
    Query<Map<String, dynamic>> existingQuery = col
        .where('ideaId', isEqualTo: idea.ideaId)
        .where('judgeId', isEqualTo: judge.userId);
    if (trimmedIdeathonId.isNotEmpty) {
      existingQuery = existingQuery.where('ideathonId', isEqualTo: trimmedIdeathonId);
    }
    final existing = await existingQuery.limit(1).get();
    // Avoid updating a score from another Ideathon when saving without event id.
    DocumentSnapshot<Map<String, dynamic>>? existingDoc;
    if (existing.docs.isNotEmpty) {
      if (trimmedIdeathonId.isEmpty) {
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in existing.docs) {
          final ScoreModel s = ScoreModel.fromMap(doc.id, doc.data());
          if (s.ideathonId.trim().isEmpty) {
            existingDoc = doc;
            break;
          }
        }
      } else {
        existingDoc = existing.docs.first;
      }
    }
    final payload = ScoreModel(
      scoreId: existingDoc == null ? '' : existingDoc.id,
      ideaId: idea.ideaId,
      judgeId: judge.userId,
      score: overall,
      feedback: overallFeedback.trim(),
      createdAt: DateTime.now(),
      orgId: judge.orgId,
      departmentCode: idea.problemDepartmentCode,
      templateId: template.templateId,
      criteriaScores: cleanedScores,
      criteriaComments: cleanedComments,
      rawScore: overall,
      normalizedScore: normalized,
      ideathonId: trimmedIdeathonId,
    );
    if (existingDoc == null) {
      final doc = col.doc();
      await doc.set(payload.copyWith(scoreId: doc.id).toMap());
    } else {
      await col.doc(existingDoc.id).update(payload.toMap());
    }
    if (trimmedIdeathonId.isNotEmpty) {
      await IdeathonEvaluationSyncService.syncIdeathonIdea(
        ideathonId: trimmedIdeathonId,
        ideaId: idea.ideaId,
        orgId: judge.orgId,
      );
      await IdeathonEvaluationSyncService.syncIdeathonCompletion(trimmedIdeathonId);
    } else {
      await EvaluationAggregationSyncService.syncIdea(
        ideaId: idea.ideaId,
        orgId: judge.orgId,
      );
    }
    clearCache();
  }

  static Future<JudgeEvaluationWorkspaceVm> loadWorkspace(
    UserModel judge, {
    String ideathonId = '',
  }) async {
    if (!_isJudge(judge)) {
      return const JudgeEvaluationWorkspaceVm.empty();
    }
    final String eventId = ideathonId.trim();
    final key = _key(judge, ideathonId: eventId);
    final now = DateTime.now();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.at) < _ttl) {
      return hit.vm;
    }

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzAttachments).where('orgId', isEqualTo: judge.orgId).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzIdeathons).where('orgId', isEqualTo: judge.orgId).get(),
    ]);

    final ideaDocs = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scoreDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final teamDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final attachmentDocs = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final paymentDocs = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;
    final ideathonDocs = (results[6] as QuerySnapshot<Map<String, dynamic>>).docs;

    final teamsById = <String, TeamModel>{
      for (final d in teamDocs) d.id: TeamModel.fromMap(d.id, d.data()),
    };
    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
    };
    final Map<String, IdeathonModel> ideathonsById = <String, IdeathonModel>{
      for (final d in ideathonDocs) d.id: IdeathonModel.fromMap(d.id, d.data()),
    };

    final attachmentCountByIdeaId = <String, int>{};
    for (final d in attachmentDocs) {
      final data = d.data();
      if ((data['entityType'] as String?)?.trim() != AttachmentEntityType.idea.value) continue;
      final eid = ((data['entityId'] as String?) ?? '').trim();
      if (eid.isEmpty) continue;
      attachmentCountByIdeaId[eid] = (attachmentCountByIdeaId[eid] ?? 0) + 1;
    }

    final paymentByIdeaId = <String, PaymentModel>{};
    for (final d in paymentDocs) {
      final p = PaymentModel.fromMap(d.id, d.data());
      paymentByIdeaId[p.ideaId] = p;
    }

    final List<EvaluationAssignmentModel> assignments =
        await EvaluationAssignmentService.listAssignmentsForJudge(
      orgId: judge.orgId,
      judgeId: judge.userId,
      ideathonId: eventId,
    );
    if (assignments.isEmpty) {
      final empty = const JudgeEvaluationWorkspaceVm.empty();
      _cache[key] = _CacheEntry(at: now, vm: empty);
      return empty;
    }

    final Set<String> assignedIdeaIds = assignments
        .map((EvaluationAssignmentModel a) => a.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    final Map<String, IdeaModel> ideasById = <String, IdeaModel>{
      for (final d in ideaDocs)
        if (assignedIdeaIds.contains(d.id)) d.id: IdeaModel.fromMap(d.id, d.data()),
    };

    final Map<String, int> assignedJudgeCountByIdeaId = <String, int>{};
    final Set<String> eventIds = assignments
        .map((EvaluationAssignmentModel a) => a.ideathonId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    if (eventIds.isEmpty) {
      final Map<String, List<String>> judges =
          await EvaluationAssignmentService.assignedJudgesByIdea(
        orgId: judge.orgId,
        ideaIds: assignedIdeaIds,
      );
      for (final MapEntry<String, List<String>> e in judges.entries) {
        assignedJudgeCountByIdeaId[e.key] = e.value.length;
      }
    } else {
      for (final String eid in eventIds) {
        final Map<String, List<String>> judges =
            await EvaluationAssignmentService.assignedJudgesByIdeaForIdeathon(
          ideathonId: eid,
          ideaIds: assignedIdeaIds,
        );
        for (final MapEntry<String, List<String>> e in judges.entries) {
          assignedJudgeCountByIdeaId[e.key] = e.value.length;
        }
      }
    }

    final List<ScoreModel> scoresByJudge = scoreDocs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => s.judgeId == judge.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    ScoreModel? scoreFor(String ideaId, String assignmentIdeathonId) {
      for (final ScoreModel s in scoresByJudge) {
        if (s.ideaId.trim() != ideaId) continue;
        if (s.ideathonId.trim() == assignmentIdeathonId.trim()) return s;
      }
      return null;
    }

    bool judgeMayEvaluate(IdeaModel idea) {
      if (idea.status == IdeaStatus.draft) return false;
      final pay = paymentByIdeaId[idea.ideaId];
      if (pay != null &&
          pay.status != PaymentRecordStatus.verified &&
          pay.status != PaymentRecordStatus.rejected) {
        return false;
      }
      return true;
    }

    final List<JudgeEvaluationPendingRow> pendingRows = <JudgeEvaluationPendingRow>[];
    final List<JudgeEvaluationEvaluatedRow> evaluatedRows = <JudgeEvaluationEvaluatedRow>[];
    final List<JudgeEvaluationFeedbackRow> feedbackRows = <JudgeEvaluationFeedbackRow>[];
    final List<ScoreModel> scopedScores = <ScoreModel>[];

    for (final EvaluationAssignmentModel assignment in assignments) {
      final String ideaId = assignment.ideaId.trim();
      final IdeaModel? idea = ideasById[ideaId];
      if (idea == null) continue;
      final String aIdeathonId = assignment.ideathonId.trim();
      if (aIdeathonId.isEmpty) continue;
      if (eventId.isNotEmpty && aIdeathonId != eventId) continue;

      final IdeathonModel? ideathon = ideathonsById[aIdeathonId];
      final String ideathonName = ideathon?.name.trim().isNotEmpty == true
          ? ideathon!.name.trim()
          : (aIdeathonId.isEmpty ? '' : aIdeathonId);
      final String templateId = ideathon?.evaluationTemplateId.trim() ?? '';
      final String schedule = ideathon == null
          ? ''
          : IdeathonStatusHelpers.scheduleLabel(ideathon.startDateTime, ideathon.endDateTime);

      final ScoreModel? score = scoreFor(ideaId, aIdeathonId);
      if (score != null) {
        scopedScores.add(score);
        evaluatedRows.add(
          _buildEvaluatedRow(
            idea,
            teamsById,
            problemsById,
            score,
            assignment.assignmentId,
            assignedJudgeCountByIdeaId[ideaId] ?? 0,
            ideathonId: aIdeathonId,
            ideathonName: ideathonName,
            evaluationTemplateId: score.templateId.trim().isNotEmpty
                ? score.templateId
                : templateId,
            ideathonSchedule: schedule,
            eventStatus: ideathon?.status,
            eventStartAt: ideathon?.startDateTime,
          ),
        );
        final String excerpt = JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback);
        final bool hasStructured = score.hasStructuredCriteria ||
            JudgeEvaluationFeedbackCodec.tryDecode(score.feedback) != null;
        feedbackRows.add(
          JudgeEvaluationFeedbackRow(
            ideaId: score.ideaId,
            ideaTitle: _ideaTitle(idea),
            evaluatedAt: score.createdAt,
            overallScore: score.score,
            remarksExcerpt: excerpt.isEmpty
                ? (hasStructured ? 'Criteria scores recorded' : '—')
                : (excerpt.length > 160 ? '${excerpt.substring(0, 157)}…' : excerpt),
            hasStructuredCriteria: hasStructured,
            ideathonId: aIdeathonId,
            ideathonName: ideathonName,
            ideathonSchedule: schedule,
            eventStatus: ideathon?.status,
            problemTitle: (problemsById[idea.problemId]?.title ?? idea.problemTitle).trim().isEmpty
                ? idea.problemId
                : (problemsById[idea.problemId]?.title ?? idea.problemTitle).trim(),
            teamName: (teamsById[idea.teamId]?.teamName ?? '').trim().isEmpty
                ? idea.teamId
                : teamsById[idea.teamId]!.teamName.trim(),
            problemId: idea.problemId,
            teamId: idea.teamId,
            scoreId: score.scoreId,
            idea: idea,
            latestScore: score,
            evaluationTemplateId: score.templateId.trim().isNotEmpty ? score.templateId : templateId,
          ),
        );
      } else if (judgeMayEvaluate(idea)) {
        pendingRows.add(
          _buildPendingRow(
            idea,
            teamsById,
            problemsById,
            attachmentCountByIdeaId,
            assignment.assignmentId,
            assignedJudgeCountByIdeaId[ideaId] ?? 0,
            ideathonId: aIdeathonId,
            ideathonName: ideathonName,
            evaluationTemplateId: templateId,
            ideathonSchedule: schedule,
            eventStatus: ideathon?.status,
            eventStartAt: ideathon?.startDateTime,
          ),
        );
      }
    }

    pendingRows.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    evaluatedRows.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));
    feedbackRows.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));

    final evaluatedCount = evaluatedRows.length;
    final pendingCount = pendingRows.length;
    final total = evaluatedCount + pendingCount;
    final completionPct = total == 0 ? 0.0 : (evaluatedCount / total) * 100.0;
    final avgScore = scopedScores.isEmpty
        ? null
        : scopedScores.map((e) => e.score).reduce((a, b) => a + b) / scopedScores.length;

    final Map<String, int> pendingCountByEvent = <String, int>{};
    for (final JudgeEvaluationPendingRow row in pendingRows) {
      final String id = row.ideathonId.trim();
      pendingCountByEvent[id] = (pendingCountByEvent[id] ?? 0) + 1;
    }
    final Map<String, int> evaluatedCountByEvent = <String, int>{};
    for (final JudgeEvaluationEvaluatedRow row in evaluatedRows) {
      final String id = row.ideathonId.trim();
      evaluatedCountByEvent[id] = (evaluatedCountByEvent[id] ?? 0) + 1;
    }

    String? contextName;
    String? contextTemplateId;
    String contextSchedule = '';
    if (eventId.isNotEmpty) {
      final IdeathonModel? focused = ideathonsById[eventId];
      contextName = focused?.name;
      contextTemplateId = focused?.evaluationTemplateId;
      if (focused != null) {
        contextSchedule = IdeathonStatusHelpers.scheduleLabel(focused.startDateTime, focused.endDateTime);
      }
    }

    final vm = JudgeEvaluationWorkspaceVm(
      pending: pendingRows,
      evaluated: evaluatedRows,
      feedback: feedbackRows,
      pendingCount: pendingCount,
      evaluatedCount: evaluatedCount,
      averageScore: avgScore,
      completionPercent: completionPct,
      ideathonId: eventId,
      ideathonName: contextName ?? '',
      evaluationTemplateId: contextTemplateId ?? '',
      ideathonSchedule: contextSchedule,
      pendingCountByEvent: pendingCountByEvent,
      evaluatedCountByEvent: evaluatedCountByEvent,
    );
    _cache[key] = _CacheEntry(at: now, vm: vm);
    return vm;
  }

  static JudgeEvaluationPendingRow _buildPendingRow(
    IdeaModel idea,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
    Map<String, int> attachmentCountByIdeaId,
    String assignmentId,
    int assignedJudgeCount, {
    String ideathonId = '',
    String ideathonName = '',
    String evaluationTemplateId = '',
    String ideathonSchedule = '',
    IdeathonStatus? eventStatus,
    DateTime? eventStartAt,
  }) {
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    final teamName = (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName.trim();
    final problemTitle = (problem?.title ?? idea.problemTitle).trim().isEmpty ? idea.problemId : (problem?.title ?? idea.problemTitle).trim();
    final category = (problem?.category ?? '').trim();
    final theme = (problem?.theme ?? '').trim();
    final fileCount = idea.files.where((e) => e.trim().isNotEmpty).length;
    final att = (attachmentCountByIdeaId[idea.ideaId] ?? 0) + fileCount;
    final due = idea.createdAt.add(const Duration(days: 14));
    final priority = idea.hasEvaluationAggregate ? JudgeEvaluationPriority.standard : JudgeEvaluationPriority.high;
    return JudgeEvaluationPendingRow(
      idea: idea,
      teamName: teamName,
      problemTitle: problemTitle,
      category: category,
      theme: theme,
      attachmentCount: att,
      submittedAt: idea.createdAt,
      reviewDueAt: due,
      priority: priority,
      assignmentId: assignmentId,
      assignedJudgeCount: assignedJudgeCount,
      ideathonId: ideathonId,
      ideathonName: ideathonName,
      evaluationTemplateId: evaluationTemplateId,
      ideathonSchedule: ideathonSchedule,
      eventStatus: eventStatus,
      eventStartAt: eventStartAt,
    );
  }

  static JudgeEvaluationEvaluatedRow _buildEvaluatedRow(
    IdeaModel idea,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
    ScoreModel score,
    String assignmentId,
    int assignedJudgeCount, {
    String ideathonId = '',
    String ideathonName = '',
    String evaluationTemplateId = '',
    String ideathonSchedule = '',
    IdeathonStatus? eventStatus,
    DateTime? eventStartAt,
  }) {
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    final teamName = (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName.trim();
    final problemTitle = (problem?.title ?? idea.problemTitle).trim().isEmpty ? idea.problemId : (problem?.title ?? idea.problemTitle).trim();
    final String overallRemarks = JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback);
    final bool hasFb = overallRemarks.isNotEmpty || score.criteriaComments.isNotEmpty;
    return JudgeEvaluationEvaluatedRow(
      idea: idea,
      teamName: teamName,
      problemTitle: problemTitle,
      score: score.score,
      evaluatedAt: score.createdAt,
      status: idea.status,
      hasFeedback: hasFb,
      latestScore: score,
      assignmentId: assignmentId,
      assignedJudgeCount: assignedJudgeCount,
      ideathonId: ideathonId,
      ideathonName: ideathonName,
      evaluationTemplateId: evaluationTemplateId,
      ideathonSchedule: ideathonSchedule,
      eventStatus: eventStatus,
      eventStartAt: eventStartAt,
    );
  }

  static String _ideaTitle(IdeaModel idea) {
    final title = idea.ideaTitle.trim();
    if (title.isNotEmpty) return title;
    if (idea.problemNumber.trim().isNotEmpty) return idea.problemNumber.trim();
    return idea.ideaId;
  }
}

class _CacheEntry {
  const _CacheEntry({required this.at, required this.vm});

  final DateTime at;
  final JudgeEvaluationWorkspaceVm vm;
}

enum JudgeEvaluationPriority { high, standard }

/// Judge-facing workflow status for an assigned idea row.
enum JudgeAssignmentRowStatus {
  assigned('Assigned'),
  inProgress('In Progress'),
  completed('Completed');

  const JudgeAssignmentRowStatus(this.label);
  final String label;
}

class JudgeEvaluationWorkspaceVm {
  const JudgeEvaluationWorkspaceVm({
    required this.pending,
    required this.evaluated,
    required this.feedback,
    required this.pendingCount,
    required this.evaluatedCount,
    required this.averageScore,
    required this.completionPercent,
    this.ideathonId = '',
    this.ideathonName = '',
    this.evaluationTemplateId = '',
    this.ideathonSchedule = '',
    this.pendingCountByEvent = const <String, int>{},
    this.evaluatedCountByEvent = const <String, int>{},
  });

  const JudgeEvaluationWorkspaceVm.empty()
      : pending = const <JudgeEvaluationPendingRow>[],
        evaluated = const <JudgeEvaluationEvaluatedRow>[],
        feedback = const <JudgeEvaluationFeedbackRow>[],
        pendingCount = 0,
        evaluatedCount = 0,
        averageScore = null,
        completionPercent = 0,
        ideathonId = '',
        ideathonName = '',
        evaluationTemplateId = '',
        ideathonSchedule = '',
        pendingCountByEvent = const <String, int>{},
        evaluatedCountByEvent = const <String, int>{};

  final List<JudgeEvaluationPendingRow> pending;
  final List<JudgeEvaluationEvaluatedRow> evaluated;
  final List<JudgeEvaluationFeedbackRow> feedback;
  final int pendingCount;
  final int evaluatedCount;
  final double? averageScore;
  final double completionPercent;
  final String ideathonId;
  final String ideathonName;
  final String evaluationTemplateId;
  final String ideathonSchedule;
  final Map<String, int> pendingCountByEvent;
  final Map<String, int> evaluatedCountByEvent;

  bool get isIdeathonScoped => ideathonId.trim().isNotEmpty;
}

class JudgeEvaluationPendingRow {
  const JudgeEvaluationPendingRow({
    required this.idea,
    required this.teamName,
    required this.problemTitle,
    required this.category,
    required this.theme,
    required this.attachmentCount,
    required this.submittedAt,
    required this.reviewDueAt,
    required this.priority,
    required this.assignmentId,
    required this.assignedJudgeCount,
    this.ideathonId = '',
    this.ideathonName = '',
    this.evaluationTemplateId = '',
    this.ideathonSchedule = '',
    this.eventStatus,
    this.eventStartAt,
  });

  final IdeaModel idea;
  final String teamName;
  final String problemTitle;
  final String category;
  final String theme;
  final int attachmentCount;
  final DateTime submittedAt;
  final DateTime reviewDueAt;
  final JudgeEvaluationPriority priority;
  final String assignmentId;
  final int assignedJudgeCount;
  final String ideathonId;
  final String ideathonName;
  final String evaluationTemplateId;
  final String ideathonSchedule;
  final IdeathonStatus? eventStatus;
  final DateTime? eventStartAt;

  String get eventId => ideathonId;
  String get eventName => ideathonName;
  String get eventSchedule => ideathonSchedule;

  String get ideaId => idea.ideaId;

  JudgeAssignmentRowStatus get workflowStatus {
    if (idea.hasEvaluationAggregate) {
      return JudgeAssignmentRowStatus.inProgress;
    }
    return JudgeAssignmentRowStatus.assigned;
  }
}

class JudgeEvaluationEvaluatedRow {
  const JudgeEvaluationEvaluatedRow({
    required this.idea,
    required this.teamName,
    required this.problemTitle,
    required this.score,
    required this.evaluatedAt,
    required this.status,
    required this.hasFeedback,
    required this.latestScore,
    required this.assignmentId,
    required this.assignedJudgeCount,
    this.ideathonId = '',
    this.ideathonName = '',
    this.evaluationTemplateId = '',
    this.ideathonSchedule = '',
    this.eventStatus,
    this.eventStartAt,
  });

  final IdeaModel idea;
  final String teamName;
  final String problemTitle;
  final double score;
  final DateTime evaluatedAt;
  final IdeaStatus status;
  final bool hasFeedback;
  final ScoreModel latestScore;
  final String assignmentId;
  final int assignedJudgeCount;
  final String ideathonId;
  final String ideathonName;
  final String evaluationTemplateId;
  final String ideathonSchedule;
  final IdeathonStatus? eventStatus;
  final DateTime? eventStartAt;

  String get eventId => ideathonId;
  String get eventName => ideathonName;
  String get eventSchedule => ideathonSchedule;

  String get ideaId => idea.ideaId;

  JudgeAssignmentRowStatus get workflowStatus => JudgeAssignmentRowStatus.completed;
}

class JudgeEvaluationFeedbackRow {
  const JudgeEvaluationFeedbackRow({
    required this.ideaId,
    required this.ideaTitle,
    required this.evaluatedAt,
    required this.overallScore,
    required this.remarksExcerpt,
    required this.hasStructuredCriteria,
    this.ideathonId = '',
    this.ideathonName = '',
    this.ideathonSchedule = '',
    this.eventStatus,
    this.problemTitle = '',
    this.teamName = '',
    this.problemId = '',
    this.teamId = '',
    this.scoreId = '',
    required this.idea,
    required this.latestScore,
    this.evaluationTemplateId = '',
  });

  final String ideaId;
  final String ideaTitle;
  final DateTime evaluatedAt;
  final double overallScore;
  final String remarksExcerpt;
  final bool hasStructuredCriteria;
  final String ideathonId;
  final String ideathonName;
  final String ideathonSchedule;
  final IdeathonStatus? eventStatus;
  final String problemTitle;
  final String teamName;
  final String problemId;
  final String teamId;
  final String scoreId;
  final IdeaModel idea;
  final ScoreModel latestScore;
  final String evaluationTemplateId;

  String get eventId => ideathonId;
  String get eventName => ideathonName;
  String get eventSchedule => ideathonSchedule;
}

