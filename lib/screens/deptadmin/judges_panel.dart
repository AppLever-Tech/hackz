import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/department_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/organization_model.dart';
import '../../models/user_model.dart';
import '../../responsive/responsive_helper.dart';
import '../../shared/feedback/feedback.dart';
import '../../utils/department_dashboard_service.dart';
import '../../utils/firestore_utils.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/deptadmin/department_metric_card.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../workspace/workspace.dart';
import '../common/create_user_dialog.dart';

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

  Widget _buildMetricChips(_JudgesPanelData data) {
    final DepartmentDashboardAnalytics metrics = data.metrics;
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DepartmentMetricCard(
          value: '${data.judges.length}',
          label: 'Total Judges',
          icon: AppIcons.judges,
          iconBgColor: const Color(0xFFFFF4ED),
          tooltip: 'Judges assigned to this department.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '${metrics.ideasSubmitted}',
          label: 'Ideas Submitted',
          icon: AppIcons.ideas,
          iconBgColor: const Color(0xFFF2EDFF),
          tooltip: 'Department idea submissions.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '${metrics.underReviewIdeas}',
          label: 'Ideas Under Review',
          icon: AppIcons.statusUnderReview,
          iconBgColor: const Color(0xFFEAF2FF),
          tooltip: 'Ideas currently under review.',
        ).toChipData(),
        DashboardMetricChipData.withSegments(
          label: 'Ideas',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.ideas,
          segments: <DashboardMetricChipSegment>[
            DashboardMetricChipSegment(
              icon: AppIcons.statusEvaluated,
              tooltip: 'Evaluated',
              value: '${metrics.evaluatedOnlyIdeas}',
              color: StatusStyles.evaluated,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusApproved,
              tooltip: 'Approved',
              value: '${metrics.approvedIdeas}',
              color: StatusStyles.approved,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              value: '${metrics.rejectedIdeas}',
              color: StatusStyles.rejected,
            ),
          ],
        ),
      ],
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
    final String name =
        '${judge.firstName} ${judge.lastName}'.trim().isEmpty ? judge.phone : '${judge.firstName} ${judge.lastName}'.trim();
    final String email = judge.email.trim().isEmpty ? '—' : judge.email.trim();
    final String phone = judge.phone.trim().isEmpty ? '—' : judge.phone.trim();

    final Widget line = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ContextPill(
          label: name,
          semantic: ContextPillSemantic.judge,
          onTap: () => WorkspaceNavigator.openUser(context, judge.userId),
          compact: true,
          fitContent: true,
        ),
        _metaDot(),
        _inlineMeta(email),
        _metaDot(),
        _inlineMeta(phone),
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
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 8 : 10,
        vertical: 8,
      ),
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
            tooltip: 'Remove',
            onPressed: () => _removeJudge(judge),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildMetricChips(data),
            SizedBox(height: gap),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _addJudge,
                icon: const Icon(AppIcons.add, size: 16),
                label: const Text('Add Judge'),
              ),
            ),
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
