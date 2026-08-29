import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../workspace/evaluation_workspace_loader.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../organization/models/department_model.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../problems/models/problem_model.dart';
import '../../team/models/team_model.dart';
import '../../user/models/enums/judge_type.dart';
import '../../user/models/user_model.dart';
import '../models/evaluation_details_view_model.dart';
import '../models/score_model.dart';
import 'evaluation_aggregation_service.dart';
import 'evaluation_templates_service.dart';

/// Loads evaluation-centric context for [EvaluationDetailsWorkspace].
///
/// Avoids the heavy aggregate path in [EvaluationWorkspaceLoader] — criteria
/// breakdown is fetched only when a judge preview is opened.
abstract final class EvaluationDetailsLoader {
  EvaluationDetailsLoader._();

  static Future<EvaluationDetailsViewModel> load({
    required String ideaId,
    String ideathonId = '',
  }) async {
    final String id = ideaId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ideaId must be non-empty');
    }
    final String eventId = ideathonId.trim();

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      final DocumentSnapshot<Map<String, dynamic>> scoreDoc =
          await db.collection(FirestoreUtils.hkzScores).doc(id).get();
      if (scoreDoc.exists && scoreDoc.data() != null) {
        final ScoreModel score = ScoreModel.fromMap(scoreDoc.id, scoreDoc.data()!);
        final String resolvedIdeaId = score.ideaId.trim();
        if (resolvedIdeaId.isEmpty || resolvedIdeaId == id) {
          throw StateError('Idea not found');
        }
        return load(
          ideaId: resolvedIdeaId,
          ideathonId: eventId.isNotEmpty ? eventId : score.ideathonId,
        );
      }
      throw StateError('Idea not found');
    }

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final String orgId = idea.orgId.trim();

    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);

    final String deptCode = idea.problemDepartmentCode.trim();
    final int defaultScale = EvaluationTemplatesService.defaultTemplate.scoringScale;

    Query<Map<String, dynamic>> scoresQuery = orgId.isEmpty
        ? db.collection(FirestoreUtils.hkzScores).limit(0)
        : db
            .collection(FirestoreUtils.hkzScores)
            .where('orgId', isEqualTo: orgId)
            .where('ideaId', isEqualTo: id);
    if (eventId.isNotEmpty) {
      scoresQuery = scoresQuery.where('ideathonId', isEqualTo: eventId);
    }
    final Future<QuerySnapshot<Map<String, dynamic>>> scoresFuture = scoresQuery.get();

    final Future<DocumentSnapshot<Map<String, dynamic>>?> teamFuture = idea.teamId.trim().isEmpty
        ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : db.collection(FirestoreUtils.hkzTeams).doc(idea.teamId.trim()).get();

    final Future<ProblemModel?> problemFuture = idea.problemId.trim().isEmpty
        ? Future<ProblemModel?>.value(null)
        : FirestoreUtils.fetchProblemById(idea.problemId.trim());

    final Future<UserModel?> submitterFuture = idea.createdBy.trim().isEmpty
        ? Future<UserModel?>.value(null)
        : FirestoreUtils.fetchUser(idea.createdBy.trim());

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      scoresFuture,
      teamFuture,
      problemFuture,
      submitterFuture,
    ]);

    final QuerySnapshot<Map<String, dynamic>> scoresSnap =
        parallel[0] as QuerySnapshot<Map<String, dynamic>>;
    final DocumentSnapshot<Map<String, dynamic>>? teamDoc =
        parallel[1] as DocumentSnapshot<Map<String, dynamic>>?;
    final ProblemModel? problem = parallel[2] as ProblemModel?;
    final UserModel? submitter = parallel[3] as UserModel?;

    final TeamModel? team = teamDoc != null && teamDoc.exists && teamDoc.data() != null
        ? TeamModel.fromMap(teamDoc.id, teamDoc.data()!)
        : null;

    final List<ScoreSummary> scores = scoresSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => ScoreSummary.fromDoc(doc))
        .where((ScoreSummary s) {
          if (eventId.isNotEmpty) return s.ideathonId.trim() == eventId;
          // Pipeline details: never mix Ideathon event scores.
          return s.ideathonId.trim().isEmpty;
        })
        .toList(growable: false)
      ..sort((ScoreSummary a, ScoreSummary b) => b.evaluatedAt.compareTo(a.evaluatedAt));

    final Set<String> judgeIds = <String>{
      for (final ScoreSummary s in scores)
        if (s.judgeId.isNotEmpty) s.judgeId,
    };

    final Map<String, UserModel?> judgesById = await _fetchUsersById(judgeIds);

    final List<EvaluationJudgeDetail> judgeDetails = <EvaluationJudgeDetail>[];
    for (final ScoreSummary score in scores) {
      final UserModel? judge = judgesById[score.judgeId];
      final String judgeName = judge == null
          ? (score.judgeId.isEmpty ? 'Judge' : score.judgeId)
          : userDisplayName(judge);
      final int scale = EvaluationTemplatesService.resolveTemplate(
        score.templateId,
        departmentCode: deptCode,
      ).scoringScale;

      judgeDetails.add(
        EvaluationJudgeDetail(
          entry: EvaluationJudgeEntry(
            scoreId: score.scoreId,
            judgeId: score.judgeId,
            judgeName: judgeName,
            overallScore: score.overallScore,
            evaluatedAt: score.evaluatedAt,
            criteria: const <EvaluationCriterionScore>[],
            criterionComments: const <String, String>{},
            recommendation: 'none',
            remarks: '',
            templateName: '',
          ),
          scoreId: score.scoreId,
          templateId: score.templateId,
          judgeType: _judgeType(judge),
          scoringScale: scale,
          judgeUser: judge,
        ),
      );
    }

    final int scoringScale = judgeDetails.isEmpty
        ? defaultScale
        : judgeDetails.first.scoringScale;

    final String ideaTitle = idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim();
    final String teamName = team?.teamName.trim().isNotEmpty == true
        ? team!.teamName.trim()
        : (idea.teamId.trim().isEmpty ? '—' : idea.teamId.trim());
    final String problemTitle = (problem?.title ?? idea.problemTitle).trim().isEmpty
        ? '—'
        : (problem?.title ?? idea.problemTitle).trim();
    final String departmentName = DepartmentModel.byCode(idea.problemDepartmentCode)?.name ??
        (deptCode.isEmpty ? '—' : deptCode);

    double? averageScore;
    double? highestScore;
    double? lowestScore;
    if (scores.isNotEmpty) {
      final List<double> values = scores.map((ScoreSummary s) => s.overallScore).toList(growable: false);
      final double sum = values.fold<double>(0, (double a, double b) => a + b);
      averageScore = double.parse((sum / values.length).toStringAsFixed(2));
      values.sort();
      highestScore = values.last;
      lowestScore = values.first;
    }

    return EvaluationDetailsViewModel(
      ideaId: id,
      idea: idea,
      problemTitle: problemTitle,
      ideaTitle: ideaTitle,
      departmentName: departmentName,
      status: idea.status,
      statusLabel: IdeaStatusHelpers.label(idea.status),
      submittedByName: submitter == null
          ? (idea.createdBy.trim().isEmpty ? '—' : idea.createdBy.trim())
          : userDisplayName(submitter),
      submittedByUser: submitter,
      teamId: team?.teamId ?? idea.teamId,
      teamName: teamName,
      evaluationRank: eventId.isNotEmpty ? null : idea.evaluationRank,
      judgeDetails: judgeDetails,
      scoringScale: scoringScale,
      ideathonId: eventId,
      aggregateOverride: scores.isEmpty
          ? null
          : IdeaEvaluationAggregate(
              averageScore: averageScore,
              highestScore: highestScore,
              lowestScore: lowestScore,
              totalEvaluators: scores.length,
            ),
    );
  }

  static JudgeType? _judgeType(UserModel? judge) => judge?.profile?.judgeProfile?.judgeType;

  static Future<Map<String, UserModel?>> _fetchUsersById(Set<String> userIds) async {
    if (userIds.isEmpty) return const <String, UserModel?>{};

    final List<String> ids = userIds.toList(growable: false);
    final List<UserModel?> users = await Future.wait<UserModel?>(
      ids.map(FirestoreUtils.fetchUser),
    );

    return <String, UserModel?>{
      for (int i = 0; i < ids.length; i++) ids[i]: users[i],
    };
  }
}

class ScoreSummary {
  const ScoreSummary({
    required this.scoreId,
    required this.judgeId,
    required this.templateId,
    required this.overallScore,
    required this.evaluatedAt,
    this.ideathonId = '',
  });

  factory ScoreSummary.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    return ScoreSummary(
      scoreId: doc.id,
      judgeId: (data['judgeId'] as String? ?? '').trim(),
      templateId: (data['templateId'] as String? ?? '').trim(),
      overallScore: (data['score'] as num?)?.toDouble() ?? 0,
      evaluatedAt: _readDate(data['createdAt']),
      ideathonId: (data['ideathonId'] as String? ?? '').trim(),
    );
  }

  final String scoreId;
  final String judgeId;
  final String templateId;
  final double overallScore;
  final DateTime evaluatedAt;
  final String ideathonId;

  static DateTime _readDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
