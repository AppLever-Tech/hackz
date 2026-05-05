import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
import '../../models/problem_model.dart';
import '../../models/score_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/problem_detail_config.dart';
import '../../utils/problem_detail_query_service.dart';
import '../../widgets/filter_pill.dart';
import '../../widgets/idea_card.dart';
import 'dashboard_components.dart';

enum _ProblemDetailTab { details, ideas }

class ProblemDetailScreen extends StatefulWidget {
  const ProblemDetailScreen({
    super.key,
    required this.problem,
    required this.currentUser,
  });

  final ProblemModel problem;
  final UserModel currentUser;

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  _ProblemDetailTab _selectedTab = _ProblemDetailTab.details;
  IdeaStatus? _statusFilter;
  bool _hasScoreOnly = false;
  bool _descriptionExpanded = false;

  late final ProblemDetailConfig _config;
  Future<List<ProblemIdeaAggregate>>? _ideasFuture;
  List<ProblemIdeaAggregate> _loadedIdeas = <ProblemIdeaAggregate>[];

  @override
  void initState() {
    super.initState();
    _config = ProblemDetailRoleConfig.configFor(widget.currentUser);
    _ideasFuture = _loadIdeas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () => setState(() {}));
  }

  Future<List<ProblemIdeaAggregate>> _loadIdeas() {
    return ProblemDetailQueryService.fetchIdeasForProblem(
      problemId: widget.problem.problemId,
      orgId: widget.problem.orgId,
      config: _config,
      currentUser: widget.currentUser,
    );
  }

  Future<void> _refreshIdeas() async {
    final ideas = await _loadIdeas();
    if (!mounted) return;
    setState(() {
      _loadedIdeas = ideas;
      _ideasFuture = Future<List<ProblemIdeaAggregate>>.value(ideas);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problem = widget.problem;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        titleSpacing: 0,
        title: Text(
          'Problem Details',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SectionContainer(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(problem),
                const SizedBox(height: 10),
                _buildMetaRow(problem),
                const SizedBox(height: 10),
                _buildTabPills(),
                const SizedBox(height: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _selectedTab == _ProblemDetailTab.details
                        ? _buildDetailsTab()
                        : _buildIdeasTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProblemModel problem) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            problem.problemNumber.trim().isEmpty ? 'N/A' : problem.problemNumber.trim(),
            style: const TextStyle(
              color: Color(0xFF3345A6),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          tooltip: 'Refresh ideas',
          onPressed: _refreshIdeas,
          icon: const Icon(AppIcons.refresh),
        ),
      ],
    );
  }

  Widget _buildMetaRow(ProblemModel problem) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _metaPill(problem.departmentDisplayName.trim().isEmpty ? '-' : problem.departmentDisplayName),
        _metaPill(problem.category.trim().isEmpty ? 'Category: -' : 'Category: ${problem.category}'),
        _metaPill(problem.theme.trim().isEmpty ? 'Theme: -' : 'Theme: ${problem.theme}'),
      ],
    );
  }

  Widget _buildTabPills() {
    return Row(
      children: <Widget>[
        FilterPill(
          selected: _selectedTab == _ProblemDetailTab.details,
          icon: AppIcons.problems,
          label: 'Details',
          count: 1,
          onTap: () => setState(() => _selectedTab = _ProblemDetailTab.details),
        ),
        const SizedBox(width: 8),
        FilterPill(
          selected: _selectedTab == _ProblemDetailTab.ideas,
          icon: AppIcons.ideas,
          label: 'Ideas',
          count: _loadedIdeas.length,
          onTap: () => setState(() => _selectedTab = _ProblemDetailTab.ideas),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return FutureBuilder<List<ProblemIdeaAggregate>>(
      future: _ideasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _loadedIdeas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final ideas = snapshot.data ?? _loadedIdeas;
        if (snapshot.hasData) _loadedIdeas = snapshot.data!;

        final evaluated = ideas.where((e) => e.hasScore).length;
        final scoredIdeas = ideas.where((e) => e.avgScore != null).toList(growable: false);
        final avg = scoredIdeas.isEmpty
            ? null
            : scoredIdeas.map((e) => e.avgScore!).reduce((a, b) => a + b) / scoredIdeas.length;

        return ListView(
          key: const ValueKey<String>('problem-detail-details'),
          padding: EdgeInsets.zero,
          children: <Widget>[
            SectionContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.problem.description.trim().isEmpty
                        ? 'No description provided.'
                        : widget.problem.description.trim(),
                    maxLines: _descriptionExpanded ? null : 3,
                    overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (widget.problem.description.trim().length > 180)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                        child: Text(_descriptionExpanded ? 'Show less' : 'Show more'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _metaPill(widget.problem.category.trim().isEmpty ? 'Category: -' : widget.problem.category),
                      _metaPill(widget.problem.theme.trim().isEmpty ? 'Theme: -' : widget.problem.theme),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Metadata',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('Department: ${widget.problem.departmentDisplayName}'),
                  const SizedBox(height: 4),
                  Text('Created by: ${widget.problem.createdBy.trim().isEmpty ? '-' : widget.problem.createdBy}'),
                  const SizedBox(height: 4),
                  Text('Created on: ${_formatDate(widget.problem.createdAt)}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (widget.problem.attachments.isEmpty)
                    const Text('No attachments available.')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.problem.attachments
                            .map(
                              (attachment) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.attach_file, size: 16),
                                  label: SizedBox(
                                    width: 180,
                                    child: Text(
                                      attachment,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onPressed: () => _showAttachmentPreview(attachment),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionContainer(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(child: _miniStat('Total Ideas', '${ideas.length}')),
                  Expanded(child: _miniStat('Evaluated', '$evaluated')),
                  Expanded(child: _miniStat('Avg Score', avg == null ? '-' : avg.toStringAsFixed(1))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdeasTab() {
    return FutureBuilder<List<ProblemIdeaAggregate>>(
      future: _ideasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _loadedIdeas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) _loadedIdeas = snapshot.data!;
        final allItems = snapshot.data ?? _loadedIdeas;
        final visibleItems = _applyIdeaFilters(allItems);

        return Column(
          key: const ValueKey<String>('problem-detail-ideas'),
          children: <Widget>[
            _buildIdeasSearchAndFilters(visibleItems.length),
            const SizedBox(height: 10),
            Expanded(
              child: visibleItems.isEmpty
                  ? const Center(child: Text('No ideas found for this problem.'))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final entry = visibleItems[index];
                        final isJudge = UserRole.fromCode(widget.currentUser.role) == UserRole.judge;
                        final canEvaluate =
                            isJudge && entry.item.idea.status != IdeaStatus.pendingSubmission;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (entry.mentorId.trim().isNotEmpty || entry.studentCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      if (entry.studentCount > 0) _metaPill('Students: ${entry.studentCount}'),
                                      if (entry.mentorId.trim().isNotEmpty)
                                        _metaPill('Mentor: ${entry.mentorId}'),
                                      if (entry.scoreCount > 0)
                                        _metaPill(
                                          'Avg: ${entry.avgScore?.toStringAsFixed(1) ?? '-'} (${entry.scoreCount})',
                                        ),
                                    ],
                                  ),
                                ),
                              IdeaCard(
                                item: entry.item,
                                canViewStatus: true,
                                canEvaluate: canEvaluate,
                                onViewDetails: () => _showIdeaDetails(entry),
                                onEvaluate: canEvaluate ? () => _openEvaluateDialog(entry) : null,
                                showUploadPayment: false,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdeasSearchAndFilters(int visibleCount) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by team or idea description',
                  prefixIcon: const Icon(AppIcons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$visibleCount ideas', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              FilterPill(
                selected: _statusFilter == null,
                icon: AppIcons.ideas,
                label: 'All',
                count: _loadedIdeas.length,
                onTap: () => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 8),
              ...IdeaStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterPill(
                    selected: _statusFilter == status,
                    icon: AppIcons.verification,
                    label: _statusLabel(status),
                    count: _loadedIdeas.where((e) => e.item.idea.status == status).length,
                    onTap: () => setState(() => _statusFilter = status),
                  ),
                ),
              ),
              FilterPill(
                selected: _hasScoreOnly,
                icon: AppIcons.scoring,
                label: 'Has Score',
                count: _loadedIdeas.where((e) => e.hasScore).length,
                onTap: () => setState(() => _hasScoreOnly = !_hasScoreOnly),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ProblemIdeaAggregate> _applyIdeaFilters(List<ProblemIdeaAggregate> items) {
    final search = _searchController.text.trim().toLowerCase();
    return items.where((entry) {
      if (_statusFilter != null && entry.item.idea.status != _statusFilter) return false;
      if (_hasScoreOnly && !entry.hasScore) return false;
      if (search.isEmpty) return true;
      final inTeam = entry.item.teamName.toLowerCase().contains(search);
      final inDesc = entry.item.idea.description.toLowerCase().contains(search);
      return inTeam || inDesc;
    }).toList(growable: false);
  }

  Future<void> _showAttachmentPreview(String url) async {
    final lower = url.toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attachment'),
        content: SizedBox(
          width: 480,
          child: isImage
              ? Image.network(url, fit: BoxFit.contain)
              : SelectableText(url),
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showIdeaDetails(ProblemIdeaAggregate entry) async {
    final item = entry.item;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.idea.problemTitle.isEmpty ? 'Idea Details' : item.idea.problemTitle),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Problem Number: ${item.idea.problemNumber.isEmpty ? '-' : item.idea.problemNumber}'),
                const SizedBox(height: 8),
                Text('Status: ${_statusLabel(item.idea.status)}'),
                const SizedBox(height: 8),
                Text('Team: ${item.teamName.isEmpty ? '-' : item.teamName}'),
                const SizedBox(height: 8),
                Text('Average score: ${entry.avgScore?.toStringAsFixed(1) ?? '-'}'),
                const SizedBox(height: 8),
                Text('Description: ${item.idea.description.isEmpty ? '-' : item.idea.description}'),
                if (item.idea.files.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  const Text('Files', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ...item.idea.files.map((file) => Text('• $file')),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEvaluateDialog(ProblemIdeaAggregate entry) async {
    final scoreController = TextEditingController();
    scoreController.text = entry.avgScore?.toStringAsFixed(1) ?? '5.0';
    final feedbackController = TextEditingController();
    bool saving = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Evaluate Idea'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: scoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Score (1-10)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              OutlinedButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final parsed = double.tryParse(scoreController.text.trim());
                        if (parsed == null || parsed < 1 || parsed > 10) return;
                        setStateDialog(() => saving = true);
                        try {
                          final col = FirebaseFirestore.instance.collection(FirestoreUtils.hkzScores);
                          final existing = await col
                              .where('ideaId', isEqualTo: entry.item.idea.ideaId)
                              .where('judgeId', isEqualTo: widget.currentUser.userId)
                              .limit(1)
                              .get();
                          final score = ScoreModel(
                            scoreId: existing.docs.isEmpty ? '' : existing.docs.first.id,
                            ideaId: entry.item.idea.ideaId,
                            judgeId: widget.currentUser.userId,
                            score: parsed,
                            feedback: feedbackController.text.trim(),
                            createdAt: DateTime.now(),
                            orgId: widget.currentUser.orgId,
                            departmentCode: entry.item.idea.departmentCode,
                          );
                          if (existing.docs.isEmpty) {
                            final doc = col.doc();
                            await doc.set(score.copyWith(scoreId: doc.id).toMap());
                          } else {
                            await col.doc(existing.docs.first.id).update(score.toMap());
                          }
                          await FirebaseFirestore.instance
                              .collection(FirestoreUtils.hkzIdeas)
                              .doc(entry.item.idea.ideaId)
                              .update(<String, dynamic>{'status': IdeaStatus.evaluated.value});
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                        } finally {
                          if (dialogContext.mounted) setStateDialog(() => saving = false);
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        );
      },
    );

    scoreController.dispose();
    feedbackController.dispose();
    if (ok == true) {
      await _refreshIdeas();
    }
  }

  Widget _metaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  String _statusLabel(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return 'Pending';
      case IdeaStatus.submitted:
        return 'Submitted';
      case IdeaStatus.underReview:
        return 'Under Review';
      case IdeaStatus.evaluated:
        return 'Evaluated';
      case IdeaStatus.approved:
        return 'Approved';
      case IdeaStatus.rejected:
        return 'Rejected';
    }
  }
}

extension on ScoreModel {
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
