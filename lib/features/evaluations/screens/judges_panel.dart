import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../workspace/evaluation_assignment_details_pane.dart';
import '../../imports/imports.dart';
import '../../user/constants/csv_import_role_constants.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
import '../../user/models/user_model.dart';
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../user/widgets/mobile_user_list_row_card.dart';
import '../../../features/dashboard/deptadmin/services/department_dashboard_service.dart';
import '../../../utils/firestore_utils.dart';
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
    _future = _load();
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

  void _openAssignmentWorkspace() {
    showEvaluationAssignmentPane(
      context,
      user: widget.user,
      backTooltip: 'Back to Judges Panel',
    );
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
        _metaDot(),
        _inlineMeta('Judge'),
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
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _editJudge(judge),
            icon: const Icon(AppIcons.edit, size: 20),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _removeJudge(judge),
            icon: const Icon(AppIcons.remove, color: Colors.redAccent),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool showImport = ImportPlatformSupport.isSupported(context);

    final Widget addButton = FilledButton.icon(
      onPressed: _addJudge,
      icon: const Icon(AppIcons.add, size: 16),
      label: Text(mobile ? 'Add' : 'Add Judge'),
      style: MobileToolbarButtonStyles.filled(compact: mobile),
    );
    final Widget? importButton = showImport
        ? OutlinedButton.icon(
            onPressed: _importJudges,
            icon: const Icon(AppIcons.attachments, size: 16),
            label: const Text('Import Users'),
            style: MobileToolbarButtonStyles.outlined(compact: false),
          )
        : null;
    final Widget assignmentsButton = OutlinedButton.icon(
      onPressed: _openAssignmentWorkspace,
      icon: const Icon(AppIcons.scoring, size: 16),
      label: Text(mobile ? 'Assignments' : 'Evaluation Assignments'),
      style: MobileToolbarButtonStyles.outlined(compact: mobile),
    );

    if (mobile) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        addButton,
        if (importButton != null) importButton,
        assignmentsButton,
      ],
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
        final Widget metrics = JudgesPanelMetricsRow(
          judgeCount: data.judges.length,
          metrics: data.metrics,
          spacing: mobile ? 8 : 10,
          runSpacing: mobile ? 8 : 10,
        );

        if (mobile) {
          const double fabGap = 12;
          final double stackedFabBottom =
              MobileCreateFabStyles.screenMargin.bottom + MobileCreateFabStyles.size + fabGap;
          final double listBottomPadding =
              MobileCreateFabStyles.listBottomPadding + MobileCreateFabStyles.size + fabGap;

          return Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  metrics,
                  const SizedBox(height: 8),
                  Expanded(
                    child: data.judges.isEmpty
                        ? const Center(child: Text('No judges assigned for this department.'))
                        : ListView.builder(
                            padding: EdgeInsets.only(bottom: listBottomPadding),
                            itemCount: data.judges.length,
                            itemBuilder: (BuildContext context, int index) => _judgeRow(data.judges[index]),
                          ),
                  ),
                ],
              ),
              MobileCreateFab(
                onPressed: _openAssignmentWorkspace,
                icon: AppIcons.scoring,
                tooltip: 'Evaluation Assignments',
                margin: EdgeInsets.only(
                  right: MobileCreateFabStyles.screenMargin.right,
                  bottom: stackedFabBottom,
                ),
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
            _buildToolbar(context),
            const SizedBox(height: 10),
            Expanded(
              child: data.judges.isEmpty
                  ? const Center(child: Text('No judges assigned for this department.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: data.judges.length,
                      itemBuilder: (BuildContext context, int index) => _judgeRow(data.judges[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}
