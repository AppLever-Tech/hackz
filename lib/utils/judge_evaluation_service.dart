import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attachment_model.dart';
import '../models/enums/user_role.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/problem_model.dart';
import '../models/score_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';
import 'judge_evaluation_feedback_codec.dart';
import 'role_visibility_helpers.dart';

/// Centralized judge-scoped evaluation queries and persistence.
abstract final class JudgeEvaluationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static const Duration _ttl = Duration(seconds: 45);

  static String _key(UserModel judge) => '${judge.userId.trim()}|${judge.orgId.trim()}';

  static void clearCache() => _cache.clear();

  static bool _isJudge(UserModel user) => UserRole.fromCode(user.role) == UserRole.judge;

  /// Persists score + structured feedback and marks idea evaluated when appropriate.
  static Future<void> saveEvaluation({
    required UserModel judge,
    required IdeaModel idea,
    required int overallScore,
    required int innovation,
    required int feasibility,
    required int impact,
    required String recommendation,
    required String remarks,
  }) async {
    if (!_isJudge(judge)) {
      throw StateError('Only judges can save evaluations.');
    }
    if (idea.status == IdeaStatus.pendingSubmission) {
      throw StateError('Idea is pending payment verification.');
    }
    if (!RoleVisibilityHelpers.ideaVisibleToUser(idea, judge)) {
      throw StateError('Idea is not visible to this judge.');
    }
    final feedback = JudgeEvaluationFeedbackCodec.compose(
      innovation: innovation,
      feasibility: feasibility,
      impact: impact,
      recommendation: recommendation,
      remarks: remarks,
    );
    final col = _db.collection(FirestoreUtils.hkzScores);
    final existing = await col
        .where('ideaId', isEqualTo: idea.ideaId)
        .where('judgeId', isEqualTo: judge.userId)
        .limit(1)
        .get();
    final payload = ScoreModel(
      scoreId: existing.docs.isEmpty ? '' : existing.docs.first.id,
      ideaId: idea.ideaId,
      judgeId: judge.userId,
      score: overallScore.toDouble(),
      feedback: feedback,
      createdAt: DateTime.now(),
      orgId: judge.orgId,
      departmentCode: idea.problemDepartmentCode,
    );
    if (existing.docs.isEmpty) {
      final doc = col.doc();
      await doc.set(payload.copyWith(scoreId: doc.id).toMap());
    } else {
      await col.doc(existing.docs.first.id).update(payload.toMap());
    }
    await _db.collection(FirestoreUtils.hkzIdeas).doc(idea.ideaId).update(<String, dynamic>{
      'status': IdeaStatus.evaluated.value,
    });
    clearCache();
  }

  static Future<JudgeEvaluationWorkspaceVm> loadWorkspace(UserModel judge) async {
    if (!_isJudge(judge)) {
      return const JudgeEvaluationWorkspaceVm.empty();
    }
    final key = _key(judge);
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
    ]);

    final ideaDocs = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scoreDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final teamDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final attachmentDocs = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final paymentDocs = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;

    final teamsById = <String, TeamModel>{
      for (final d in teamDocs) d.id: TeamModel.fromMap(d.id, d.data()),
    };
    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
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

    final scopedIdeas = ideaDocs
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .where((idea) => RoleVisibilityHelpers.ideaVisibleToUser(idea, judge))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final scoresByJudge = scoreDocs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => s.judgeId == judge.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final scoresByIdea = <String, List<ScoreModel>>{};
    for (final score in scoresByJudge) {
      scoresByIdea.putIfAbsent(score.ideaId, () => <ScoreModel>[]).add(score);
    }
    for (final e in scoresByIdea.values) {
      e.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final evaluatedIdeaIds = scoresByIdea.keys.toSet();

    bool judgeMayEvaluate(IdeaModel idea) {
      if (!RoleVisibilityHelpers.ideaVisibleToUser(idea, judge)) return false;
      if (idea.status == IdeaStatus.pendingSubmission) return false;
      final pay = paymentByIdeaId[idea.ideaId];
      if (pay != null && pay.status != PaymentRecordStatus.verified && pay.status != PaymentRecordStatus.rejected) {
        return false;
      }
      return true;
    }

    final pendingIdeas = scopedIdeas.where((i) => judgeMayEvaluate(i) && !evaluatedIdeaIds.contains(i.ideaId)).toList(growable: false);

    final pendingRows = pendingIdeas
        .map((idea) => _buildPendingRow(idea, teamsById, problemsById, attachmentCountByIdeaId))
        .toList(growable: false);

    final evaluatedRows = <JudgeEvaluationEvaluatedRow>[];
    for (final idea in scopedIdeas) {
      final list = scoresByIdea[idea.ideaId];
      if (list == null || list.isEmpty) continue;
      final score = list.first;
      evaluatedRows.add(_buildEvaluatedRow(idea, teamsById, problemsById, score));
    }
    evaluatedRows.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));

    final latestScoreByIdea = <String, ScoreModel>{};
    for (final s in scoresByJudge) {
      latestScoreByIdea.putIfAbsent(s.ideaId, () => s);
    }

    final feedbackRows = <JudgeEvaluationFeedbackRow>[];
    for (final s in latestScoreByIdea.values) {
      IdeaModel? match;
      for (final i in scopedIdeas) {
        if (i.ideaId == s.ideaId) {
          match = i;
          break;
        }
      }
      final title = match == null ? s.ideaId : _ideaTitle(match);
      final decoded = JudgeEvaluationFeedbackCodec.tryDecode(s.feedback);
      final excerpt = JudgeEvaluationFeedbackCodec.displayRemarks(s.feedback);
      final hasContent = excerpt.isNotEmpty || decoded != null;
      if (!hasContent) continue;
      feedbackRows.add(
        JudgeEvaluationFeedbackRow(
          ideaId: s.ideaId,
          ideaTitle: title,
          evaluatedAt: s.createdAt,
          overallScore: s.score,
          remarksExcerpt: excerpt.isEmpty
              ? (decoded != null ? 'Criteria scores recorded' : '—')
              : (excerpt.length > 160 ? '${excerpt.substring(0, 157)}…' : excerpt),
          hasStructuredCriteria: decoded != null,
        ),
      );
    }
    feedbackRows.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));

    final evaluatedCount = evaluatedRows.length;
    final pendingCount = pendingRows.length;
    final total = evaluatedCount + pendingCount;
    final completionPct = total == 0 ? 0.0 : (evaluatedCount / total) * 100.0;
    final avgScore = scoresByJudge.isEmpty
        ? null
        : scoresByJudge.map((e) => e.score).reduce((a, b) => a + b) / scoresByJudge.length;

    final vm = JudgeEvaluationWorkspaceVm(
      pending: pendingRows,
      evaluated: evaluatedRows,
      feedback: feedbackRows,
      pendingCount: pendingCount,
      evaluatedCount: evaluatedCount,
      averageScore: avgScore,
      completionPercent: completionPct,
    );
    _cache[key] = _CacheEntry(at: now, vm: vm);
    return vm;
  }

  static JudgeEvaluationPendingRow _buildPendingRow(
    IdeaModel idea,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
    Map<String, int> attachmentCountByIdeaId,
  ) {
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    final teamName = (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName.trim();
    final problemTitle = (problem?.title ?? idea.problemTitle).trim().isEmpty ? idea.problemId : (problem?.title ?? idea.problemTitle).trim();
    final category = (problem?.category ?? '').trim();
    final theme = (problem?.theme ?? '').trim();
    final fileCount = idea.files.where((e) => e.trim().isNotEmpty).length;
    final att = (attachmentCountByIdeaId[idea.ideaId] ?? 0) + fileCount;
    final due = idea.createdAt.add(const Duration(days: 14));
    final priority = idea.status == IdeaStatus.underReview ? JudgeEvaluationPriority.high : JudgeEvaluationPriority.standard;
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
    );
  }

  static JudgeEvaluationEvaluatedRow _buildEvaluatedRow(
    IdeaModel idea,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
    ScoreModel score,
  ) {
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    final teamName = (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName.trim();
    final problemTitle = (problem?.title ?? idea.problemTitle).trim().isEmpty ? idea.problemId : (problem?.title ?? idea.problemTitle).trim();
    final hasFb = JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback).trim().isNotEmpty;
    return JudgeEvaluationEvaluatedRow(
      idea: idea,
      teamName: teamName,
      problemTitle: problemTitle,
      score: score.score,
      evaluatedAt: score.createdAt,
      status: idea.status,
      hasFeedback: hasFb,
      latestScore: score,
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

class JudgeEvaluationWorkspaceVm {
  const JudgeEvaluationWorkspaceVm({
    required this.pending,
    required this.evaluated,
    required this.feedback,
    required this.pendingCount,
    required this.evaluatedCount,
    required this.averageScore,
    required this.completionPercent,
  });

  const JudgeEvaluationWorkspaceVm.empty()
      : pending = const <JudgeEvaluationPendingRow>[],
        evaluated = const <JudgeEvaluationEvaluatedRow>[],
        feedback = const <JudgeEvaluationFeedbackRow>[],
        pendingCount = 0,
        evaluatedCount = 0,
        averageScore = null,
        completionPercent = 0;

  final List<JudgeEvaluationPendingRow> pending;
  final List<JudgeEvaluationEvaluatedRow> evaluated;
  final List<JudgeEvaluationFeedbackRow> feedback;
  final int pendingCount;
  final int evaluatedCount;
  final double? averageScore;
  final double completionPercent;
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
  });

  final IdeaModel idea;
  final String teamName;
  final String problemTitle;
  final double score;
  final DateTime evaluatedAt;
  final IdeaStatus status;
  final bool hasFeedback;
  final ScoreModel latestScore;
}

class JudgeEvaluationFeedbackRow {
  const JudgeEvaluationFeedbackRow({
    required this.ideaId,
    required this.ideaTitle,
    required this.evaluatedAt,
    required this.overallScore,
    required this.remarksExcerpt,
    required this.hasStructuredCriteria,
  });

  final String ideaId;
  final String ideaTitle;
  final DateTime evaluatedAt;
  final double overallScore;
  final String remarksExcerpt;
  final bool hasStructuredCriteria;
}

extension _JudgeScoreCopy on ScoreModel {
  ScoreModel copyWith({String? scoreId}) {
    return ScoreModel(
      scoreId: scoreId ?? this.scoreId,
      ideaId: ideaId,
      judgeId: judgeId,
      score: score,
      feedback: feedback,
      createdAt: createdAt,
      orgId: orgId,
      departmentCode: departmentCode,
    );
  }
}
