import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/idea_model.dart';
import '../../../models/score_model.dart';
import '../../../models/user_model.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../utils/firestore_utils.dart';
import '../../problems/models/problem_model.dart';
import '../../team/models/team_model.dart';
import '../assignments/models/evaluation_assignment_conflict.dart';
import '../assignments/services/evaluation_assignment_service.dart';

class EvaluationAssignmentWorkspace extends StatefulWidget {
  const EvaluationAssignmentWorkspace({super.key, required this.user});

  final UserModel user;

  @override
  State<EvaluationAssignmentWorkspace> createState() =>
      _EvaluationAssignmentWorkspaceState();
}

class _IdeaRowVm {
  const _IdeaRowVm({
    required this.idea,
    required this.team,
    required this.latestScore,
    required this.assignedJudgeIds,
  });

  final IdeaModel idea;
  final TeamModel? team;
  final ScoreModel? latestScore;
  final List<String> assignedJudgeIds;
}

class _AssignmentDocVm {
  const _AssignmentDocVm({
    required this.assignmentId,
    required this.ideaId,
    required this.judgeId,
  });

  final String assignmentId;
  final String ideaId;
  final String judgeId;
}

class _EvaluationAssignmentWorkspaceState extends State<EvaluationAssignmentWorkspace> {
  bool _loading = true;
  bool _saving = false;
  String? _selectedProblemId;
  String _search = '';
  final Set<String> _selectedIdeaIds = <String>{};
  final Set<String> _selectedJudgeIds = <String>{};
  bool _onlyUnassigned = false;
  bool _onlyPendingScore = false;
  String? _filterDepartmentCode;
  final int _pageSize = 120;
  int _visibleCount = 120;

  List<ProblemModel> _problems = <ProblemModel>[];
  List<IdeaModel> _ideas = <IdeaModel>[];
  List<UserModel> _judges = <UserModel>[];
  Map<String, TeamModel> _teamsById = <String, TeamModel>{};
  Map<String, ScoreModel> _latestScoreByIdea = <String, ScoreModel>{};
  Map<String, List<String>> _assignedJudgesByIdea = <String, List<String>>{};
  List<_AssignmentDocVm> _assignmentDocs = <_AssignmentDocVm>[];
  Map<String, int> _workloadByJudge = <String, int>{};

  String get _orgId => widget.user.orgId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzProblems)
            .where('orgId', isEqualTo: _orgId)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzIdeas)
            .where('orgId', isEqualTo: _orgId)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzUsers)
            .where('orgId', isEqualTo: _orgId)
            .where('role', isEqualTo: 'JUD')
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzTeams)
            .where('orgId', isEqualTo: _orgId)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzScores)
            .where('orgId', isEqualTo: _orgId)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreUtils.hkzEvaluationAssignments)
            .where('orgId', isEqualTo: _orgId)
            .where('status', isEqualTo: 'active')
            .get(),
      ]);

      final QuerySnapshot<Map<String, dynamic>> problemsSnap =
          results[0] as QuerySnapshot<Map<String, dynamic>>;
      final QuerySnapshot<Map<String, dynamic>> ideasSnap =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final QuerySnapshot<Map<String, dynamic>> judgesSnap =
          results[2] as QuerySnapshot<Map<String, dynamic>>;
      final QuerySnapshot<Map<String, dynamic>> teamsSnap =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final QuerySnapshot<Map<String, dynamic>> scoresSnap =
          results[4] as QuerySnapshot<Map<String, dynamic>>;
      final QuerySnapshot<Map<String, dynamic>> assignmentsSnap =
          results[5] as QuerySnapshot<Map<String, dynamic>>;

      final List<ProblemModel> problems = problemsSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              ProblemModel.fromMap(doc.id, doc.data()))
          .toList(growable: false)
        ..sort((ProblemModel a, ProblemModel b) => a.title.compareTo(b.title));
      final List<IdeaModel> ideas = ideasSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              IdeaModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
      final List<UserModel> judges = judgesSnap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isNotEmpty) return user;
        return user.copyWith(userId: doc.id);
      }).toList(growable: false);
      final Map<String, TeamModel> teamsById = <String, TeamModel>{
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in teamsSnap.docs)
          doc.id: TeamModel.fromMap(doc.id, doc.data()),
      };
      final Map<String, ScoreModel> latestScoreByIdea = <String, ScoreModel>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in scoresSnap.docs) {
        final ScoreModel score = ScoreModel.fromMap(doc.id, doc.data());
        final ScoreModel? prev = latestScoreByIdea[score.ideaId];
        if (prev == null || score.createdAt.isAfter(prev.createdAt)) {
          latestScoreByIdea[score.ideaId] = score;
        }
      }
      final Map<String, List<String>> assignedByIdea = <String, List<String>>{};
      final List<_AssignmentDocVm> assignmentDocs = <_AssignmentDocVm>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in assignmentsSnap.docs) {
        final String ideaId = ((doc.data()['ideaId'] as String?) ?? '').trim();
        final String judgeId = ((doc.data()['judgeId'] as String?) ?? '').trim();
        if (ideaId.isEmpty || judgeId.isEmpty) continue;
        assignedByIdea.putIfAbsent(ideaId, () => <String>[]).add(judgeId);
        assignmentDocs.add(
          _AssignmentDocVm(
            assignmentId: doc.id,
            ideaId: ideaId,
            judgeId: judgeId,
          ),
        );
      }
      final Map<String, int> workload =
          await EvaluationAssignmentService.workloadByJudge(
        orgId: _orgId,
        judgeIds: judges.map((UserModel e) => e.userId),
      );

      if (!mounted) return;
      setState(() {
        _problems = problems;
        _ideas = ideas;
        _judges = judges;
        _teamsById = teamsById;
        _latestScoreByIdea = latestScoreByIdea;
        _assignedJudgesByIdea = assignedByIdea;
        _assignmentDocs = assignmentDocs;
        _workloadByJudge = workload;
        _selectedProblemId = _selectedProblemId ??
            (_problems.isEmpty ? null : _problems.first.problemId);
        _loading = false;
        _visibleCount = _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      FeedbackService.showError(
        context,
        title: 'Load failed',
        message: '$e',
      );
    }
  }

  List<_IdeaRowVm> get _filteredIdeas {
    final String selectedProblem = (_selectedProblemId ?? '').trim();
    final String q = _search.trim().toLowerCase();
    final List<_IdeaRowVm> rows = _ideas
        .where((IdeaModel idea) =>
            selectedProblem.isEmpty || idea.problemId == selectedProblem)
        .map(_buildIdeaRowVm)
        .where((_IdeaRowVm row) {
      if (_onlyUnassigned && row.assignedJudgeIds.isNotEmpty) return false;
      if (_onlyPendingScore && row.latestScore != null) return false;
      if ((_filterDepartmentCode ?? '').trim().isNotEmpty &&
          row.idea.problemDepartmentCode != _filterDepartmentCode) {
        return false;
      }
      if (q.isEmpty) return true;
      final String team = (row.team?.teamName ?? row.idea.teamId).toLowerCase();
      return row.idea.ideaTitle.toLowerCase().contains(q) ||
          row.idea.problemTitle.toLowerCase().contains(q) ||
          team.contains(q);
    }).toList(growable: false)
      ..sort((a, b) => b.idea.createdAt.compareTo(a.idea.createdAt));
    return rows;
  }

  _IdeaRowVm _buildIdeaRowVm(IdeaModel idea) {
    return _IdeaRowVm(
      idea: idea,
      team: _teamsById[idea.teamId],
      latestScore: _latestScoreByIdea[idea.ideaId],
      assignedJudgeIds: _assignedJudgesByIdea[idea.ideaId] ?? const <String>[],
    );
  }

  ProblemModel? get _selectedProblem {
    final String pid = (_selectedProblemId ?? '').trim();
    for (final ProblemModel p in _problems) {
      if (p.problemId == pid) return p;
    }
    return null;
  }

  Future<void> _assignSelected() async {
    if (_saving) return;
    final List<_IdeaRowVm> selectedRows = _filteredIdeas
        .where((_IdeaRowVm row) => _selectedIdeaIds.contains(row.idea.ideaId))
        .toList(growable: false);
    final List<UserModel> targetJudges = _judges
        .where((UserModel u) => _selectedJudgeIds.contains(u.userId))
        .toList(growable: false);
    if (selectedRows.isEmpty || targetJudges.isEmpty) {
      FeedbackService.showInfo(
        context,
        title: 'Nothing selected',
        message: 'Select ideas and judges first.',
      );
      return;
    }
    final ProblemModel? selectedProblem = _selectedProblem;
    if (selectedProblem == null) return;
    setState(() => _saving = true);
    final String? err = await EvaluationAssignmentService.assignIdeasToJudges(
      orgId: _orgId,
      actorUserId: widget.user.userId,
      problemId: selectedProblem.problemId,
      ideas: selectedRows.map((_IdeaRowVm e) => e.idea),
      judges: targetJudges,
      teamsById: _teamsById,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      FeedbackService.showError(
        context,
        title: 'Assignment failed',
        message: err,
      );
      return;
    }
    await _load();
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: 'Assigned',
      message: 'Selected ideas were assigned to judges.',
    );
  }

  Future<void> _removeAssignment({
    required String ideaId,
    required String judgeId,
  }) async {
    final _AssignmentDocVm? doc = _assignmentDocs.cast<_AssignmentDocVm?>().firstWhere(
          (_AssignmentDocVm? d) =>
              d != null && d.ideaId == ideaId && d.judgeId == judgeId,
          orElse: () => null,
        );
    if (doc == null) return;
    await EvaluationAssignmentService.removeAssignment(
      assignmentId: doc.assignmentId,
    );
    if (!mounted) return;
    await _load();
  }

  int get _assignedCountForProblem {
    final String pid = (_selectedProblemId ?? '').trim();
    if (pid.isEmpty) return 0;
    final Set<String> assignedIdeaIds = _ideas
        .where((IdeaModel idea) => idea.problemId == pid)
        .where((IdeaModel idea) =>
            (_assignedJudgesByIdea[idea.ideaId] ?? const <String>[]).isNotEmpty)
        .map((IdeaModel idea) => idea.ideaId)
        .toSet();
    return assignedIdeaIds.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final bool mobile = MediaQuery.sizeOf(context).width < 900;
    if (mobile) {
      return _buildMobileLayout();
    }
    return Row(
      children: <Widget>[
        SizedBox(width: 300, child: _buildLeftPanel()),
        const SizedBox(width: 10),
        Expanded(child: _buildCenterPanel()),
        const SizedBox(width: 10),
        SizedBox(width: 320, child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      children: <Widget>[
        _buildLeftPanel(),
        const SizedBox(height: 10),
        _buildRightPanel(),
        const SizedBox(height: 10),
        SizedBox(height: 540, child: _buildCenterPanel()),
      ],
    );
  }

  Widget _buildLeftPanel() {
    final ProblemModel? selectedProblem = _selectedProblem;
    final List<_IdeaRowVm> rows = _filteredIdeas;
    final int evaluated = rows.where((_IdeaRowVm r) => r.latestScore != null).length;
    final int assigned = rows.where((_IdeaRowVm r) => r.assignedJudgeIds.isNotEmpty).length;
    final int total = rows.length;
    final double progress = total == 0 ? 0 : evaluated / total;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(AppIcons.problems, size: 18, color: Color(0xFF4F46E5)),
              SizedBox(width: 6),
              Text(
                'Problem Summary',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProblemId,
            isExpanded: true,
            items: _problems
                .map((ProblemModel p) => DropdownMenuItem<String>(
                      value: p.problemId,
                      child: Text(
                        p.title.isEmpty ? p.problemId : p.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(growable: false),
            onChanged: (String? value) {
              setState(() {
                _selectedProblemId = value;
                _selectedIdeaIds.clear();
                _visibleCount = _pageSize;
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            selectedProblem?.title.isNotEmpty == true
                ? selectedProblem!.title
                : 'Select a problem',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _metricLine('Total ideas', '$total'),
          _metricLine('Assigned ideas', '$assigned'),
          _metricLine('Unassigned ideas', '${math.max(0, total - assigned)}'),
          _metricLine('Evaluated ideas', '$evaluated'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            'Evaluation progress ${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              FilterChip(
                label: const Text('Unassigned'),
                selected: _onlyUnassigned,
                onSelected: (bool v) => setState(() => _onlyUnassigned = v),
              ),
              FilterChip(
                label: const Text('Score pending'),
                selected: _onlyPendingScore,
                onSelected: (bool v) => setState(() => _onlyPendingScore = v),
              ),
              ActionChip(
                avatar: const Icon(Icons.select_all, size: 16),
                label: const Text('Select all'),
                onPressed: () {
                  setState(() {
                    _selectedIdeaIds
                      ..clear()
                      ..addAll(rows.map((_IdeaRowVm e) => e.idea.ideaId));
                  });
                },
              ),
              ActionChip(
                label: const Text('Select filtered'),
                onPressed: () {
                  setState(() {
                    _selectedIdeaIds
                      ..clear()
                      ..addAll(_filteredIdeas.map((_IdeaRowVm e) => e.idea.ideaId));
                  });
                },
              ),
              ActionChip(
                label: const Text('Select unassigned'),
                onPressed: () {
                  setState(() {
                    _selectedIdeaIds
                      ..clear()
                      ..addAll(_filteredIdeas
                          .where((_IdeaRowVm e) => e.assignedJudgeIds.isEmpty)
                          .map((_IdeaRowVm e) => e.idea.ideaId));
                  });
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('Clear selection'),
                onPressed: () => setState(() => _selectedIdeaIds.clear()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCenterPanel() {
    final List<_IdeaRowVm> rows = _filteredIdeas;
    final int visible = math.min(_visibleCount, rows.length);
    return Container(
      decoration: kDashboardCardDecoration,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.ideas, size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                const Text(
                  'Ideas',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search idea/team/problem',
                      prefixIcon: Icon(AppIcons.search, size: 18),
                    ),
                    onChanged: (String v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: visible + (visible < rows.length ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (index == visible && visible < rows.length) {
                  return TextButton(
                    onPressed: () {
                      setState(() => _visibleCount += _pageSize);
                    },
                    child: Text('Load more (${rows.length - visible} remaining)'),
                  );
                }
                final _IdeaRowVm row = rows[index];
                final bool selected = _selectedIdeaIds.contains(row.idea.ideaId);
                return _ideaRow(row, selected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ideaRow(_IdeaRowVm row, bool selected) {
    final String teamName =
        (row.team?.teamName ?? row.idea.teamId).trim().isEmpty
            ? row.idea.teamId
            : (row.team?.teamName ?? row.idea.teamId).trim();
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIdeaIds.remove(row.idea.ideaId);
          } else {
            _selectedIdeaIds.add(row.idea.ideaId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F5FF) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Checkbox(
              value: selected,
              onChanged: (_) => setState(() {
                if (selected) {
                  _selectedIdeaIds.remove(row.idea.ideaId);
                } else {
                  _selectedIdeaIds.add(row.idea.ideaId);
                }
              }),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.idea.ideaTitle.isEmpty
                        ? row.idea.problemNumber
                        : row.idea.ideaTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$teamName • ${row.idea.problemDepartmentCode} • ${row.idea.status.value}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: row.assignedJudgeIds
                        .map((String judgeId) {
                          final UserModel? judge = _judges.cast<UserModel?>().firstWhere(
                                (UserModel? u) => u?.userId == judgeId,
                                orElse: () => null,
                              );
                          final String label = judge == null
                              ? judgeId
                              : ('${judge.firstName} ${judge.lastName}'
                                          .trim()
                                          .isEmpty
                                      ? judge.userId
                                      : '${judge.firstName} ${judge.lastName}'
                                          .trim());
                          return InputChip(
                            label: Text(label),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () =>
                                _removeAssignment(ideaId: row.idea.ideaId, judgeId: judgeId),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              row.latestScore == null
                  ? '—'
                  : row.latestScore!.score.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      decoration: kDashboardCardDecoration,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.judges, size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Judge Assignment',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _assignSelected,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.assignment_turned_in_outlined, size: 16),
                  label: const Text('Assign selected'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _judges.length,
              itemBuilder: (BuildContext context, int index) {
                final UserModel judge = _judges[index];
                final String judgeName =
                    '${judge.firstName} ${judge.lastName}'.trim().isEmpty
                        ? judge.userId
                        : '${judge.firstName} ${judge.lastName}'.trim();
                final int workload = _workloadByJudge[judge.userId] ?? 0;
                final bool selected = _selectedJudgeIds.contains(judge.userId);
                final int selectedIdeaCount = _selectedIdeaIds.length;
                final EvaluationAssignmentConflict? sampledConflict =
                    selectedIdeaCount == 1
                        ? _conflictForSingleSelection(judge.userId)
                        : null;
                return CheckboxListTile(
                  value: selected,
                  onChanged: (bool? v) {
                    setState(() {
                      if (v == true) {
                        _selectedJudgeIds.add(judge.userId);
                      } else {
                        _selectedJudgeIds.remove(judge.userId);
                      }
                    });
                  },
                  title: Text(
                    judgeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _workloadPill('$workload ideas'),
                      if (sampledConflict != null && sampledConflict.isConflict)
                        _conflictPill(sampledConflict.reasons.join(', ')),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  EvaluationAssignmentConflict? _conflictForSingleSelection(String judgeId) {
    if (_selectedIdeaIds.length != 1) return null;
    final String ideaId = _selectedIdeaIds.first;
    final _IdeaRowVm? row = _filteredIdeas.cast<_IdeaRowVm?>().firstWhere(
          (_IdeaRowVm? r) => r?.idea.ideaId == ideaId,
          orElse: () => null,
        );
    final UserModel? judge = _judges.cast<UserModel?>().firstWhere(
          (UserModel? u) => u?.userId == judgeId,
          orElse: () => null,
        );
    if (row == null || judge == null) return null;
    return EvaluationAssignmentService.validateConflict(
      judge: judge,
      idea: row.idea,
      team: row.team,
    );
  }

  Widget _workloadPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  Widget _conflictPill(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Text(
        reason,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFBE123C),
        ),
      ),
    );
  }
}
