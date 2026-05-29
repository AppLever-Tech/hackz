import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/brand_colors.dart';
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
  static const double _kPaneHeaderHeight = 56;
  static const double _kPaneToolbarRowHeight = 52;

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

  bool get _allFilteredIdeasSelected {
    final List<_IdeaRowVm> rows = _filteredIdeas;
    return rows.isNotEmpty &&
        rows.every((_IdeaRowVm row) => _selectedIdeaIds.contains(row.idea.ideaId));
  }

  bool? get _ideasSelectAllValue {
    final List<_IdeaRowVm> rows = _filteredIdeas;
    if (rows.isEmpty) return false;
    final int selected =
        rows.where((_IdeaRowVm row) => _selectedIdeaIds.contains(row.idea.ideaId)).length;
    if (selected == 0) return false;
    if (selected == rows.length) return true;
    return null;
  }

  bool get _allJudgesSelected {
    return _judges.isNotEmpty &&
        _judges.every((UserModel judge) => _selectedJudgeIds.contains(judge.userId));
  }

  bool? get _judgesSelectAllValue {
    if (_judges.isEmpty) return false;
    if (_selectedJudgeIds.isEmpty) return false;
    if (_selectedJudgeIds.length == _judges.length) return true;
    return null;
  }

  void _toggleSelectAllIdeas() {
    setState(() {
      final Iterable<String> ids =
          _filteredIdeas.map((_IdeaRowVm row) => row.idea.ideaId);
      if (_allFilteredIdeasSelected) {
        _selectedIdeaIds.removeAll(ids);
      } else {
        _selectedIdeaIds.addAll(ids);
      }
    });
  }

  void _toggleSelectAllJudges() {
    setState(() {
      if (_allJudgesSelected) {
        _selectedJudgeIds.clear();
      } else {
        _selectedJudgeIds
          ..clear()
          ..addAll(_judges.map((UserModel judge) => judge.userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final bool mobile = MediaQuery.sizeOf(context).width < 900;
    if (mobile) {
      return _buildMobileLayout();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      padding: const EdgeInsets.only(bottom: 16),
      children: <Widget>[
        _buildLeftPanel(),
        const SizedBox(height: 12),
        SizedBox(height: 520, child: _buildCenterPanel()),
        const SizedBox(height: 12),
        SizedBox(height: 420, child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildLeftPanel() {
    final ProblemModel? selectedProblem = _selectedProblem;
    final List<_IdeaRowVm> rows = _filteredIdeas;
    final int assigned = rows.where((_IdeaRowVm r) => r.assignedJudgeIds.isNotEmpty).length;
    final int total = rows.length;
    return Container(
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            icon: AppIcons.problems,
            title: 'Problem Summary',
          ),
          _panelToolbarRow(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedProblemId,
              isExpanded: true,
              decoration: _compactRoundedFieldDecoration(hintText: 'Select problem'),
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
          ),
          _panelToolbarDivider,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    selectedProblem?.title.isNotEmpty == true
                        ? selectedProblem!.title
                        : 'Select a problem',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _summaryStatTile('Total ideas', '$total', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                  const SizedBox(height: 6),
                  _summaryStatTile('Assigned', '$assigned', const Color(0xFFECFDF5), const Color(0xFF16A34A)),
                  const SizedBox(height: 6),
                  _summaryStatTile(
                    'Unassigned',
                    '${math.max(0, total - assigned)}',
                    const Color(0xFFFFF7ED),
                    const Color(0xFFEA580C),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  _sectionLabel('Default Filters'),
                  _filterCheckboxRow(
                    label: 'Show unassigned only',
                    value: _onlyUnassigned,
                    onChanged: (bool value) => setState(() => _onlyUnassigned = value),
                  ),
                  _filterCheckboxRow(
                    label: 'Score pending only',
                    value: _onlyPendingScore,
                    onChanged: (bool value) => setState(() => _onlyPendingScore = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Divider _panelToolbarDivider =
      Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0));

  static InputDecoration _compactRoundedFieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF94A3B8), width: 1.3),
      ),
    );
  }

  Widget _panelToolbarRow({required Widget child}) {
    return SizedBox(
      height: _kPaneToolbarRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(child: child),
      ),
    );
  }

  Widget _inlineSelectAllControl({
    required bool? value,
    required VoidCallback onToggle,
    required String label,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                tristate: true,
                value: value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => onToggle(),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelHeader({required IconData icon, required String title, Widget? trailing}) {
    return Container(
      height: _kPaneHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EEF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _summaryStatTile(String label, String value, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _filterCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? checked) => onChanged(checked ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPanel() {
    final List<_IdeaRowVm> rows = _filteredIdeas;
    final int visible = math.min(_visibleCount, rows.length);
    final String selectionLabel = '${_selectedIdeaIds.length} selected';
    return Container(
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(icon: AppIcons.ideas, title: 'Ideas'),
          _panelToolbarRow(
            child: Row(
              children: <Widget>[
                _inlineSelectAllControl(
                  value: _ideasSelectAllValue,
                  onToggle: _toggleSelectAllIdeas,
                  label: 'Select all',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: _compactRoundedFieldDecoration(
                      hintText: 'Search idea, team, or problem',
                    ).copyWith(prefixIcon: const Icon(AppIcons.search, size: 18)),
                    onChanged: (String v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _panelToolbarDivider,
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No ideas match the current filters.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    itemCount: visible + (visible < rows.length ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == visible && visible < rows.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _visibleCount += _pageSize);
                            },
                            child: Text('Load more (${rows.length - visible} remaining)'),
                          ),
                        );
                      }
                      final _IdeaRowVm row = rows[index];
                      final bool selected = _selectedIdeaIds.contains(row.idea.ideaId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ideaRow(row, selected),
                      );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIdeaIds.remove(row.idea.ideaId);
            } else {
              _selectedIdeaIds.add(row.idea.ideaId);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => setState(() {
                    if (selected) {
                      _selectedIdeaIds.remove(row.idea.ideaId);
                    } else {
                      _selectedIdeaIds.add(row.idea.ideaId);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      row.idea.ideaTitle.isEmpty
                          ? row.idea.problemNumber
                          : row.idea.ideaTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$teamName • ${row.idea.problemDepartmentCode} • ${row.idea.status.value}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (row.assignedJudgeIds.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: row.assignedJudgeIds.map((String judgeId) {
                          final UserModel? judge = _judges.cast<UserModel?>().firstWhere(
                                (UserModel? u) => u?.userId == judgeId,
                                orElse: () => null,
                              );
                          final String label = judge == null
                              ? judgeId
                              : ('${judge.firstName} ${judge.lastName}'.trim().isEmpty
                                  ? judge.userId
                                  : '${judge.firstName} ${judge.lastName}'.trim());
                          return InputChip(
                            label: Text(label, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            onDeleted: () =>
                                _removeAssignment(ideaId: row.idea.ideaId, judgeId: judgeId),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.latestScore == null
                      ? '—'
                      : row.latestScore!.score.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    final String selectionLabel = '${_selectedJudgeIds.length} selected';
    return Container(
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panelHeader(
            icon: AppIcons.judges,
            title: 'Judge Assignment',
            trailing: FilledButton.icon(
              onPressed: _saving ? null : _assignSelected,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.primaryActionFill,
                foregroundColor: BrandColors.onPrimaryActionFill,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
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
              label: const Text('Assign'),
            ),
          ),
          _panelToolbarRow(
            child: Row(
              children: <Widget>[
                _inlineSelectAllControl(
                  value: _judgesSelectAllValue,
                  onToggle: _toggleSelectAllJudges,
                  label: 'Select all',
                ),
                const Spacer(),
                Text(
                  selectionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _panelToolbarDivider,
          Expanded(
            child: _judges.isEmpty
                ? const Center(
                    child: Text(
                      'No judges found for this organization.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    itemCount: _judges.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _judgeRow(_judges[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _judgeRow(UserModel judge) {
    final String judgeName = '${judge.firstName} ${judge.lastName}'.trim().isEmpty
        ? judge.userId
        : '${judge.firstName} ${judge.lastName}'.trim();
    final int workload = _workloadByJudge[judge.userId] ?? 0;
    final bool selected = _selectedJudgeIds.contains(judge.userId);
    final EvaluationAssignmentConflict? sampledConflict =
        _selectedIdeaIds.length == 1 ? _conflictForSingleSelection(judge.userId) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedJudgeIds.remove(judge.userId);
            } else {
              _selectedJudgeIds.add(judge.userId);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? v) {
                    setState(() {
                      if (v == true) {
                        _selectedJudgeIds.add(judge.userId);
                      } else {
                        _selectedJudgeIds.remove(judge.userId);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      judgeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _workloadPill('$workload ideas'),
                        if (sampledConflict != null && sampledConflict.isConflict)
                          _conflictPill(sampledConflict.reasons.join(', ')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
