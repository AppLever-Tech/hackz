import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import '../../utils/department_dashboard_service.dart';

class PaymentOperationsWidget extends StatelessWidget {
  const PaymentOperationsWidget({
    super.key,
    required this.pendingPayments,
    required this.submittedIdeas,
    required this.evaluatedIdeas,
    required this.approvedIdeas,
    required this.rejectedIdeas,
    required this.paymentVerificationRate,
    required this.evaluationCompletionRate,
  });

  final int pendingPayments;
  final int submittedIdeas;
  final int evaluatedIdeas;
  final int approvedIdeas;
  final int rejectedIdeas;
  final double paymentVerificationRate;
  final double evaluationCompletionRate;

  @override
  Widget build(BuildContext context) {
    final inFixedPanel = ResponsiveHelper.isDesktopOrWider(context);
    final Widget body = Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _MiniOperationCard(label: 'Pending payments', value: '$pendingPayments', color: const Color(0xFFEA580C))),
            const SizedBox(width: 10),
            Expanded(child: _MiniOperationCard(label: 'Submitted ideas', value: '$submittedIdeas', color: const Color(0xFF6A38FF))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _MiniOperationCard(label: 'Evaluated ideas', value: '$evaluatedIdeas', color: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: _MiniOperationCard(label: 'Rejected ideas', value: '$rejectedIdeas', color: const Color(0xFFDC2626))),
          ],
        ),
        const SizedBox(height: 14),
        _ProgressMetric(label: 'Payment verification', value: paymentVerificationRate, color: const Color(0xFF0891B2)),
        const SizedBox(height: 12),
        _ProgressMetric(label: 'Evaluation completion', value: evaluationCompletionRate, color: const Color(0xFF16A34A)),
        const SizedBox(height: 12),
        _ApprovalMix(approvedIdeas: approvedIdeas, rejectedIdeas: rejectedIdeas),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Idea & Payment Operations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Operational workload without rankings or showcase metrics', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        if (inFixedPanel)
          Expanded(child: SingleChildScrollView(child: body))
        else
          body,
      ],
    );
  }
}

class _MiniOperationCard extends StatelessWidget {
  const _MiniOperationCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double safeValue = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
            Text('${(safeValue * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(minHeight: 8, value: safeValue, color: color, backgroundColor: const Color(0xFFE8ECF8)),
        ),
      ],
    );
  }
}

class _ApprovalMix extends StatelessWidget {
  const _ApprovalMix({required this.approvedIdeas, required this.rejectedIdeas});

  final int approvedIdeas;
  final int rejectedIdeas;

  @override
  Widget build(BuildContext context) {
    final int total = approvedIdeas + rejectedIdeas;
    final double approved = total == 0 ? 0 : approvedIdeas / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Approval / rejection distribution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: total == 0 ? 1 : (approved * 100).round().clamp(1, 99).toInt(),
                child: Container(height: 10, color: const Color(0xFF16A34A)),
              ),
              Expanded(
                flex: total == 0 ? 1 : ((1 - approved) * 100).round().clamp(1, 99).toInt(),
                child: Container(height: 10, color: const Color(0xFFDC2626)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Approved $approvedIdeas · Rejected $rejectedIdeas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      ],
    );
  }
}
