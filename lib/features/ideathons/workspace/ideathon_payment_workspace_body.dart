import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_alert_dialog.dart';
import '../../../core/responsive/responsive_dialog.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../payment/models/payment_model.dart';
import '../../payment/services/payment_finance_helpers.dart';
import '../../payment/widgets/payment_status_pill.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_payment_service.dart';
import '../widgets/ideathon_status_pill.dart';

class IdeathonPaymentWorkspaceBody extends StatefulWidget {
  const IdeathonPaymentWorkspaceBody({
    super.key,
    required this.vm,
    this.actor,
  });

  final IdeathonPaymentWorkspaceViewModel vm;
  final UserModel? actor;

  @override
  State<IdeathonPaymentWorkspaceBody> createState() => _IdeathonPaymentWorkspaceBodyState();
}

class _IdeathonPaymentWorkspaceBodyState extends State<IdeathonPaymentWorkspaceBody> {
  late IdeathonPaymentWorkspaceViewModel _vm;
  bool _busy = false;
  String _search = '';
  PaymentRecordStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _vm = widget.vm;
  }

  @override
  void didUpdateWidget(covariant IdeathonPaymentWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) _vm = widget.vm;
  }

  Future<void> _reload() async {
    final IdeathonPaymentWorkspaceViewModel next =
        await IdeathonPaymentService.load(_vm.ideathon.ideathonId);
    if (!mounted) return;
    setState(() => _vm = next);
  }

  List<IdeathonPaymentRow> get _filteredRows {
    final String q = _search.trim().toLowerCase();
    return _vm.rows.where((IdeathonPaymentRow row) {
      if (_statusFilter != null && row.displayPaymentStatus != _statusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final String hay = <String>[
        row.ideaTitle,
        row.teamName,
        row.payerName,
        row.payment?.remarks ?? '',
        row.payment?.transactionId ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }

  Future<void> _verify(IdeathonPaymentRow row) async {
    final UserModel? actor = widget.actor;
    if (actor == null) {
      FeedbackService.showError(context, title: 'Unable to verify', message: 'Coordinator session required.');
      return;
    }
    setState(() => _busy = true);
    try {
      await IdeathonPaymentService.verifyRow(row: row, coordinator: actor);
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Payment confirmed',
        message: 'Idea payment is confirmed.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Verify failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(IdeathonPaymentRow row) async {
    final UserModel? actor = widget.actor;
    if (actor == null) {
      FeedbackService.showError(context, title: 'Unable to reject', message: 'Coordinator session required.');
      return;
    }
    final TextEditingController remarks = TextEditingController(text: row.payment?.remarks ?? '');
    final String? confirmed = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return ResponsiveAlertDialog(
          title: const Text('Payment exception'),
          widthPreset: DialogWidthPreset.compact,
          content: TextField(
            controller: remarks,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, remarks.text.trim()),
              child: const Text('Mark exception'),
            ),
          ],
        );
      },
    );
    remarks.dispose();
    if (confirmed == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await IdeathonPaymentService.rejectRow(
        row: row,
        coordinator: actor,
        remarks: confirmed.isEmpty ? null : confirmed,
      );
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(context, title: 'Payment exception recorded', message: 'Participation remains payment pending.');
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Reject failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final IdeathonPaymentMetrics metrics = _vm.metrics;
    final List<IdeathonPaymentRow> rows = _filteredRows;

    return Stack(
      children: <Widget>[
        ListView(
          padding: EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 28),
          children: <Widget>[
            Text(
              _vm.ideathon.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            IdeathonStatusPill(status: _vm.ideathon.status, compact: true),
            const SizedBox(height: 12),
            ResponsiveMetricGrid(
              chips: <DashboardMetricChipData>[
                DashboardMetricChipData.single(
                  label: 'Total Ideas',
                  value: '${metrics.totalIdeas}',
                  color: const Color(0xFF4A67FF),
                  icon: AppIcons.ideas,
                ),
                DashboardMetricChipData.single(
                  label: 'Payment Pending',
                  value: '${metrics.paymentPending}',
                  color: const Color(0xFFEA580C),
                  icon: AppIcons.workflowPendingReview,
                ),
                DashboardMetricChipData.single(
                  label: 'Payment Completed',
                  value: '${metrics.paymentCompleted}',
                  color: const Color(0xFF047857),
                  icon: AppIcons.workflowApproved,
                ),
                DashboardMetricChipData.single(
                  label: 'Payment Exception',
                  value: '${metrics.paymentException}',
                  color: const Color(0xFFB91C1C),
                  icon: AppIcons.workflowRejected,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (String v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search idea, team, participant, remarks…',
                prefixIcon: const Icon(AppIcons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _filterChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                _filterChip(
                  label: 'Pending',
                  selected: _statusFilter == PaymentRecordStatus.pending,
                  onTap: () => setState(() => _statusFilter = PaymentRecordStatus.pending),
                ),
                _filterChip(
                  label: 'Completed',
                  selected: _statusFilter == PaymentRecordStatus.verified,
                  onTap: () => setState(() => _statusFilter = PaymentRecordStatus.verified),
                ),
                _filterChip(
                  label: 'Exception',
                  selected: _statusFilter == PaymentRecordStatus.rejected,
                  onTap: () => setState(() => _statusFilter = PaymentRecordStatus.rejected),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: kDashboardCardDecoration,
                child: const Text(
                  'No idea payments match your filters for this Ideathon.',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              )
            else
              ...rows.map(
                (IdeathonPaymentRow row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IdeathonPaymentRowCard(
                    row: row,
                    enabled: !_busy && widget.actor != null,
                    onOpenIdea: () => WorkspaceNavigator.openIdea(context, row.ideaId),
                    onOpenTeam: row.teamId.isEmpty
                        ? null
                        : () => WorkspaceNavigator.openTeam(context, row.teamId),
                    onOpenPayment: row.payment == null
                        ? null
                        : () => WorkspaceNavigator.openPayment(context, row.payment!.paymentId),
                    onOpenPayer: row.payerId.isEmpty
                        ? null
                        : () => WorkspaceNavigator.openUser(context, row.payerId),
                    onVerify: row.canVerify ? () => _verify(row) : null,
                    onReject: row.canReject ? () => _reject(row) : null,
                  ),
                ),
              ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: const Color(0xFFE0E7FF),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(color: selected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
    );
  }
}

class _IdeathonPaymentRowCard extends StatelessWidget {
  const _IdeathonPaymentRowCard({
    required this.row,
    required this.enabled,
    required this.onOpenIdea,
    required this.onOpenTeam,
    required this.onOpenPayment,
    required this.onOpenPayer,
    required this.onVerify,
    required this.onReject,
  });

  final IdeathonPaymentRow row;
  final bool enabled;
  final VoidCallback onOpenIdea;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onOpenPayment;
  final VoidCallback? onOpenPayer;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final PaymentModel? payment = row.payment;
    final String amount = payment == null
        ? '—'
        : PaymentFinanceHelpers.formatCurrency(payment.amount);
    final String date = payment == null ? '—' : formatDateTime(payment.createdAt);
    final String remarks = (payment?.remarks ?? '').trim();
    final String txn = (payment?.transactionId ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: onOpenIdea,
                      child: Text(
                        row.ideaTitle,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onOpenTeam,
                      child: Text(
                        row.teamName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PaymentStatusPill(
                status: row.displayPaymentStatus,
                compact: true,
                showAttentionDot: row.displayPaymentStatus == PaymentRecordStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _metaRow('Participant', row.payerName, onTap: onOpenPayer),
          _metaRow('Payment info', amount),
          _metaRow('Payment date', date),
          if (txn.isNotEmpty) _metaRow('Transaction', txn),
          if (remarks.isNotEmpty) _metaRow('Exception / remarks', remarks),
          if (payment == null) ...<Widget>[
            const SizedBox(height: 6),
            const Text(
              'No idea payment record found for this Ideathon member.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (onOpenPayment != null)
                ProblemWorkflowActionPill(
                  label: 'Payment details',
                  icon: AppIcons.payments,
                  semantic: ProblemWorkflowPillSemantic.primary,
                  onTap: onOpenPayment,
                ),
              if (onVerify != null)
                ProblemWorkflowActionPill(
                  label: 'Verify payment',
                  icon: AppIcons.workflowApproved,
                  semantic: ProblemWorkflowPillSemantic.filledBrand,
                  enabled: enabled,
                  onTap: onVerify,
                ),
              if (onReject != null)
                ProblemWorkflowActionPill(
                  label: 'Exception',
                  icon: AppIcons.workflowRejected,
                  semantic: ProblemWorkflowPillSemantic.closed,
                  enabled: enabled,
                  onTap: onReject,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? const Color(0xFF0F172A) : const Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
