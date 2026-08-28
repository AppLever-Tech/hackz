import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../imports/imports.dart';
import '../../user/constants/csv_import_role_constants.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
import '../../user/models/user_model.dart';
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/filter_pill.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../user/models/enums/judge_type.dart';
import '../../user/widgets/mobile_user_list_row_card.dart';
import '../../../features/dashboard/chrome/empty_search_state.dart';
import '../../../features/dashboard/deptadmin/services/department_dashboard_service.dart';
import '../../../utils/firestore_utils.dart';
import '../widgets/judge_type_pill.dart';
import '../widgets/judges_panel_metrics_row.dart';
import '../../../core/workspace/user_list_identity_lead.dart';
import '../../user/screens/create_user_dialog.dart';

class JudgesPanelScreen extends StatefulWidget {
  const JudgesPanelScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<JudgesPanelScreen> createState() => _JudgesPanelScreenState();
}

class _JudgesPanelData {
  const _JudgesPanelData({required this.judges, required this.metrics});

  final List<UserModel> judges;
  final DepartmentDashboardAnalytics metrics;
}

class _JudgesPanelScreenState extends State<JudgesPanelScreen> {
  late Future<_JudgesPanelData> _future;
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  JudgeType? _typeFilter;

  OrganizationModel get _organization => OrganizationModel(
        id: widget.user.orgId,
        name: '',
        type: widget.user.orgType ?? OrganizationType.college,
        address: '',
        website: '',
        contact: '',
        createdAt: DateTime.now(),
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<_JudgesPanelData> _load() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.getDepartmentUsers(
        orgId: widget.user.orgId,
        department: widget.user.departmentCode,
        roleCodes: const <String>['JUD'],
      ),
      DepartmentDashboardService.load(
        orgId: widget.user.orgId,
        departmentCode: widget.user.departmentCode,
        forceRefresh: true,
      ),
    ]);
    return _JudgesPanelData(
      judges: results[0] as List<UserModel>,
      metrics: results[1] as DepartmentDashboardAnalytics,
    );
  }

  Future<void> _importJudges() async {
    final bool? imported = await showUserImportWorkflow(
      context: context,
      config: UserImportConfig(
        actor: widget.user,
        organizationType: widget.user.orgType ?? OrganizationType.college,
        departmentName: widget.user.department,
        departmentCode: DepartmentModel.resolveCode(widget.user.departmentCode),
        allowedCsvRoles: CsvImportRoleConstants.judgesPanelOnly,
      ),
    );
    if (imported == true && mounted) {
      _refresh();
    }
  }

  Future<void> _editJudge(UserModel judge) async {
    final bool changed = await showCreateUserDialog(
      context: context,
      roleCode: 'JUD',
      organization: _organization,
      department: widget.user.department,
      initialUser: judge,
    );
    if (changed && mounted) {
      _refresh();
    }
  }

  Future<void> _addJudge() async {
    final bool changed = await showCreateUserDialog(
      context: context,
      roleCode: 'JUD',
      organization: _organization,
      department: widget.user.department,
      onUserSaved: (UserModel savedUser) async {
        await FirestoreUtils.updateUser(savedUser.userId, <String, dynamic>{
          'role': 'JUD',
          'orgId': widget.user.orgId,
          'department': widget.user.department,
          'departmentCode': DepartmentModel.resolveCode(widget.user.departmentCode),
        });
      },
    );
    if (changed && mounted) {
      _refresh();
    }
  }

  Future<void> _removeJudge(UserModel judge) async {
    final String displayName = '${judge.firstName} ${judge.lastName}'.trim().isEmpty
        ? judge.phone
        : '${judge.firstName} ${judge.lastName}'.trim();
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete user?',
      message: 'This will remove $displayName from this department.',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return;
    await FirestoreUtils.deleteUser(judge.userId);
    if (mounted) {
      _refresh();
    }
  }

  Widget _metaDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1))),
    );
  }

  Widget _inlineMeta(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
    );
  }

  Widget _judgeDetailsLine(UserModel judge) {
    final String email = judge.email.trim().isEmpty ? '—' : judge.email.trim();
    final String phone = judge.phone.trim().isEmpty ? '—' : judge.phone.trim();

    final Widget line = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        UserListIdentityLead(user: judge),
        _metaDot(),
        _inlineMeta(email),
        _metaDot(),
        _inlineMeta(phone),
        if (_judgeTypeOf(judge) != null) ...<Widget>[
          _metaDot(),
          JudgeTypePill(judgeType: _judgeTypeOf(judge), compact: true),
        ],
      ],
    );

    if (ResponsiveHelper.isMobile(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: line,
      );
    }
    return line;
  }

  Widget _judgeRow(UserModel judge) {
    if (ResponsiveHelper.isMobile(context)) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: MobileUserListRowCard.editDelete(
          user: judge,
          showJudgeType: true,
          onEdit: () => _editJudge(judge),
          onDelete: () => _removeJudge(judge),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: _judgeDetailsLine(judge)),
          const SizedBox(width: 4),
          ListRowIconButton(
            tooltip: 'Edit',
            icon: AppIcons.edit,
            onPressed: () => _editJudge(judge),
          ),
          ListRowIconButton(
            tooltip: 'Delete',
            icon: AppIcons.delete,
            onPressed: () => _removeJudge(judge),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  JudgeType? _judgeTypeOf(UserModel judge) => judge.profile?.judgeProfile?.judgeType;

  int _countByType(List<UserModel> judges, JudgeType type) {
    return judges.where((UserModel judge) => _judgeTypeOf(judge) == type).length;
  }

  List<UserModel> _visibleJudges(List<UserModel> judges) {
    final String query = _searchController.text.trim().toLowerCase();
    return judges.where((UserModel judge) {
      final JudgeType? type = _judgeTypeOf(judge);
      if (_typeFilter != null && type != _typeFilter) return false;
      if (query.isEmpty) return true;
      return judge.displayName.toLowerCase().contains(query) ||
          judge.email.toLowerCase().contains(query) ||
          judge.phone.toLowerCase().contains(query) ||
          (type?.label.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchController.clear();
      _typeFilter = null;
    });
  }

  Widget _typeFilterPill({
    required JudgeType type,
    required int count,
  }) {
    return FilterPill(
      selected: _typeFilter == type,
      icon: JudgeTypePill.iconFor(type),
      label: type.label,
      count: count,
      foregroundColor: JudgeTypePill.colorFor(type),
      onTap: () => setState(() {
        _typeFilter = _typeFilter == type ? null : type;
      }),
    );
  }

  Widget _buildToolbar(BuildContext context, List<UserModel> judges) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool showImport = !mobile && ImportPlatformSupport.isSupported(context);

    return ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search judges',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      filterLabel: _showFilters ? 'Hide Filters' : 'Show Filters',
      searchTextStyle: HackzInputDecoration.fieldTextStyle,
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search judges',
        prefixIcon: const Icon(AppIcons.search, size: 18),
        contentPaddingOverride: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      leading: <Widget>[
        if (!mobile) MobileToolbarButtonStyles.filledIcon(
          onPressed: _addJudge,
          label: 'Add Judge',
        ),
        if (showImport) MobileToolbarButtonStyles.outlinedIcon(
          onPressed: _importJudges,
          label: 'Import Users',
        ),
      ],
      afterFilter: _showFilters
          ? <Widget>[
              _typeFilterPill(type: JudgeType.internal, count: _countByType(judges, JudgeType.internal)),
              _typeFilterPill(type: JudgeType.external, count: _countByType(judges, JudgeType.external)),
            ]
          : const <Widget>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double gap = ResponsiveHelper.dashboardSectionGap(context);
    return FutureBuilder<_JudgesPanelData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<_JudgesPanelData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load judges panel: ${snapshot.error}');
        }
        final _JudgesPanelData? data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No judges data available.'));
        }

        final bool mobile = ResponsiveHelper.isMobile(context);
        final List<UserModel> visible = _visibleJudges(data.judges);
        final bool hasActiveQuery = _searchController.text.trim().isNotEmpty || _typeFilter != null;
        final Widget metrics = JudgesPanelMetricsRow(
          judgeCount: data.judges.length,
          metrics: data.metrics,
          spacing: mobile ? 8 : 10,
          runSpacing: mobile ? 8 : 10,
        );
        final Widget toolbar = _buildToolbar(context, data.judges);
        final Widget list = visible.isEmpty
            ? (data.judges.isEmpty
                ? const Center(child: Text('No judges assigned for this department.'))
                : EmptySearchState.judges(
                    onClearSearch: () {
                      if (!hasActiveQuery) return;
                      _clearSearchAndFilters();
                    },
                  ))
            : ListView.builder(
                padding: EdgeInsets.only(
                  bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 12,
                ),
                itemCount: visible.length,
                itemBuilder: (BuildContext context, int index) => _judgeRow(visible[index]),
              );

        if (mobile) {
          return Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  metrics,
                  const SizedBox(height: 8),
                  toolbar,
                  const SizedBox(height: 10),
                  Expanded(child: list),
                ],
              ),
              MobileCreateFab(
                onPressed: _addJudge,
                tooltip: 'Add Judge',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            metrics,
            SizedBox(height: gap),
            toolbar,
            const SizedBox(height: 10),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}
