import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/user_role.dart';
import '../../models/attachment_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/coordinator_dashboard_service.dart';
import '../../utils/firestore_utils.dart';
import '../../widgets/coordinator/coordinator_activity_feed.dart';
import '../../widgets/coordinator/coordinator_panel_card.dart';
import '../../widgets/coordinator/department_operational_snapshot.dart';
import '../../widgets/coordinator/escalation_alert_card.dart';
import '../../widgets/coordinator/operational_metric_card.dart';
import '../../widgets/coordinator/payment_queue_card.dart';
import '../../widgets/coordinator/submission_workflow_funnel.dart';
import '../../widgets/coordinator/verification_trend_chart.dart';
import 'coordinator_payment_card.dart';
import '../common/app_dialog_template.dart';
import '../common/dashboard_page_template.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../../widgets/attachment_viewer.dart';
import '../../responsive/responsive_breakpoints.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/common/rich_tabs.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../workspace/workspace.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.coordinator) {
      return const Scaffold(body: Center(child: Text('Access denied: Coordinator only')));
    }
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return _CoordinatorPaymentsView(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return _CoordinatorSummaryView(
          key: ValueKey<int>(refreshToken),
          user: user,
          refreshToken: refreshToken,
        );
      },
    );
  }
}

class _CoordinatorSummaryView extends StatefulWidget {
  const _CoordinatorSummaryView({super.key, required this.user, required this.refreshToken});

  final UserModel user;
  final int refreshToken;

  @override
  State<_CoordinatorSummaryView> createState() => _CoordinatorSummaryViewState();
}

class _CoordinatorSummaryViewState extends State<_CoordinatorSummaryView> {
  CoordinatorDashboardTimeframe _timeframe = CoordinatorDashboardTimeframe.currentWeek;
  late Future<CoordinatorDashboardAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = CoordinatorDashboardService.load(widget.user, forceRefresh: widget.refreshToken > 0);
  }

  void _refresh({bool force = false}) {
    setState(() {
      _future = CoordinatorDashboardService.load(widget.user, forceRefresh: force);
    });
  }

  Future<void> _viewProof(PaymentModel payment) async {
    await showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.wide,
      child: FutureBuilder<List<AttachmentModel>>(
        future: AttachmentService.fetchActiveAttachments(
          entityType: AttachmentEntityType.payment,
          entityId: payment.paymentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
          }
          final attachments = snapshot.data ?? const <AttachmentModel>[];
          if (attachments.isNotEmpty) {
            return AttachmentViewerDialog(
              title: 'Payment proof',
              attachments: attachments,
              embedded: true,
            );
          }
          final url = payment.paymentProofUrl.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Payment proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              url.isEmpty ? const Text('No payment proof uploaded.') : SelectableText(url),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _verify(PaymentModel payment) async {
    await CoordinatorDashboardService.verifyPayment(payment: payment, coordinator: widget.user);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified.')));
    _refresh(force: true);
  }

  Future<void> _reject(PaymentModel payment) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return ResponsiveAlertDialog(
          title: const Text('Reject payment'),
          widthPreset: DialogWidthPreset.compact,
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Reject')),
          ],
        );
      },
    );
    if (remarks == null) return;
    await CoordinatorDashboardService.rejectPayment(payment: payment, coordinator: widget.user, remarks: remarks.isEmpty ? null : remarks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rejected.')));
    _refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CoordinatorDashboardAnalytics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load coordinator dashboard: ${snapshot.error}');
        }
        final analytics = snapshot.data!;
        final gap = ResponsiveHelper.dashboardSectionGap(context);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CoordinatorHero(onRefresh: () => _refresh(force: true)),
              SizedBox(height: gap),
              _OperationalMetricGrid(analytics: analytics),
              SizedBox(height: gap),
              ResponsivePair(
                spacing: gap,
                first: AdaptiveDashboardPanel(
                  desktopHeight: 380,
                  child: VerificationTrendChart(
                    points: analytics.trendFor(_timeframe),
                    selectedTimeframe: _timeframe,
                    onTimeframeChanged: (timeframe) => setState(() => _timeframe = timeframe),
                  ),
                ),
                second: AdaptiveDashboardPanel(
                  desktopHeight: 380,
                  child: SubmissionWorkflowFunnel(steps: analytics.workflow),
                ),
              ),
              SizedBox(height: gap),
              ResponsivePair(
                spacing: gap,
                firstFlex: 2,
                secondFlex: 1,
                first: _PaymentVerificationQueue(
                  items: analytics.pendingQueue,
                  onVerify: _verify,
                  onReject: _reject,
                  onViewProof: _viewProof,
                  onOpenProblem: (payment) => WorkspaceNavigator.openProblem(context, payment.problemId),
                ),
                second: Column(
                  children: <Widget>[
                    _EscalationsPanel(alerts: analytics.escalations),
                    SizedBox(height: gap),
                    AdaptiveDashboardPanel(
                      desktopHeight: 245,
                      child: DepartmentOperationalSnapshot(snapshot: analytics.snapshot),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              AdaptiveDashboardPanel(
                desktopHeight: 360,
                child: CoordinatorActivityFeed(activities: analytics.recentActivity),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoordinatorHero extends StatelessWidget {
  const _CoordinatorHero({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE6FF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlock = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Coordinator Operations Control Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              SizedBox(height: 4),
              Text('Monitor payment verification, submission readiness and delayed actions in one compact workspace.', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            ],
          );
          final icon = Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: const Icon(AppIcons.verification, color: Color(0xFF4F46E5), size: 26),
          );
          final refreshButton = OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(AppIcons.refresh, size: 16),
            label: const Text('Refresh'),
          );
          if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                icon,
                const SizedBox(height: 12),
                textBlock,
                const SizedBox(height: 12),
                refreshButton,
              ],
            );
          }
          return Row(
            children: <Widget>[
              icon,
              const SizedBox(width: 14),
              Expanded(child: textBlock),
              const SizedBox(width: 12),
              refreshButton,
            ],
          );
        },
      ),
    );
  }
}

class _OperationalMetricGrid extends StatelessWidget {
  const _OperationalMetricGrid({required this.analytics});

  final CoordinatorDashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        OperationalMetricCard(value: '${analytics.pendingPayments}', label: 'Pending Payments', icon: AppIcons.pendingUsers, iconBgColor: const Color(0xFFFFF7ED), footnote: 'Payments waiting for coordinator verification').toChipData(),
        OperationalMetricCard(value: '${analytics.verifiedPaymentsToday}', label: 'Verified Today', icon: AppIcons.verification, iconBgColor: const Color(0xFFE8FAF1), footnote: 'Payments verified since midnight').toChipData(),
        OperationalMetricCard(value: '${analytics.ideasAwaitingValidation}', label: 'Payments Awaiting Validation', icon: AppIcons.submissions, iconBgColor: const Color(0xFFEFF6FF), footnote: 'Submitted payments waiting for coordinator review').toChipData(),
        OperationalMetricCard(value: '${analytics.rejectedPayments}', label: 'Rejected Payments', icon: AppIcons.statusRejected, iconBgColor: const Color(0xFFFDECEC), footnote: 'Payment submissions rejected by coordinators').toChipData(),
      ],
    );
  }
}

class _PaymentVerificationQueue extends StatelessWidget {
  const _PaymentVerificationQueue({
    required this.items,
    required this.onVerify,
    required this.onReject,
    required this.onViewProof,
    required this.onOpenProblem,
  });

  final List<PaymentQueueItem> items;
  final ValueChanged<PaymentModel> onVerify;
  final ValueChanged<PaymentModel> onReject;
  final ValueChanged<PaymentModel> onViewProof;
  final ValueChanged<PaymentModel> onOpenProblem;

  @override
  Widget build(BuildContext context) {
    final fixedHeight = ResponsiveHelper.fixedPanelHeight(context, 560);
  final listBody = items.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No pending payment verifications.')),
          )
        : ListView.separated(
            shrinkWrap: fixedHeight == null,
            physics: fixedHeight == null ? const NeverScrollableScrollPhysics() : null,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return PaymentQueueCard(
                item: item,
                onVerify: () => onVerify(item.payment),
                onReject: () => onReject(item.payment),
                onViewProof: () => onViewProof(item.payment),
                onOpenProblem: item.payment.problemId.trim().isEmpty
                    ? null
                    : () => onOpenProblem(item.payment),
              );
            },
          );

    return CoordinatorPanelCard(
      height: fixedHeight,
      backgroundColor: const Color(0xFFFCFDFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Pending Verification Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Prioritized payment reviews with proof and overdue signals', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          if (fixedHeight != null) Expanded(child: listBody) else listBody,
        ],
      ),
    );
  }
}

class _EscalationsPanel extends StatelessWidget {
  const _EscalationsPanel({required this.alerts});

  final List<CoordinatorEscalation> alerts;

  @override
  Widget build(BuildContext context) {
    final fixedHeight = ResponsiveHelper.fixedPanelHeight(context, 300);
    final listBody = ListView.separated(
      shrinkWrap: fixedHeight == null,
      physics: fixedHeight == null ? const NeverScrollableScrollPhysics() : null,
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => EscalationAlertCard(alert: alerts[index]),
    );

    return CoordinatorPanelCard(
      height: fixedHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Escalations / Delayed Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          if (fixedHeight != null) Expanded(child: listBody) else listBody,
        ],
      ),
    );
  }
}

class _CoordinatorPaymentsView extends StatefulWidget {
  const _CoordinatorPaymentsView({super.key, required this.user});

  final UserModel user;

  @override
  State<_CoordinatorPaymentsView> createState() => _CoordinatorPaymentsViewState();
}

class _CoordinatorPaymentsViewState extends State<_CoordinatorPaymentsView> {
  Future<_CoordinatorPaymentsData> _load() async {
    final payments = FirestoreUtils.getPaymentsByOrg(widget.user.orgId);
    final teams = FirestoreUtils.getTeamNamesByOrg(widget.user.orgId);
    final results = await Future.wait<dynamic>(<Future<dynamic>>[payments, teams]);
    var list = results[0] as List<PaymentModel>;
    list = _scopePayments(list);
    final teamById = results[1] as Map<String, String>;
    final studentIds = list.map((p) => p.paidByStudentId).where((e) => e.isNotEmpty).toSet();
    final names = <String, String>{};
    for (final id in studentIds) {
      final u = await FirestoreUtils.fetchUser(id);
      names[id] = u == null ? id : '${u.firstName} ${u.lastName}'.trim().isEmpty ? id : '${u.firstName} ${u.lastName}'.trim();
    }
    return _CoordinatorPaymentsData(
      payments: list,
      teamNameById: teamById,
      studentNameById: names,
    );
  }

  List<PaymentModel> _scopePayments(List<PaymentModel> all) {
    final dep = widget.user.departmentCode.trim().toUpperCase();
    if (dep.isEmpty) return all;
    return all.where((p) => p.departmentCode.trim().toUpperCase() == dep).toList(growable: false);
  }

  Future<void> _viewShot(PaymentModel payment) async {
    await showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.wide,
      child: FutureBuilder<List<AttachmentModel>>(
        future: AttachmentService.fetchActiveAttachments(
          entityType: AttachmentEntityType.payment,
          entityId: payment.paymentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
          }
          final attachments = snapshot.data ?? const <AttachmentModel>[];
          if (attachments.isNotEmpty) {
            return AttachmentViewerDialog(
              title: 'Payment attachments',
              attachments: attachments,
              embedded: true,
            );
          }
          final url = payment.paymentProofUrl.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Payment screenshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              url.isEmpty ? const Text('No payment proof uploaded.') : SelectableText(url),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(PaymentModel p) async {
    await FirestoreUtils.verifyIdeaPayment(
      paymentId: p.paymentId,
      coordinatorId: widget.user.userId,
    );
    CoordinatorDashboardService.clearCache();
    if (mounted) setState(() {});
  }

  Future<void> _reject(PaymentModel p) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return ResponsiveAlertDialog(
          title: const Text('Reject payment'),
          widthPreset: DialogWidthPreset.compact,
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: const Text('Reject')),
          ],
        );
      },
    );
    if (remarks == null) return;
    await FirestoreUtils.rejectIdeaPayment(
      paymentId: p.paymentId,
      coordinatorId: widget.user.userId,
      remarks: remarks.isEmpty ? null : remarks,
    );
    CoordinatorDashboardService.clearCache();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CoordinatorPaymentsData>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load: ${snapshot.error}');
        }
        final data = snapshot.data!;
        final pending = data.payments
            .where((p) => p.status == PaymentRecordStatus.pending)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final verified = data.payments
            .where((p) => p.status == PaymentRecordStatus.verified)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final rejected = data.payments
            .where((p) => p.status == PaymentRecordStatus.rejected)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return RichTabs(
          spacingAfterBar: 10,
          tabs: <RichTabItem>[
            RichTabItem('Pending', count: pending.isEmpty ? null : pending.length),
            RichTabItem('Verified', count: verified.isEmpty ? null : verified.length),
            RichTabItem('Rejected', count: rejected.isEmpty ? null : rejected.length),
          ],
          children: <Widget>[
            _buildList(pending, data),
            _buildList(verified, data),
            _buildList(rejected, data),
          ],
        );
      },
    );
  }

  Widget _buildList(List<PaymentModel> items, _CoordinatorPaymentsData data) {
    if (items.isEmpty) return const Center(child: Text('No items.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final teamName = data.teamNameById[p.teamId] ?? p.teamId;
        final student = data.studentNameById[p.paidByStudentId] ?? p.paidByStudentId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CoordinatorPaymentCard(
            payment: p,
            problemNumber: p.problemNumber,
            onOpenProblem: p.problemId.trim().isEmpty
                ? null
                : () => WorkspaceNavigator.openProblem(context, p.problemId),
            teamName: teamName,
            studentName: student,
            onOpenStudent: p.paidByStudentId.trim().isEmpty
                ? null
                : () => WorkspaceNavigator.openUser(context, p.paidByStudentId),
            onOpenTeam: p.teamId.trim().isEmpty
                ? null
                : () => WorkspaceNavigator.openTeam(context, p.teamId),
            onViewScreenshot: () => _viewShot(p),
            onApprove: () => _approve(p),
            onReject: () => _reject(p),
          ),
        );
      },
    );
  }
}

class _CoordinatorPaymentsData {
  const _CoordinatorPaymentsData({
    required this.payments,
    required this.teamNameById,
    required this.studentNameById,
  });

  final List<PaymentModel> payments;
  final Map<String, String> teamNameById;
  final Map<String, String> studentNameById;
}
