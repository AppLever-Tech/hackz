import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/models/evaluation_criterion.dart';
import 'ideathon_idea_snapshot.dart';
import 'ideathon_status.dart';
import 'ideathon_type.dart';

class IdeathonModel {
  const IdeathonModel({
    required this.ideathonId,
    required this.orgId,
    required this.name,
    required this.description,
    required this.departmentId,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    required this.judgeIds,
    required this.coordinatorIds,
    required this.ideas,
    required this.evaluationTemplateId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.problemId = '',
    this.ideathonType = IdeathonType.internal,
    this.evaluationCriteria = const <EvaluationCriterion>[],
    this.winnerIdeaId = '',
    this.runnerUpIdeaId = '',
    this.resultsReviewedAt,
  });

  final String ideathonId;
  final String orgId;
  final IdeathonType ideathonType;
  final String name;
  final String description;
  final String departmentId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final IdeathonStatus status;
  final List<String> judgeIds;
  final List<String> coordinatorIds;
  final List<IdeathonIdeaSnapshot> ideas;
  final String evaluationTemplateId;

  /// Event-scoped rubric. Empty until Department Admin customizes the template.
  final List<EvaluationCriterion> evaluationCriteria;
  /// Optional filter/context only — Ideathon is not required to bind to one Problem.
  final String problemId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Department Admin selected winner (not rank-1 from the leaderboard).
  final String winnerIdeaId;
  /// Department Admin selected runner-up.
  final String runnerUpIdeaId;
  /// Set when Department Admin reviews results (unlocks Select Winners).
  final DateTime? resultsReviewedAt;

  int get ideaCount => ideas.length;
  int get judgeCount => judgeIds.length;
  int get coordinatorCount => coordinatorIds.length;
  bool get hasOptionalProblem => problemId.trim().isNotEmpty;

  /// Team Leader submissions/payments close one day before the event start.
  DateTime get submissionCutoff => startDateTime.subtract(const Duration(days: 1));

  /// Scheduled/in-progress events that have not reached the submission cutoff.
  bool get isAcceptingSubmissions {
    if (status == IdeathonStatus.completed ||
        status == IdeathonStatus.archived ||
        status == IdeathonStatus.draft) {
      return false;
    }
    return DateTime.now().isBefore(submissionCutoff);
  }

  /// Empty [problemId] means any problem; otherwise the idea must match.
  bool acceptsProblem(String problemId) {
    final String bound = this.problemId.trim();
    return bound.isEmpty || bound == problemId.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ideathonId': ideathonId,
      'orgId': orgId,
      'ideathonType': ideathonType.value,
      'name': name,
      'description': description,
      'departmentId': departmentId,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'status': status.value,
      'judgeIds': judgeIds,
      'coordinatorIds': coordinatorIds,
      'ideas': ideas.map((IdeathonIdeaSnapshot i) => i.toMap()).toList(growable: false),
      'evaluationTemplateId': evaluationTemplateId,
      if (evaluationCriteria.isNotEmpty)
        'evaluationCriteria':
            evaluationCriteria.map((EvaluationCriterion c) => c.toMap()).toList(growable: false),
      if (problemId.trim().isNotEmpty) 'problemId': problemId.trim(),
      if (winnerIdeaId.trim().isNotEmpty) 'winnerIdeaId': winnerIdeaId.trim(),
      if (runnerUpIdeaId.trim().isNotEmpty) 'runnerUpIdeaId': runnerUpIdeaId.trim(),
      if (resultsReviewedAt != null) 'resultsReviewedAt': Timestamp.fromDate(resultsReviewedAt!),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory IdeathonModel.fromMap(String id, Map<String, dynamic> map) {
    final List<IdeathonIdeaSnapshot> ideaSnapshots = <IdeathonIdeaSnapshot>[];
    final dynamic rawIdeas = map['ideas'];
    if (rawIdeas is List) {
      for (final dynamic item in rawIdeas) {
        if (item is Map) {
          ideaSnapshots.add(IdeathonIdeaSnapshot.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final List<EvaluationCriterion> criteria = <EvaluationCriterion>[];
    final dynamic rawCriteria = map['evaluationCriteria'];
    if (rawCriteria is List) {
      for (final dynamic item in rawCriteria) {
        if (item is Map) {
          criteria.add(EvaluationCriterion.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final DateTime start = (map['startDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime end = (map['endDateTime'] as Timestamp?)?.toDate() ?? start.add(const Duration(hours: 8));
    return IdeathonModel(
      ideathonId: ((map['ideathonId'] as String?) ?? '').trim().isNotEmpty
          ? ((map['ideathonId'] as String?) ?? '').trim()
          : id,
      orgId: (map['orgId'] as String? ?? '').trim(),
      ideathonType: IdeathonType.fromRaw(map['ideathonType'] as String?),
      name: (map['name'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      departmentId: (map['departmentId'] as String? ?? '').trim(),
      startDateTime: start,
      endDateTime: end,
      status: IdeathonStatus.fromRaw((map['status'] as String?) ?? 'draft'),
      judgeIds: _readStringList(map['judgeIds']),
      coordinatorIds: _readStringList(map['coordinatorIds']),
      ideas: ideaSnapshots,
      evaluationTemplateId: (map['evaluationTemplateId'] as String? ?? '').trim(),
      evaluationCriteria: criteria,
      problemId: (map['problemId'] as String? ?? '').trim(),
      winnerIdeaId: (map['winnerIdeaId'] as String? ?? '').trim(),
      runnerUpIdeaId: (map['runnerUpIdeaId'] as String? ?? '').trim(),
      resultsReviewedAt: (map['resultsReviewedAt'] as Timestamp?)?.toDate(),
      createdBy: (map['createdBy'] as String? ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((dynamic e) => e.toString().trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }
}
