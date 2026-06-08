import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';

class VerificationTimelineEvent {
  const VerificationTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.color,
    required this.isComplete,
  });

  final String title;
  final String subtitle;
  final DateTime? when;
  final IconData icon;
  final Color color;
  final bool isComplete;
}

class VerificationTimelineWidget extends StatelessWidget {
  const VerificationTimelineWidget({
    super.key,
    required this.payment,
    this.remarks,
  });

  final PaymentModel payment;
  final String? remarks;

  static List<VerificationTimelineEvent> eventsFor(PaymentModel payment, {String? remarks}) {
    final submitted = VerificationTimelineEvent(
      title: 'Payment submitted',
      subtitle: 'Student uploaded payment proof',
      when: payment.createdAt,
      icon: AppIcons.submissions,
      color: const Color(0xFF475569),
      isComplete: true,
    );
    final underReview = VerificationTimelineEvent(
      title: 'Under verification',
      subtitle: payment.status == PaymentRecordStatus.pending
          ? 'Coordinator review in progress'
          : 'Review completed',
      when: payment.status == PaymentRecordStatus.pending ? null : payment.verifiedAt ?? payment.createdAt,
      icon: AppIcons.workflowPendingReview,
      color: const Color(0xFF1E88E5),
      isComplete: payment.status != PaymentRecordStatus.pending,
    );
    final resolved = VerificationTimelineEvent(
      title: payment.status == PaymentRecordStatus.rejected ? 'Payment rejected' : 'Payment verified',
      subtitle: remarks?.trim().isNotEmpty == true
          ? remarks!.trim()
          : (payment.status == PaymentRecordStatus.rejected ? 'Rejected by coordinator' : 'Verified by coordinator'),
      when: payment.verifiedAt,
      icon: payment.status == PaymentRecordStatus.rejected ? AppIcons.statusRejected : AppIcons.workflowApproved,
      color: PaymentFinanceHelpers.statusColor(payment.status),
      isComplete: payment.status != PaymentRecordStatus.pending,
    );
    return <VerificationTimelineEvent>[submitted, underReview, resolved];
  }

  @override
  Widget build(BuildContext context) {
    final events = eventsFor(payment, remarks: remarks ?? payment.remarks);
    return Column(
      children: List<Widget>.generate(events.length, (int index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: event.isComplete ? 0.18 : 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: event.color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(event.icon, size: 14, color: event.color),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(event.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    if (event.when != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        PaymentFinanceHelpers.formatDate(event.when!),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
