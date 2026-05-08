import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/enums/team_status.dart';
import '../../models/idea_list_config.dart';
import '../../models/idea_model.dart';
import '../../models/problem_model.dart';
import '../../models/score_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_query_service.dart';
import '../../utils/team_service.dart';
import '../../widgets/idea_card.dart';
import '../../widgets/payment_dialog.dart';
import '../../widgets/attachment_viewer.dart';
import 'dashboard_components.dart';

class IdeasListScreen extends StatefulWidget {
  const IdeasListScreen({
    super.key,
    required this.currentUser,
    required this.config,
  });

  final UserModel currentUser;
  final IdeaListConfig config;

  @override
  State<IdeasListScreen> createState() => _IdeasListScreenState();
}

class _IdeasListScreenState extends State<IdeasListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<List<IdeaListItem>>? _ideasFuture;
  List<IdeaListItem> _lastLoaded = <IdeaListItem>[];

  bool _showFilters = false;
  Set<IdeaStatus> _statusFilters = <IdeaStatus>{};
  Set<String> _problemFilters = <String>{};
  Set<String> _departmentFilters = <String>{};
  IdeaSortType _sort = IdeaSortType.newest;

  @override
  void initState() {
    super.initState();
    _sort = widget.config.enabledSorts.contains(IdeaSortType.newest)
        ? IdeaSortType.newest
        : widget.config.enabledSorts.first;
    _loadIdeas();
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadIdeas);
  }

  void _loadIdeas() {
    setState(() {
      _ideasFuture = IdeaQueryService.fetchIdeas(
        IdeaQueryParams(
          config: widget.config,
          search: _searchController.text,
          sortType: _sort,
          statusFilters: _statusFilters,
          problemFilters: _problemFilters,
          departmentFilters: _departmentFilters,
          viewer: widget.currentUser,
        ),
      );
    });
  }

  Future<void> _openSubmitIdeaDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _SubmitIdeaDialog(currentUser: widget.currentUser),
    );
    if (created == true && mounted) _loadIdeas();
  }

  Future<void> _openEvaluateDialog(IdeaListItem item) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EvaluateIdeaDialog(
        currentUser: widget.currentUser,
        item: item,
      ),
    );
    if (updated == true && mounted) _loadIdeas();
  }

  Future<void> _showIdeaDetails(IdeaListItem item) async {
    final showPay = widget.config.canUploadPayment && item.canUploadPayment;
    final isCoordinator = UserRole.fromCode(widget.currentUser.role) == UserRole.coordinator;
    final canVerifyPayment = isCoordinator &&
        item.payment != null &&
        item.payment!.status == PaymentRecordStatus.pending;
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
                if (item.score != null) Text('Score: ${item.score!.score.toStringAsFixed(1)} / 10'),
                if (item.score != null && item.score!.feedback.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Feedback: ${item.score!.feedback}'),
                ],
                const SizedBox(height: 12),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (item.payment == null)
                  const Text('No payment uploaded yet.')
                else ...<Widget>[
                  Text('Amount: ${item.payment!.amount.toStringAsFixed(2)}'),
                  Text('Status: ${_paymentStatusLabel(item.payment!.status)}'),
                  if ((item.payment!.transactionId ?? '').trim().isNotEmpty)
                    Text('Transaction ID: ${item.payment!.transactionId}'),
                  if (item.payment!.paymentProofUrl.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.payment!.paymentProofUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  AttachmentPreviewRow(
                    entityType: AttachmentEntityType.payment,
                    entityId: item.payment!.paymentId,
                    title: 'Payment Attachments',
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(item.idea.description.isEmpty ? '-' : item.idea.description),
                const SizedBox(height: 12),
                AttachmentPreviewRow(
                  entityType: AttachmentEntityType.idea,
                  entityId: item.idea.ideaId,
                  title: 'Idea Attachments',
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          if (showPay && item.team != null)
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _openUploadPayment(item);
              },
              icon: const Icon(Icons.payment_outlined, size: 16),
              label: const Text('Upload Payment'),
            ),
          if (canVerifyPayment) ...<Widget>[
            FilledButton(
              onPressed: () async {
                await FirestoreUtils.verifyIdeaPayment(
                  paymentId: item.payment!.paymentId,
                  coordinatorId: widget.currentUser.userId,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (mounted) _loadIdeas();
              },
              child: const Text('Approve payment'),
            ),
            OutlinedButton(
              onPressed: () async {
                final remarks = await showDialog<String>(
                  context: dialogContext,
                  builder: (rejCtx) {
                    final c = TextEditingController();
                    return AlertDialog(
                      title: const Text('Reject payment'),
                      content: TextField(
                        controller: c,
                        decoration: const InputDecoration(
                          labelText: 'Remarks (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.of(rejCtx).pop(), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.of(rejCtx).pop(c.text.trim()),
                          child: const Text('Reject'),
                        ),
                      ],
                    );
                  },
                );
                if (remarks == null) return;
                await FirestoreUtils.rejectIdeaPayment(
                  paymentId: item.payment!.paymentId,
                  coordinatorId: widget.currentUser.userId,
                  remarks: remarks.isEmpty ? null : remarks,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (mounted) _loadIdeas();
              },
              child: const Text('Reject payment'),
            ),
          ],
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUploadPayment(IdeaListItem item) async {
    final team = item.team;
    if (team == null) return;
    final ok = await showPaymentDialog(
      context: context,
      currentUser: widget.currentUser,
      idea: item.idea,
      team: team,
    );
    if (ok == true && mounted) _loadIdeas();
  }

  String _paymentStatusLabel(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.verified:
        return 'Verified';
      case PaymentRecordStatus.rejected:
        return 'Rejected';
    }
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilters = <IdeaStatus>{};
      _problemFilters = <String>{};
      _departmentFilters = <String>{};
    });
    _loadIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IdeaListItem>>(
      future: _ideasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load ideas: ${snapshot.error}');
        }
        final ideas = snapshot.data ?? _lastLoaded;
        _lastLoaded = ideas;
        final availableProblems = <String, String>{
          for (final item in ideas)
            if (item.idea.problemId.isNotEmpty)
              item.idea.problemId: item.idea.problemTitle.isEmpty
                  ? item.idea.problemId
                  : '${item.idea.problemNumber.isEmpty ? '' : '${item.idea.problemNumber} - '}${item.idea.problemTitle}',
        };
        final availableDepartments = ideas
            .map((e) => e.idea.departmentCode)
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

        final listWidget = ideas.isEmpty
            ? const Center(
                child: Text('No ideas found for the selected criteria.'),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: ideas.length,
                itemBuilder: (context, index) {
                  final item = ideas[index];
                  final showPay = widget.config.canUploadPayment && item.canUploadPayment;
                  final canEval = widget.config.canEvaluate && item.idea.status != IdeaStatus.pendingSubmission;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IdeaCard(
                      key: ValueKey(item.idea.ideaId),
                      item: item,
                      canEvaluate: canEval,
                      canViewStatus: widget.config.canViewStatus,
                      onViewDetails: () => _showIdeaDetails(item),
                      onEvaluate: canEval ? () => _openEvaluateDialog(item) : null,
                      showUploadPayment: showPay,
                      onUploadPayment: showPay && item.team != null ? () => _openUploadPayment(item) : null,
                    ),
                  );
                },
              );
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            return SectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSearchAndFilterRow(),
                  const SizedBox(height: 12),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildFiltersPanel(
                      availableProblems: availableProblems,
                      availableDepartments: availableDepartments,
                    ),
                    crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                  if (_hasAnyActiveFilter) ...<Widget>[
                    const SizedBox(height: 12),
                    _buildActiveFiltersRow(availableProblems),
                  ],
                  const SizedBox(height: 12),
                  _buildSortAndCountBar(ideas.length),
                  const SizedBox(height: 12),
                  if (hasBoundedHeight)
                    Expanded(child: listWidget)
                  else
                    SizedBox(
                      height: 420,
                      child: listWidget,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Ideas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.config.canCreateIdea)
          FilledButton.icon(
            onPressed: _openSubmitIdeaDialog,
            icon: const Icon(AppIcons.add),
            label: const Text('Submit Idea'),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by problem number, title, description',
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
        OutlinedButton.icon(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: const Icon(Icons.tune),
          label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersPanel({
    required Map<String, String> availableProblems,
    required List<String> availableDepartments,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.config.enabledFilters.contains(IdeaFilterType.status)) ...<Widget>[
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IdeaStatus.values
                  .map(
                    (status) => FilterChip(
                      label: Text(_statusLabel(status)),
                      selected: _statusFilters.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _statusFilters.add(status);
                          } else {
                            _statusFilters.remove(status);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(IdeaFilterType.problem)) ...<Widget>[
            const Text('Problem', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _problemFilters.length == 1 ? _problemFilters.first : null,
              isExpanded: true,
              items: availableProblems.entries
                  .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _problemFilters = value == null ? <String>{} : <String>{value};
              }),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: 'Select problem',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(IdeaFilterType.department) &&
              !widget.config.restrictToDepartment) ...<Widget>[
            const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableDepartments
                  .map(
                    (d) => FilterChip(
                      label: Text(d),
                      selected: _departmentFilters.contains(d),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _departmentFilters.add(d);
                          } else {
                            _departmentFilters.remove(d);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: _clearAllFilters, child: const Text('Clear All')),
              const SizedBox(width: 6),
              FilledButton(onPressed: _loadIdeas, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow(Map<String, String> problems) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ..._statusFilters.map(
          (status) => InputChip(
            label: Text(_statusLabel(status)),
            onDeleted: () {
              setState(() => _statusFilters.remove(status));
              _loadIdeas();
            },
          ),
        ),
        ..._problemFilters.map(
          (problemId) => InputChip(
            label: Text(problems[problemId] ?? problemId),
            onDeleted: () {
              setState(() => _problemFilters.remove(problemId));
              _loadIdeas();
            },
          ),
        ),
        ..._departmentFilters.map(
          (dep) => InputChip(
            label: Text(dep),
            onDeleted: () {
              setState(() => _departmentFilters.remove(dep));
              _loadIdeas();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortAndCountBar(int count) {
    const order = <IdeaSortType>[
      IdeaSortType.newest,
      IdeaSortType.oldest,
      IdeaSortType.status,
      IdeaSortType.score,
    ];
    final availableSorts = order.where((sort) => widget.config.enabledSorts.contains(sort)).toList(growable: false);
    return Row(
      children: <Widget>[
        Text('$count Ideas', style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        const Text('Sort:'),
        const SizedBox(width: 8),
        DropdownButton<IdeaSortType>(
          value: _sort,
          items: availableSorts
              .map((sort) => DropdownMenuItem<IdeaSortType>(value: sort, child: Text(_sortLabel(sort))))
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _sort = value);
            _loadIdeas();
          },
        ),
      ],
    );
  }

  String _sortLabel(IdeaSortType type) {
    switch (type) {
      case IdeaSortType.newest:
        return 'Newest';
      case IdeaSortType.oldest:
        return 'Oldest';
      case IdeaSortType.status:
        return 'Status';
      case IdeaSortType.score:
        return 'Score';
    }
  }

  String _statusLabel(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return 'Pending Submission';
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

  bool get _hasAnyActiveFilter =>
      _statusFilters.isNotEmpty || _problemFilters.isNotEmpty || _departmentFilters.isNotEmpty;
}

class _EvaluateIdeaDialog extends StatefulWidget {
  const _EvaluateIdeaDialog({
    required this.currentUser,
    required this.item,
  });

  final UserModel currentUser;
  final IdeaListItem item;

  @override
  State<_EvaluateIdeaDialog> createState() => _EvaluateIdeaDialogState();
}

class _EvaluateIdeaDialogState extends State<_EvaluateIdeaDialog> {
  late double _score;
  final TextEditingController _feedbackController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _score = widget.item.score?.score ?? 5;
    _feedbackController.text = widget.item.score?.feedback ?? '';
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.item.idea.status == IdeaStatus.pendingSubmission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This idea is pending payment verification before it can be evaluated.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance.collection(FirestoreUtils.hkzScores);
      final existing = await col
          .where('ideaId', isEqualTo: widget.item.idea.ideaId)
          .where('judgeId', isEqualTo: widget.currentUser.userId)
          .limit(1)
          .get();
      final payload = ScoreModel(
        scoreId: existing.docs.isEmpty ? '' : existing.docs.first.id,
        ideaId: widget.item.idea.ideaId,
        judgeId: widget.currentUser.userId,
        score: _score,
        feedback: _feedbackController.text.trim(),
        createdAt: DateTime.now(),
        orgId: widget.currentUser.orgId,
        departmentCode: widget.item.idea.departmentCode,
      );
      if (existing.docs.isEmpty) {
        final doc = col.doc();
        await doc.set(payload.copyWith(scoreId: doc.id).toMap());
      } else {
        await col.doc(existing.docs.first.id).update(payload.toMap());
      }
      await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzIdeas)
          .doc(widget.item.idea.ideaId)
          .update(<String, dynamic>{'status': IdeaStatus.evaluated.value});
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Evaluate Idea'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Score: ${_score.toStringAsFixed(1)} / 10'),
            Slider(
              value: _score,
              min: 1,
              max: 10,
              divisions: 18,
              label: _score.toStringAsFixed(1),
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class _SubmitIdeaDialog extends StatefulWidget {
  const _SubmitIdeaDialog({
    required this.currentUser,
  });

  final UserModel currentUser;

  @override
  State<_SubmitIdeaDialog> createState() => _SubmitIdeaDialogState();
}

class _SubmitIdeaDialogState extends State<_SubmitIdeaDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _filesController = TextEditingController();
  bool _saving = false;
  List<TeamModel> _teams = <TeamModel>[];
  TeamModel? _selectedTeam;
  List<ProblemModel> _problems = <ProblemModel>[];
  ProblemModel? _selectedProblem;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _filesController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      TeamService.getFacultyTeams(widget.currentUser.userId),
      FirestoreUtils.getProblemModelsByCollege(widget.currentUser.orgId),
    ]);
    final teams = results[0] as List<TeamModel>;
    final problems = results[1] as List<ProblemModel>;
    if (!mounted) return;
    setState(() {
      _teams = teams.where((t) => t.status != TeamStatus.inactive).toList(growable: false);
      _problems = problems;
      if (teams.isNotEmpty) _selectedTeam = teams.first;
      if (problems.isNotEmpty) _selectedProblem = problems.first;
    });
  }

  Future<void> _submit() async {
    if (_selectedTeam == null || _selectedProblem == null || _descriptionController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await TeamService.validateIdeaCreation(
        teamId: _selectedTeam!.teamId,
        problemId: _selectedProblem!.problemId,
      );
      final dept = _selectedProblem!.departmentCode.trim().toUpperCase();
      final doc = FirebaseFirestore.instance.collection(FirestoreUtils.hkzIdeas).doc();
      final files = _filesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      final idea = IdeaModel(
        ideaId: doc.id,
        problemId: _selectedProblem!.problemId,
        teamId: _selectedTeam!.teamId,
        description: _descriptionController.text.trim(),
        files: files,
        status: IdeaStatus.pendingSubmission,
        createdAt: DateTime.now(),
        orgId: widget.currentUser.orgId,
        departmentCode: dept,
        problemNumber: _selectedProblem!.problemNumber,
        problemTitle: _selectedProblem!.title,
        createdBy: widget.currentUser.userId,
      );
      final batch = FirebaseFirestore.instance.batch();
      batch.set(doc, idea.toMap());
      batch.set(
        FirebaseFirestore.instance.collection(FirestoreUtils.hkzTeams).doc(_selectedTeam!.teamId),
        <String, dynamic>{'status': TeamStatus.locked.value},
        SetOptions(merge: true),
      );
      await batch.commit();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Idea'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedTeam?.teamId,
              isExpanded: true,
              items: _teams
                  .map(
                    (team) => DropdownMenuItem<String>(
                      value: team.teamId,
                      child: Text(team.teamName),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedTeam = _teams.firstWhere((t) => t.teamId == value));
              },
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedProblem?.problemId,
              isExpanded: true,
              items: _problems
                  .map(
                    (problem) => DropdownMenuItem<String>(
                      value: problem.problemId,
                      child: Text('${problem.problemNumber} • ${problem.title}'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedProblem = _problems.firstWhere((p) => p.problemId == value));
              },
              decoration: const InputDecoration(
                labelText: 'Problem',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Idea Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _filesController,
              decoration: const InputDecoration(
                labelText: 'Files (comma-separated URLs, optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Submitting...' : 'Submit'),
        ),
      ],
    );
  }
}

extension on ScoreModel {
  ScoreModel copyWith({
    String? scoreId,
  }) {
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
