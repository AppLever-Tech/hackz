import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../domain/domain.dart';
import '../../../organization/models/department_model.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/user_model.dart';
import '../../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../../core/responsive/responsive_filter_bar.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/icon_only_filter_button.dart';
import '../../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../../features/dashboard/chrome/empty_search_state.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../core/ui/data_view/data_table_view.dart';
import '../../../idea/screens/innovation_submission_workspace.dart';
import '../../widgets/problem_table_columns.dart';
import '../../../../core/ui/loading/hkz_async_loader.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../org_settings/constants/org_setting_keys.dart';
import '../../../org_settings/services/org_settings_service.dart';
import '../../../imports/models/import_created_source.dart';
import '../../../imports/screens/problems_import_entry.dart';
import '../../../imports/services/import_platform_support.dart';
import '../../models/problem_list_config.dart';
import '../../models/problem_model.dart';
import '../../models/problem_status.dart';
import '../../services/problem_query_service.dart';
import '../../services/problem_status_service.dart';
import '../../validators/problem_submission_validators.dart';
import '../../widgets/problem_filters_panel.dart';
import '../../widgets/problem_metrics_row.dart';
import '../authoring/problem_authoring_workspace.dart';
import 'problem_statement_details_pane.dart';
import '../../../evaluations/workspace/evaluation_assignment_details_pane.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Tabular view of problem statements from [FirestoreUtils.hkzProblems].
class ProblemStatementsTableScreen extends StatefulWidget {
  const ProblemStatementsTableScreen({
    super.key,
    required this.currentUser,
    required this.config,
  });

  final UserModel currentUser;
  final ProblemListConfig config;

  @override
  State<ProblemStatementsTableScreen> createState() => _ProblemStatementsTableScreenState();
}

class _ProblemStatementsTableScreenState extends State<ProblemStatementsTableScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<ProblemListQueryResult>? _problemsFuture;
  List<ProblemModel> _lastLoaded = <ProblemModel>[];
  ProblemDashboardMetrics _metrics = ProblemDashboardMetrics.empty;
  Map<String, int> _ideaCountByProblemId = <String, int>{};
  int _orgDefaultMaxIdeas = 50;
  ProblemSortType _sort = ProblemSortType.newest;

  // Filter state. Defaults to "no filter" (i.e. show everything). The same
  // [ProblemFiltersPanel] / [ProblemActiveFiltersRow] widgets drive both
  // this screen and the dashboard cards layout.
  bool _showFilters = false;
  ProblemStatus? _statusFilter;
  ImportCreatedSource? _sourceFilter;
  bool? _hasAttachments;
  Set<String> _departmentFilters = <String>{};
  Set<String> _domainFilters = <String>{};
  Set<String> _tagFilters = <String>{};
  Map<String, DomainModel> _domainsById = <String, DomainModel>{};
  Map<String, String> _deptIdToCode = <String, String>{};
  bool _groupByDomain = false;

  // Embedded authoring workspace toggles.
  // replaced in-place by [ProblemAuthoringWorkspace] (create or edit mode).
  ProblemModel? _editingProblem;
  bool _showCreateProblem = false;

  @override
  void initState() {
    super.initState();
    _sort = widget.config.enabledSorts.contains(ProblemSortType.newest)
        ? ProblemSortType.newest
        : widget.config.enabledSorts.first;
    _loadProblems();
    _loadOrgDefaultMaxIdeas();
    _loadDomains();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadDomains() async {
    try {
      final List<DomainModel> domains = await DomainService.listByOrg(orgId: widget.config.orgId);
      final Map<String, String> idToCode = await DomainDepartmentResolver.idToCodeMap(widget.config.orgId);
      if (!mounted) return;
      setState(() {
        _domainsById = <String, DomainModel>{
          for (final DomainModel d in domains) d.domainId: d,
        };
        _deptIdToCode = idToCode;
      });
      _loadProblems();
    } catch (_) {
      // Domain enrichment is best-effort.
    }
  }

  /// Reads org-scoped default-max-ideas so the submission gate can resolve
  /// when a problem doesn't carry its own per-problem override.
  Future<void> _loadOrgDefaultMaxIdeas() async {
    try {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.config.orgId);
      if (!mounted) return;
      final Map<String, dynamic> values = OrgSettingsService.instance.valuesSnapshot;
      final int defMax =
          (values[OrgSettingKeys.defaultMaxIdeasPerProblem] as num?)?.toInt() ?? 50;
      if (defMax != _orgDefaultMaxIdeas) {
        setState(() => _orgDefaultMaxIdeas = defMax);
      }
    } catch (_) {
      // Fallback already applied.
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadProblems);
  }

  void _loadProblems() {
    setState(() {
      _problemsFuture = ProblemQueryService.fetchProblems(
        ProblemQueryParams(
          config: widget.config,
          search: _searchController.text,
          sortType: _sort,
          statusFilter: _statusFilter,
          sourceFilter: _sourceFilter,
          departmentFilters: _departmentFilters,
          domainFilters: _domainFilters,
          tagFilters: _tagFilters,
          hasAttachments: _hasAttachments,
          domainsById: <String, String>{
            for (final MapEntry<String, DomainModel> e in _domainsById.entries)
              e.key: '${e.value.code} ${e.value.name}',
          },
        ),
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = null;
      _sourceFilter = null;
      _hasAttachments = null;
      _departmentFilters = <String>{};
      _domainFilters = <String>{};
      _tagFilters = <String>{};
    });
    _loadProblems();
  }

  bool get _hasAnyActiveFilter =>
      _departmentFilters.isNotEmpty ||
      _domainFilters.isNotEmpty ||
      _tagFilters.isNotEmpty ||
      _statusFilter != null ||
      _sourceFilter != null ||
      _hasAttachments != null;

  Future<void> _openCreateProblem() async {
    setState(() {
      _showCreateProblem = true;
      _editingProblem = null;
    });
  }

  Future<void> _openEditProblem(ProblemModel problem) async {
    setState(() {
      _editingProblem = problem;
      _showCreateProblem = false;
    });
  }

  void _closeProblemForm() {
    setState(() {
      _showCreateProblem = false;
      _editingProblem = null;
    });
  }

  Future<void> _onProblemFormSaved() async {
    _closeProblemForm();
    _loadProblems();
  }

  /// Department admins may only edit problems they personally authored;
  /// college admin and sys admin retain blanket edit rights gated by
  /// [ProblemListConfig.canEdit].
  bool _canEditProblem(ProblemModel problem) {
    if (!widget.config.canEdit) return false;
    final role = UserRole.fromCode(widget.currentUser.role);
    if (role == UserRole.departmentAdmin) {
      return problem.createdBy.trim() == widget.currentUser.userId.trim();
    }
    return true;
  }

  bool get _isCollegeAdmin => UserRole.fromCode(widget.currentUser.role) == UserRole.collegeAdmin;

  List<ProblemModel> _activatableProblems(List<ProblemModel> problems) {
    if (!_isCollegeAdmin || !widget.config.canToggleActive) return const <ProblemModel>[];
    return problems
        .where(
          (ProblemModel p) =>
              p.status == ProblemStatus.draft || p.status == ProblemStatus.inactive,
        )
        .toList(growable: false);
  }

  List<ProblemModel> _deletableProblems(List<ProblemModel> problems) {
    if (!_isCollegeAdmin) return const <ProblemModel>[];
    return problems.where(_canDeleteProblem).toList(growable: false);
  }

  Future<void> _activateProblem(ProblemModel problem) async {
    await ProblemStatusService.activate(problem.problemId);
    if (!mounted) return;
    _loadProblems();
  }

  Future<void> _deactivateProblem(ProblemModel problem) async {
    await ProblemStatusService.deactivate(problem.problemId);
    if (!mounted) return;
    _loadProblems();
  }

  Future<void> _openImportProblems() async {
    final bool? imported = await showProblemsImportWorkflow(
      context: context,
      actorUserId: widget.currentUser.userId,
      orgId: widget.config.orgId,
      defaultDepartmentName: widget.currentUser.department.trim(),
      defaultDepartmentCode: widget.currentUser.departmentCode,
      orgType: widget.currentUser.orgType?.name ?? 'college',
      lockDepartment: UserRole.fromCode(widget.currentUser.role) == UserRole.departmentAdmin,
    );
    if (imported == true && mounted) {
      _loadProblems();
    }
  }

  /// College admins may delete any draft; department admins may delete drafts
  /// they personally authored.
  bool _canDeleteProblem(ProblemModel problem) {
    if (!widget.config.canDeleteDraft) return false;
    if (problem.status != ProblemStatus.draft) return false;
    final role = UserRole.fromCode(widget.currentUser.role);
    if (role == UserRole.departmentAdmin) {
      return problem.createdBy.trim() == widget.currentUser.userId.trim();
    }
    return role == UserRole.collegeAdmin;
  }

  Future<void> _deleteProblem(ProblemModel problem) async {
    if (!_canDeleteProblem(problem)) return;
    final bool shouldDelete = await FeedbackService.showConfirmation(
      context,
      title: 'Delete Problem',
      message: 'Delete this problem permanently?',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!shouldDelete) return;
    await _deleteProblemRecord(problem);
    if (!mounted) return;
    _loadProblems();
  }

  Future<void> _deleteProblemRecord(ProblemModel problem) async {
    await AttachmentService.deactivateEntityAttachments(
      entityType: AttachmentEntityType.problem,
      entityId: problem.problemId,
    );
    await FirestoreUtils.deleteProblem(problem.problemId);
  }

  Future<void> _activateAllDisplayed(List<ProblemModel> problems) async {
    final List<ProblemModel> targets = _activatableProblems(problems);
    if (targets.isEmpty) return;
    final int n = targets.length;
    final bool confirmed = await FeedbackService.showConfirmation(
      context,
      title: 'Activate All',
      message:
          'Activate $n problem${n == 1 ? '' : 's'}? They will become available for idea submissions.',
      confirmLabel: 'Activate All',
    );
    if (!confirmed || !mounted) return;

    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Activating problems',
        message: 'Activating 0 of $n…',
        successMessage: 'Activated $n problem${n == 1 ? '' : 's'}.',
        task: () async {
          final List<String> failures = <String>[];
          for (var i = 0; i < targets.length; i++) {
            HkzAsyncLoader.update(
              message: 'Activating ${i + 1} of $n…',
              progress: (i + 1) / n,
            );
            try {
              await ProblemStatusService.activate(targets[i].problemId);
            } catch (_) {
              failures.add(targets[i].problemId);
            }
          }
          if (failures.isNotEmpty) {
            throw Exception(
              'Activated ${n - failures.length} of $n. ${failures.length} failed.',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Activate All failed', message: '$e');
      }
    }
    if (mounted) _loadProblems();
  }

  Future<void> _deleteAllDisplayed(List<ProblemModel> problems) async {
    final List<ProblemModel> targets = _deletableProblems(problems);
    if (targets.isEmpty) return;
    final int n = targets.length;
    final bool confirmed = await FeedbackService.showConfirmation(
      context,
      title: 'Delete All',
      message: 'Delete $n draft problem${n == 1 ? '' : 's'} permanently? This cannot be undone.',
      confirmLabel: 'Delete All',
      dangerConfirm: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Deleting problems',
        message: 'Deleting 0 of $n…',
        successMessage: 'Deleted $n problem${n == 1 ? '' : 's'}.',
        task: () async {
          final List<String> failures = <String>[];
          for (var i = 0; i < targets.length; i++) {
            HkzAsyncLoader.update(
              message: 'Deleting ${i + 1} of $n…',
              progress: (i + 1) / n,
            );
            try {
              await _deleteProblemRecord(targets[i]);
            } catch (_) {
              failures.add(targets[i].problemId);
            }
          }
          if (failures.isNotEmpty) {
            throw Exception(
              'Deleted ${n - failures.length} of $n. ${failures.length} failed.',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Delete All failed', message: '$e');
      }
    }
    if (mounted) _loadProblems();
  }

  Future<void> _openSubmitIdea(ProblemModel problem) async {
    final IdeaSubmissionGate gate = computeIdeaSubmissionGate(
      problem: problem,
      submittedCount: _ideaCountByProblemId[problem.problemId] ?? 0,
      orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
    );
    final created = await showInnovationSubmissionWorkspace(
      context: context,
      currentUser: widget.currentUser,
      problem: problem,
      gate: gate,
    );
    if (created == true && mounted) _loadProblems();
  }

  void _openAssignJudge(ProblemModel problem) {
    showEvaluationAssignmentPane(
      context,
      user: widget.currentUser,
      problemId: problem.problemId,
      backTooltip: 'Back to Problems',
    );
  }

  void _openDetails(ProblemModel problem) {
    WorkspaceController.instance.close();
    final chrome = DashboardChromeScope.of(context);
    chrome.showOverlay(
      ProblemStatementDetailsPane(
        key: ValueKey<String>(problem.problemId),
        problem: problem,
        onBack: chrome.clearOverlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreateProblem || _editingProblem != null) {
      return ProblemAuthoringWorkspace(
        currentUser: widget.currentUser,
        initialProblem: _editingProblem,
        embedded: true,
        onBack: _closeProblemForm,
        onSaved: _onProblemFormSaved,
      );
    }
    return FutureBuilder<ProblemListQueryResult>(
      future: _problemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load problem statements: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        final ProblemListQueryResult result = snapshot.data ??
            ProblemListQueryResult(
              items: _lastLoaded,
              metrics: _metrics,
              ideaCountByProblemId: _ideaCountByProblemId,
            );
        final problems = result.items;
        _lastLoaded = problems;
        _metrics = result.metrics;
        _ideaCountByProblemId = result.ideaCountByProblemId;

        // Filter facets come from the currently loaded page only — matches
        // the cards-based list screen behaviour so the two surfaces stay
        // visually consistent.
        final allDepartments = problems
            .map((p) => p.departmentDisplayName.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
        final allTags = problems
            .expand((p) => p.tags)
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
        final Map<String, String> allDomains = _domainFilterOptions();

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final bool mobile = ResponsiveHelper.isMobile(context);

            final ProblemTableActions tableActions = _problemTableActions(problems);

            final Widget contentBody = problems.isEmpty
                ? EmptySearchState.problems(onClearSearch: () {
                    _searchController.clear();
                    _loadProblems();
                  })
                : _groupByDomain
                    ? _buildGroupedProblems(problems, tableActions, mobile: mobile)
                    : mobile
                        ? ListView.separated(
                            padding: const EdgeInsets.only(bottom: MobileCreateFabStyles.listBottomPadding),
                            itemCount: problems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              return ProblemListRowCard(
                                problem: problems[index],
                                actions: tableActions,
                              );
                            },
                          )
                        : DataTableView<ProblemModel>(
                            items: problems,
                            columns: ProblemTableColumns.build(
                              config: widget.config,
                              actions: tableActions,
                            ),
                            onSort: _onTableSort,
                            activeSortKey: _activeSortKey,
                          );

            final Widget header = _buildListHeader(
              context: context,
              problems: problems,
              allDepartments: allDepartments,
              allDomains: allDomains,
              allTags: allTags,
            );

            if (!hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  SizedBox(height: 480, child: contentBody),
                ],
              );
            }

            if (mobile) {
              final Widget mobileBody = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Expanded(child: contentBody),
                ],
              );

              if (!widget.config.canCreate) {
                return mobileBody;
              }

              return Stack(
                children: <Widget>[
                  mobileBody,
                  MobileCreateFab(
                    onPressed: _openCreateProblem,
                    tooltip: 'Create Problem',
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(child: contentBody),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, String> _domainFilterOptions() {
    Iterable<DomainModel> domains = _domainsById.values;
    if (_departmentFilters.isNotEmpty) {
      final Set<String> selected = _departmentFilters
          .map((String e) => e.trim().toUpperCase())
          .where((String e) => e.isNotEmpty)
          .toSet();
      final Set<String> matchingDeptIds = <String>{};
      for (final MapEntry<String, String> e in _deptIdToCode.entries) {
        final String code = e.value.trim().toUpperCase();
        final String name = (DepartmentModel.byCode(code)?.name ?? code).trim().toUpperCase();
        if (selected.contains(code) || selected.contains(name)) {
          matchingDeptIds.add(e.key);
        }
      }
      if (matchingDeptIds.isNotEmpty) {
        domains = domains.where((DomainModel d) => matchingDeptIds.contains(d.departmentId));
      } else {
        final Set<String> domainIdsOnFiltered = _lastLoaded
            .where((ProblemModel p) {
              final String name = p.departmentDisplayName.trim().toUpperCase();
              final String code = p.departmentCode.trim().toUpperCase();
              return selected.contains(code) || selected.contains(name);
            })
            .map((ProblemModel p) => p.domainId.trim())
            .where((String id) => id.isNotEmpty)
            .toSet();
        if (domainIdsOnFiltered.isNotEmpty) {
          domains = domains.where((DomainModel d) => domainIdsOnFiltered.contains(d.domainId));
        }
      }
    }
    final List<DomainModel> list = domains.toList(growable: false)
      ..sort((DomainModel a, DomainModel b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return <String, String>{
      for (final DomainModel d in list) d.domainId: d.displayLabel,
    };
  }

  Widget _buildGroupedProblems(
    List<ProblemModel> problems,
    ProblemTableActions tableActions, {
    required bool mobile,
  }) {
    final Map<String, List<ProblemModel>> grouped = <String, List<ProblemModel>>{};
    for (final ProblemModel p in problems) {
      final String key = p.domainId.trim().isEmpty ? '__none__' : p.domainId.trim();
      grouped.putIfAbsent(key, () => <ProblemModel>[]).add(p);
    }
    final List<String> keys = grouped.keys.toList(growable: false)
      ..sort((String a, String b) {
        if (a == '__none__') return 1;
        if (b == '__none__') return -1;
        final String an = _domainsById[a]?.name ?? a;
        final String bn = _domainsById[b]?.name ?? b;
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });

    return ListView.builder(
      padding: EdgeInsets.only(bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 12),
      itemCount: keys.length,
      itemBuilder: (BuildContext context, int index) {
        final String key = keys[index];
        final List<ProblemModel> group = grouped[key]!;
        final String title = key == '__none__'
            ? 'Unassigned domain'
            : (_domainsById[key]?.displayLabel ?? 'Domain');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            subtitle: Text(
              '${group.length} problem${group.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            children: <Widget>[
              if (mobile)
                ...group.map(
                  (ProblemModel p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProblemListRowCard(problem: p, actions: tableActions),
                  ),
                )
              else
                SizedBox(
                  height: (group.length * 56.0).clamp(120, 420),
                  child: DataTableView<ProblemModel>(
                    items: group,
                    columns: ProblemTableColumns.build(
                      config: widget.config,
                      actions: tableActions,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListHeader({
    required BuildContext context,
    required List<ProblemModel> problems,
    required List<String> allDepartments,
    required Map<String, String> allDomains,
    required List<String> allTags,
  }) {
    final bool compact = ResponsiveHelper.isMobile(context);

    final Widget metrics = ProblemMetricsRow(metrics: _metrics);
    final Widget? bulk = _buildBulkActions(problems);
    final Widget searchBar = _buildSearchFilterBar(context);
    final Widget filters = AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: ProblemFiltersPanel(
            compact: compact,
            enabledFilters: widget.config.enabledFilters,
            allDepartments: allDepartments,
            allDomains: allDomains,
            allTags: allTags,
            departmentFilters: _departmentFilters,
            domainFilters: _domainFilters,
            tagFilters: _tagFilters,
            statusFilter: _statusFilter,
            sourceFilter: _sourceFilter,
            hasAttachments: _hasAttachments,
            onDepartmentToggle: (d, selected) => setState(() {
              if (selected) {
                _departmentFilters.add(d);
              } else {
                _departmentFilters.remove(d);
              }
              _domainFilters.removeWhere((String id) => !allDomains.containsKey(id));
            }),
            onDomainToggle: (id, selected) => setState(() {
              if (selected) {
                _domainFilters.add(id);
              } else {
                _domainFilters.remove(id);
              }
            }),
            onTagToggle: (t, selected) => setState(() {
              if (selected) {
                _tagFilters.add(t);
              } else {
                _tagFilters.remove(t);
              }
            }),
            onStatusChange: (next) => setState(() => _statusFilter = next),
            onSourceChange: (next) => setState(() => _sourceFilter = next),
            onAttachmentsChange: (next) => setState(() => _hasAttachments = next),
            onClearAll: _clearAllFilters,
            onApply: _loadProblems,
          ),
      crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
    );
    final Widget? activeFilters = _hasAnyActiveFilter
        ? ProblemActiveFiltersRow(
            departmentFilters: _departmentFilters,
            domainFilters: _domainFilters,
            domainLabels: allDomains,
            tagFilters: _tagFilters,
            statusFilter: _statusFilter,
            sourceFilter: _sourceFilter,
            hasAttachments: _hasAttachments,
            onRemoveDepartment: (d) {
              setState(() => _departmentFilters.remove(d));
              _loadProblems();
            },
            onRemoveDomain: (id) {
              setState(() => _domainFilters.remove(id));
              _loadProblems();
            },
            onRemoveTag: (t) {
              setState(() => _tagFilters.remove(t));
              _loadProblems();
            },
            onClearStatus: () {
              setState(() => _statusFilter = null);
              _loadProblems();
            },
            onClearSource: () {
              setState(() => _sourceFilter = null);
              _loadProblems();
            },
            onClearAttachments: () {
              setState(() => _hasAttachments = null);
              _loadProblems();
            },
          )
        : null;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          metrics,
          const SizedBox(height: 8),
          searchBar,
          if (bulk != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: bulk),
          ],
          const SizedBox(height: 6),
          filters,
          if (activeFilters != null) ...<Widget>[
            const SizedBox(height: 6),
            activeFilters,
          ],
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        metrics,
        const SizedBox(height: 12),
        _buildDesktopToolbar(context, bulk: bulk),
        const SizedBox(height: 12),
        filters,
        if (activeFilters != null) ...<Widget>[
          const SizedBox(height: 12),
          activeFilters,
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildViewModeIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconOnlyFilterButton(
          icon: AppIcons.tableView,
          tooltip: 'Table',
          selected: !_groupByDomain,
          color: const Color(0xFF4A67FF),
          onTap: () => setState(() => _groupByDomain = false),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.domains,
          tooltip: 'By Domain',
          selected: _groupByDomain,
          color: const Color(0xFF7C3AED),
          onTap: () => setState(() => _groupByDomain = true),
        ),
      ],
    );
  }

  Widget? _buildBulkActions(List<ProblemModel> problems) {
    final bool showActivate = _activatableProblems(problems).isNotEmpty;
    final bool showDelete = _deletableProblems(problems).isNotEmpty;
    if (!showActivate && !showDelete) return null;

    final ButtonStyle outlined = MobileToolbarButtonStyles.outlined(compact: true);
    final ButtonStyle filled = MobileToolbarButtonStyles.filled(compact: true);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showActivate)
          FilledButton.icon(
            onPressed: () => _activateAllDisplayed(problems),
            icon: const Icon(AppIcons.problemStatusActive, size: 16),
            label: const Text('Activate All'),
            style: filled,
          ),
        if (showActivate && showDelete) const SizedBox(width: 8),
        if (showDelete)
          OutlinedButton.icon(
            onPressed: () => _deleteAllDisplayed(problems),
            icon: const Icon(AppIcons.delete, size: 16),
            label: const Text('Delete All'),
            style: outlined.copyWith(
              foregroundColor: const WidgetStatePropertyAll<Color>(Color(0xFFB91C1C)),
              side: const WidgetStatePropertyAll<BorderSide>(
                BorderSide(color: Color(0xFFF8C4C4), width: 1.2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchFilterBar(BuildContext context) {
    return ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search problem number, title, department, tags…',
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search problem number, title, department, tags…',
        prefixIcon: const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
        compact: true,
      ),
      searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      onSearchSubmitted: _loadProblems,
      iconOnlyFilterOnMobile: true,
      trailing: <Widget>[_buildViewModeIcons()],
    );
  }

  Widget _buildDesktopToolbar(BuildContext context, {Widget? bulk}) {
    final Widget? createButton = widget.config.canCreate
        ? FilledButton.icon(
            onPressed: _openCreateProblem,
            icon: const Icon(AppIcons.add, size: 16),
            label: const Text('Create Problem'),
            style: MobileToolbarButtonStyles.filled(compact: true),
          )
        : null;

    final Widget? importButton = widget.config.canCreate && ImportPlatformSupport.isSupported(context)
        ? OutlinedButton.icon(
            onPressed: _openImportProblems,
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Import Problems'),
            style: MobileToolbarButtonStyles.outlined(compact: true),
          )
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (createButton != null) ...<Widget>[
          createButton,
          const SizedBox(width: 8),
        ],
        if (importButton != null) ...<Widget>[
          importButton,
          const SizedBox(width: 8),
        ],
        Expanded(child: _buildSearchFilterBar(context)),
        if (bulk != null) ...<Widget>[
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: bulk,
          ),
        ],
      ],
    );
  }

  ProblemTableActions _problemTableActions(List<ProblemModel> displayedProblems) {
    final Map<String, String> domainLabelById = <String, String>{
      for (final DomainModel d in _domainsById.values)
        d.domainId: d.name.trim().isEmpty ? d.code : d.name.trim(),
    };
    return ProblemTableActions(
      config: widget.config,
      ideaCountByProblemId: _ideaCountByProblemId,
      orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
      canEditFor: _canEditProblem,
      canDeleteFor: _canDeleteProblem,
      onOpenProblem: (ProblemModel problem) =>
          WorkspaceNavigator.openProblem(context, problem.problemId),
      onOpenDetails: _openDetails,
      onSubmitIdea: _openSubmitIdea,
      onAssignJudge: _openAssignJudge,
      onEditProblem: _openEditProblem,
      onDeleteProblem: _deleteProblem,
      domainLabelById: domainLabelById,
      onActivateProblem: widget.config.canToggleActive ? _activateProblem : null,
      onDeactivateProblem: widget.config.canToggleActive ? _deactivateProblem : null,
      displayedProblems: displayedProblems,
    );
  }

  /// `_sort` is the single source of truth — table headers mutate it here.
  String? get _activeSortKey {
    switch (_sort) {
      case ProblemSortType.newest:
      case ProblemSortType.oldest:
        return 'newest';
      case ProblemSortType.psNumber:
        return 'psNumber';
      case ProblemSortType.titleAZ:
        return 'title';
      case ProblemSortType.department:
        return 'department';
      case ProblemSortType.category:
        return 'category';
      case ProblemSortType.ideasCount:
        return 'ideas';
      case ProblemSortType.deadline:
        return 'deadline';
    }
  }

  void _onTableSort(String sortKey) {
    ProblemSortType? next;
    switch (sortKey) {
      case 'newest':
        next = _sort == ProblemSortType.newest
            ? ProblemSortType.oldest
            : ProblemSortType.newest;
        break;
      case 'psNumber':
        next = ProblemSortType.psNumber;
        break;
      case 'title':
        next = ProblemSortType.titleAZ;
        break;
      case 'department':
        next = ProblemSortType.department;
        break;
      case 'category':
        next = ProblemSortType.category;
        break;
      case 'ideas':
        next = ProblemSortType.ideasCount;
        break;
      case 'deadline':
        next = ProblemSortType.deadline;
        break;
    }
    if (next == null) return;
    if (!widget.config.enabledSorts.contains(next)) return;
    if (next == _sort) return;
    setState(() => _sort = next!);
    _loadProblems();
  }

}
