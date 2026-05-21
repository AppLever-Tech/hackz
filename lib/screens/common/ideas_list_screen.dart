import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_list_config.dart';
import '../../models/idea_model.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../utils/idea_query_service.dart';
import '../../utils/role_visibility_helpers.dart';
import '../../widgets/idea_card.dart';
import '../../widgets/payment_dialog.dart';
import '../../widgets/attachment_viewer.dart';
import '../../widgets/faculty/submit_idea_dialog.dart';
import '../../widgets/judge/evaluate_idea_dialog.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/responsive_list_detail_layout.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../workspace/workspace.dart';
import 'app_dialog_template.dart';
import 'dashboard_components.dart';
import 'idea_detail_screen.dart';

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

  Future<IdeaListQueryResult>? _ideasFuture;
  List<IdeaListItem> _lastLoaded = <IdeaListItem>[];
  IdeaDepartmentMetrics _metrics = IdeaDepartmentMetrics.empty;

  bool _showFilters = false;
  Set<IdeaStatus> _statusFilters = <IdeaStatus>{};
  Set<String> _problemFilters = <String>{};
  Set<String> _departmentFilters = <String>{};
  IdeaSortType _sort = IdeaSortType.newest;
  String? _selectedIdeaId;

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
    final created = await showAppDialog<bool>(
      context: context,
      width: DialogWidthPreset.wide,
      child: SubmitIdeaDialog(currentUser: widget.currentUser),
    );
    if (created == true && mounted) _loadIdeas();
  }

  Future<void> _openEvaluateDialog(IdeaListItem item) async {
    final updated = await EvaluateIdeaDialog.showForIdeaListItem(
      context,
      judge: widget.currentUser,
      item: item,
    );
    if (updated == true && mounted) _loadIdeas();
  }

  Future<void> _showIdeaDetails(IdeaListItem item) async {
    setState(() => _selectedIdeaId = item.idea.ideaId);
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
    if (!widget.config.canViewIdeas) {
      return const Center(
        child: Text('Ideas are not available for your role.'),
      );
    }
    return FutureBuilder<IdeaListQueryResult>(
      future: _ideasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load ideas: ${snapshot.error}');
        }
        final IdeaListQueryResult result = snapshot.data ??
            IdeaListQueryResult(items: _lastLoaded, metrics: _metrics);
        final ideas = result.items;
        _lastLoaded = ideas;
        _metrics = result.metrics;
        final availableProblems = <String, String>{
          for (final item in ideas)
            if (item.idea.problemId.isNotEmpty)
              item.idea.problemId: item.idea.problemTitle.isEmpty
                  ? item.idea.problemId
                  : '${item.idea.problemNumber.isEmpty ? '' : '${item.idea.problemNumber} - '}${item.idea.problemTitle}',
        };
        final availableDepartments = ideas
            .map((e) => e.idea.teamDepartmentCode)
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showIdeaDetails(item),
                      child: IdeaCard(
                        key: ValueKey(item.idea.ideaId),
                        item: item,
                        onOpenIdea: () => WorkspaceNavigator.openIdea(context, item.idea.ideaId),
                        onOpenProblem: item.idea.problemId.trim().isEmpty
                            ? null
                            : () => WorkspaceNavigator.openProblem(context, item.idea.problemId),
                        onOpenTeam: () {
                          final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
                          if (teamId.isEmpty) return;
                          WorkspaceNavigator.openTeam(context, teamId);
                        },
                        onOpenPayment: item.payment == null
                            ? null
                            : () => WorkspaceNavigator.openPayment(context, item.payment!.paymentId),
                        onOpenEvaluation: _canOpenEvaluation(item)
                            ? () => WorkspaceNavigator.openEvaluation(context, item.idea.ideaId)
                            : null,
                        onOpenAttachments: item.attachmentCount > 0
                            ? () => _openAttachments(context, item)
                            : null,
                        showEvaluate: canEval,
                        onEvaluate: canEval ? () => _openEvaluateDialog(item) : null,
                        showUploadPayment: showPay,
                        onUploadPayment: showPay && item.team != null ? () => _openUploadPayment(item) : null,
                      ),
                    ),
                  );
                },
              );
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final listPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildMetricsRow(_metrics),
                const SizedBox(height: 12),
                _buildToolbar(context),
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
                if (hasBoundedHeight)
                  Expanded(child: listWidget)
                else
                  SizedBox(height: 420, child: listWidget),
              ],
            );

            final selectedId = _selectedIdeaId;
            return ResponsiveListDetailLayout(
              hasSelection: selectedId != null,
              onCloseDetail: () => setState(() => _selectedIdeaId = null),
              backLabel: 'Back to Ideas',
              list: listPanel,
              detail: selectedId == null
                  ? const SizedBox.shrink()
                  : IdeaDetailScreen(
                      key: ValueKey<String>(selectedId),
                      ideaId: selectedId,
                      currentUser: widget.currentUser,
                      embedded: true,
                      onBack: () => setState(() => _selectedIdeaId = null),
                    ),
            );
          },
        );
      },
    );
  }

  bool _canOpenEvaluation(IdeaListItem item) {
    if (item.score != null) return true;
    return item.idea.status == IdeaStatus.evaluated ||
        item.idea.status == IdeaStatus.approved ||
        item.idea.status == IdeaStatus.underReview;
  }

  void _openAttachments(BuildContext context, IdeaListItem item) {
    final String? id = item.firstAttachmentId?.trim();
    if (item.attachmentCount == 1 && id != null && id.isNotEmpty) {
      WorkspaceNavigator.openAttachment(context, id);
      return;
    }
    WorkspaceNavigator.openIdea(context, item.idea.ideaId);
  }

  Widget _buildMetricsRow(IdeaDepartmentMetrics metrics) {
    return ResponsiveMetricGrid(
      spacing: 10,
      runSpacing: 10,
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Ideas',
          value: '${metrics.total}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.ideas,
          subtitle: metrics.pendingSubmission > 0 ? '${metrics.pendingSubmission} pending' : null,
        ),
        DashboardMetricChipData.single(
          label: 'Submitted',
          value: '${metrics.submitted}',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.submissions,
        ),
        DashboardMetricChipData.single(
          label: 'Approved',
          value: '${metrics.approved}',
          color: const Color(0xFF059669),
          icon: AppIcons.statusApproved,
        ),
        DashboardMetricChipData.single(
          label: 'Evaluated',
          value: '${metrics.evaluated}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.scoring,
        ),
      ],
    );
  }

  ButtonStyle _toolbarButtonStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: const Color(0xFFFCFDFF),
        side: const BorderSide(color: Color(0xFFD9E2F5), width: 1.2),
        disabledForegroundColor: const Color(0xFF334155),
        disabledBackgroundColor: const Color(0xFFFCFDFF),
      );

  Widget _buildToolbar(BuildContext context) {
    final filterButton = OutlinedButton.icon(
      onPressed: () => setState(() => _showFilters = !_showFilters),
      icon: const Icon(Icons.tune),
      label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
      style: _toolbarButtonStyle(context),
    );

    final sortButton = _buildSortButton(context);

    final submitButton = widget.config.canCreateIdea
        ? FilledButton.icon(
            onPressed: _openSubmitIdeaDialog,
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Submit Idea'),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : null;

    final searchField = TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadIdeas(),
      decoration: InputDecoration(
        hintText: 'Search by idea title, problem, or description',
        prefixIcon: const Icon(AppIcons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: ResponsiveHelper.isMobile(context) ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    if (ResponsiveHelper.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          searchField,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (submitButton != null) submitButton,
              filterButton,
              sortButton,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (submitButton != null) ...<Widget>[
          submitButton,
          const SizedBox(width: 8),
        ],
        Expanded(child: searchField),
        const SizedBox(width: 8),
        filterButton,
        const SizedBox(width: 8),
        sortButton,
      ],
    );
  }

  Widget _buildSortButton(BuildContext context) {
    const order = <IdeaSortType>[
      IdeaSortType.newest,
      IdeaSortType.oldest,
      IdeaSortType.status,
      IdeaSortType.score,
    ];
    final availableSorts =
        order.where((IdeaSortType sort) => widget.config.enabledSorts.contains(sort)).toList(growable: false);

    return MenuAnchor(
      style: const MenuStyle(
        visualDensity: VisualDensity.compact,
      ),
      menuChildren: availableSorts
          .map(
            (IdeaSortType sort) => MenuItemButton(
              onPressed: () {
                setState(() => _sort = sort);
                _loadIdeas();
              },
              child: Text(_sortLabel(sort)),
            ),
          )
          .toList(growable: false),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.swap_vert),
          label: Text(_sortLabel(_sort)),
          style: _toolbarButtonStyle(context),
        );
      },
    );
  }

  Widget _buildFiltersPanel({
    required Map<String, String> availableProblems,
    required List<String> availableDepartments,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration.copyWith(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.config.enabledFilters.contains(IdeaFilterType.status)) ...<Widget>[
            Row(
              children: const <Widget>[
                Icon(AppIcons.statusUnderReview, size: 18, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IdeaStatus.values
                  .map(
                    (status) => FilterChip(
                      avatar: Icon(_statusIcon(status), size: 16),
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
            Row(
              children: const <Widget>[
                Icon(AppIcons.problems, size: 18, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Problem', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
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
                prefixIcon: Icon(AppIcons.problems),
                border: OutlineInputBorder(),
                hintText: 'Select problem',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(IdeaFilterType.department) &&
              widget.config.ideaDepartmentScope == IdeaDepartmentScope.none) ...<Widget>[
            Row(
              children: const <Widget>[
                Icon(AppIcons.departments, size: 18, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableDepartments
                  .map(
                    (d) => FilterChip(
                      avatar: const Icon(AppIcons.departments, size: 16),
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
            avatar: Icon(_statusIcon(status), size: 16),
            label: Text(_statusLabel(status)),
            onDeleted: () {
              setState(() => _statusFilters.remove(status));
              _loadIdeas();
            },
          ),
        ),
        ..._problemFilters.map(
          (problemId) => InputChip(
            avatar: const Icon(AppIcons.problems, size: 16),
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

  IconData _statusIcon(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return AppIcons.statusSubmitted;
      case IdeaStatus.submitted:
        return AppIcons.submissions;
      case IdeaStatus.underReview:
        return AppIcons.statusUnderReview;
      case IdeaStatus.evaluated:
        return AppIcons.statusEvaluated;
      case IdeaStatus.approved:
        return AppIcons.statusApproved;
      case IdeaStatus.rejected:
        return AppIcons.statusRejected;
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
