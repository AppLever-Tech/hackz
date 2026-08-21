import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../features/user/models/enums/user_role.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../core/ui/feedback/feedback.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import '../services/coordinator_dashboard_service.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../widgets/coordinator_activity_feed.dart';
import '../widgets/payment_queue_card.dart';
import '../widgets/submission_workflow_funnel.dart';
import '../widgets/verification_trend_chart.dart';
import 'coordinator_payment_card.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../chrome/dashboard_components.dart';
import '../../../../core/responsive/responsive_alert_dialog.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/leaderboard/screens/leaderboard_showcase_screen.dart';
import '../../../../features/team/screens/team_registration_screen.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/common/rich_tabs.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../../core/responsive/responsive_metric_grid.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

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
          return TeamRegistrationScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return IdeathonsListScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 3) {
          return _CoordinatorPaymentsView(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 4) {
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
  CoordinatorDashboardTimeframe _trendTimeframe = CoordinatorDashboardTimeframe.currentWeek;
  CoordinatorDashboardTimeframe _activityTimeframe = CoordinatorDashboardTimeframe.currentWeek;
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

  Future<void> _openPaymentProof(PaymentModel payment) async {
    final attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.payment,
      entityId: payment.paymentId,
    );
    if (!mounted) return;
    if (attachments.length == 1) {
      WorkspaceNavigator.openAttachment(context, attachments.first.attachmentId);
      return;
    }
    if (attachments.isNotEmpty || payment.paymentProofUrl.trim().isNotEmpty) {
      WorkspaceNavigator.openPayment(context, payment.paymentId);
      return;
    }
    FeedbackService.showInfo(
      context,
      title: 'Payment proof',
      message: 'No payment proof uploaded yet.',
    );
  }

  Future<void> _verify(PaymentModel payment) async {
    await CoordinatorDashboardService.verifyPayment(payment: payment, coordinator: widget.user);
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: 'Payment verified',
      message: 'Payment verified.',
    );
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
    FeedbackService.showInfo(
      context,
      title: 'Payment rejected',
      message: 'Payment rejected.',
    );
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
              _OperationalMetricGrid(analytics: analytics),
              SizedBox(height: gap),
              DashboardPairRow(
                height: DashboardLayoutTokens.coordinatorChartsRowHeight(
                  analytics.workflow.length,
                ),
                pair: ResponsivePair(
                  spacing: gap,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  first: SectionContainer(
                    child: VerificationTrendChart(
                      points: analytics.trendFor(_trendTimeframe),
                      selectedTimeframe: _trendTimeframe,
                      onTimeframeChanged: (CoordinatorDashboardTimeframe timeframe) {
                        setState(() => _trendTimeframe = timeframe);
                      },
                    ),
                  ),
                  second: SectionContainer(
                    child: SubmissionWorkflowFunnel(steps: analytics.workflow),
                  ),
                ),
              ),
              SizedBox(height: gap),
              DashboardPairRow(
                height: DashboardLayoutTokens.coordinatorQueueActivityRowHeight(
                  analytics.pendingQueue.length,
                ),
                pair: ResponsivePair(
                  spacing: gap,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  first: SectionContainer(
                    child: _PaymentVerificationQueue(
                      items: analytics.pendingQueue,
                      onVerify: _verify,
                      onReject: _reject,
                      onOpenProof: _openPaymentProof,
                      onOpenIdea: (payment) => WorkspaceNavigator.openIdea(context, payment.ideaId),
                    ),
                  ),
                  second: SectionContainer(
                    child: CoordinatorActivityFeed(
                      activities: analytics.recentActivity,
                      selectedTimeframe: _activityTimeframe,
                      onTimeframeChanged: (CoordinatorDashboardTimeframe timeframe) {
                        setState(() => _activityTimeframe = timeframe);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        DashboardMetricChipData.single(
          label: 'Pending Payments',
          value: '${analytics.pendingPayments}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.pendingUsers,
        ),
        DashboardMetricChipData.single(
          label: 'Verified Today',
          value: '${analytics.verifiedPaymentsToday}',
          color: const Color(0xFF16A34A),
          icon: AppIcons.verification,
        ),
        DashboardMetricChipData.single(
          label: 'Payments Awaiting Validation',
          value: '${analytics.ideasAwaitingValidation}',
          color: const Color(0xFF0EA5E9),
          icon: AppIcons.submissions,
        ),
        DashboardMetricChipData.single(
          label: 'Rejected Payments',
          value: '${analytics.rejectedPayments}',
          color: const Color(0xFFDC2626),
          icon: AppIcons.workflowRejected,
        ),
      ],
    );
  }
}

class _PaymentVerificationQueue extends StatelessWidget {
  const _PaymentVerificationQueue({
    required this.items,
    required this.onVerify,
    required this.onReject,
    required this.onOpenProof,
    this.onOpenIdea,
  });

  final List<PaymentQueueItem> items;
  final ValueChanged<PaymentModel> onVerify;
  final ValueChanged<PaymentModel> onReject;
  final ValueChanged<PaymentModel> onOpenProof;
  final ValueChanged<PaymentModel>? onOpenIdea;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      preset: DashboardListPreset.compact,
      rowStride: DashboardLayoutTokens.listPaymentQueueRowStride,
      separatorHeight: 8,
      headers: DashboardCardHeaders.sectionTitle(
        title: 'Pending Verification Queue',
        subtitle: 'Prioritized payment reviews with proof and overdue signals',
      ),
      itemCount: items.length,
      empty: const Align(
        alignment: Alignment.topLeft,
        child: Text('No pending payment verifications.'),
      ),
      itemBuilder: (BuildContext context, int index) {
        final PaymentQueueItem item = items[index];
        return PaymentQueueCard(
          item: item,
          onVerify: () => onVerify(item.payment),
          onReject: () => onReject(item.payment),
          onOpenProof: item.hasProof ? () => onOpenProof(item.payment) : null,
          onOpenIdea: item.ideaId.trim().isEmpty
              ? null
              : () => onOpenIdea?.call(item.payment),
        );
      },
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
    final Set<String> ideaIds =
        list.map((PaymentModel p) => p.ideaId.trim()).where((String id) => id.isNotEmpty).toSet();
    final Map<String, String> ideaTitleById = <String, String>{};
    if (ideaIds.isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> ideaSnap = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzIdeas)
          .where('orgId', isEqualTo: widget.user.orgId)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in ideaSnap.docs) {
        if (!ideaIds.contains(doc.id)) continue;
        final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
        final String title = idea.ideaTitle.trim();
        ideaTitleById[doc.id] =
            title.isNotEmpty ? title : (idea.problemNumber.trim().isNotEmpty ? idea.problemNumber.trim() : doc.id);
      }
    }
    final Set<String> paymentIds = list.map((PaymentModel p) => p.paymentId).toSet();
    final Map<String, int> attachmentCountByPaymentId = <String, int>{};
    if (paymentIds.isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> attachmentSnap = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzAttachments)
          .where('orgId', isEqualTo: widget.user.orgId)
          .where('isActive', isEqualTo: true)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in attachmentSnap.docs) {
        final AttachmentModel attachment = AttachmentModel.fromMap(doc.id, doc.data());
        if (attachment.entityType != AttachmentEntityType.payment) continue;
        if (!paymentIds.contains(attachment.entityId)) continue;
        attachmentCountByPaymentId[attachment.entityId] =
            (attachmentCountByPaymentId[attachment.entityId] ?? 0) + 1;
      }
    }
    return _CoordinatorPaymentsData(
      payments: list,
      teamNameById: teamById,
      ideaTitleById: ideaTitleById,
      attachmentCountByPaymentId: attachmentCountByPaymentId,
    );
  }

  List<PaymentModel> _scopePayments(List<PaymentModel> all) {
    final dep = widget.user.departmentCode.trim().toUpperCase();
    if (dep.isEmpty) return all;
    return all.where((p) => p.departmentCode.trim().toUpperCase() == dep).toList(growable: false);
  }

  Future<void> _openPaymentAttachments(PaymentModel payment) async {
    final attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.payment,
      entityId: payment.paymentId,
    );
    if (!mounted) return;
    if (attachments.length == 1) {
      WorkspaceNavigator.openAttachment(context, attachments.first.attachmentId);
      return;
    }
    if (attachments.isNotEmpty || payment.paymentProofUrl.trim().isNotEmpty) {
      WorkspaceNavigator.openPayment(context, payment.paymentId);
      return;
    }
    FeedbackService.showInfo(
      context,
      title: 'Payment proof',
      message: 'No payment proof uploaded yet.',
    );
  }

  bool _hasPaymentProof(PaymentModel payment, _CoordinatorPaymentsData data) {
    if (payment.paymentProofUrl.trim().isNotEmpty) return true;
    return (data.attachmentCountByPaymentId[payment.paymentId] ?? 0) > 0;
  }

  int _paymentAttachmentCount(PaymentModel payment, _CoordinatorPaymentsData data) {
    final int count = data.attachmentCountByPaymentId[payment.paymentId] ?? 0;
    if (count > 0) return count;
    return payment.paymentProofUrl.trim().isNotEmpty ? 1 : 0;
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
            RichTabItem('Pending', count: pending.isEmpty ? null : pending.length, prominentCount: true),
            RichTabItem('Verified', count: verified.isEmpty ? null : verified.length, prominentCount: true),
            RichTabItem('Rejected', count: rejected.isEmpty ? null : rejected.length, prominentCount: true),
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
        final String ideaName = data.ideaTitleById[p.ideaId] ?? p.problemNumber;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CoordinatorPaymentCard(
            payment: p,
            teamName: teamName,
            ideaName: ideaName,
            onOpenTeam: p.teamId.trim().isEmpty
                ? null
                : () => WorkspaceNavigator.openTeam(context, p.teamId),
            onOpenIdea: p.ideaId.trim().isEmpty
                ? null
                : () => WorkspaceNavigator.openIdea(context, p.ideaId),
            onOpenPayment: () => WorkspaceNavigator.openPayment(context, p.paymentId),
            onOpenAttachments: _hasPaymentProof(p, data) ? () => _openPaymentAttachments(p) : null,
            attachmentCount: _paymentAttachmentCount(p, data),
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
    required this.ideaTitleById,
    required this.attachmentCountByPaymentId,
  });

  final List<PaymentModel> payments;
  final Map<String, String> teamNameById;
  final Map<String, String> ideaTitleById;
  final Map<String, int> attachmentCountByPaymentId;
}
