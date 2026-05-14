import 'package:flutter/material.dart';

import '../screens/common/dashboard_components.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../utils/idea_query_service.dart';

class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.item,
    required this.canViewStatus,
    required this.canEvaluate,
    required this.onViewDetails,
    this.showViewDetails = true,
    this.onEvaluate,
    required this.showUploadPayment,
    this.onUploadPayment,
  });

  final IdeaListItem item;
  final bool canViewStatus;
  final bool canEvaluate;
  final VoidCallback onViewDetails;
  final bool showViewDetails;
  final VoidCallback? onEvaluate;
  final bool showUploadPayment;
  final VoidCallback? onUploadPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = _statusStyle(item.idea.status);
    final paymentChip = _paymentChip(item.payment);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.idea.problemNumber.isEmpty ? 'N/A' : item.idea.problemNumber,
                  style: const TextStyle(
                    color: Color(0xFF2E43C6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (canViewStatus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      color: badge.fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.idea.problemTitle.trim().isEmpty ? 'Untitled Problem' : item.idea.problemTitle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            item.idea.description.trim().isEmpty ? '-' : item.idea.description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _metaPill('Team: ${item.teamName.trim().isEmpty ? '-' : item.teamName}'),
              _metaPill('Created: ${_formatDate(item.idea.createdAt)}'),
              if (item.idea.status == IdeaStatus.pendingSubmission || item.payment != null) _metaPill(paymentChip),
              if (item.score != null) _metaPill('Score: ${item.score!.score.toStringAsFixed(1)} / 10'),
              if (item.score != null) _metaPill('Judge: ${item.judgeName ?? item.score!.judgeId}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (showViewDetails)
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Details'),
                ),
              if (showUploadPayment) ...<Widget>[
                SizedBox(width: showViewDetails ? 8 : 0),
                FilledButton.icon(
                  onPressed: onUploadPayment,
                  icon: const Icon(Icons.payment_outlined, size: 16),
                  label: const Text('Upload Payment'),
                ),
              ],
              if (canEvaluate) ...<Widget>[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onEvaluate,
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Evaluate'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _paymentChip(PaymentModel? payment) {
    if (payment == null) return 'Payment: Not uploaded';
    switch (payment.status) {
      case PaymentRecordStatus.pending:
        return 'Payment: Pending';
      case PaymentRecordStatus.verified:
        return 'Payment: Verified';
      case PaymentRecordStatus.rejected:
        return 'Payment: Rejected';
    }
  }

  Widget _metaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }

  _StatusStyle _statusStyle(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return const _StatusStyle('Pending Submission', Color(0xFFE8ECFF), Color(0xFF2E43C6));
      case IdeaStatus.submitted:
        return const _StatusStyle('Submitted', Color(0xFFEFE8FF), Color(0xFF5C3CC0));
      case IdeaStatus.underReview:
        return const _StatusStyle('Under Review', Color(0xFFFFF1E4), Color(0xFFB56A11));
      case IdeaStatus.evaluated:
        return const _StatusStyle('Evaluated', Color(0xFFE7F9F1), Color(0xFF177C50));
      case IdeaStatus.approved:
        return const _StatusStyle('Approved', Color(0xFFE3F7EA), Color(0xFF0D7A45));
      case IdeaStatus.rejected:
        return const _StatusStyle('Rejected', Color(0xFFFDECEC), Color(0xFFB93838));
    }
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.bg, this.fg);

  final String label;
  final Color bg;
  final Color fg;
}
