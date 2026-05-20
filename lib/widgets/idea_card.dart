import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
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
    this.onOpenProblem,
    this.onOpenTeam,
    this.showViewDetails = true,
    this.onEvaluate,
    required this.showUploadPayment,
    this.onUploadPayment,
  });

  final IdeaListItem item;
  final bool canViewStatus;
  final bool canEvaluate;
  final VoidCallback onViewDetails;
  final VoidCallback? onOpenProblem;
  final VoidCallback? onOpenTeam;
  final bool showViewDetails;
  final VoidCallback? onEvaluate;
  final bool showUploadPayment;
  final VoidCallback? onUploadPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = _statusStyle(item.idea.status);
    final ideaTitle = item.idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : item.idea.ideaTitle.trim();
    final problemTitle = item.idea.problemTitle.trim().isEmpty ? 'Untitled Problem' : item.idea.problemTitle.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _metaPill(
                icon: AppIcons.problems,
                label: item.idea.problemNumber.isEmpty ? 'N/A' : item.idea.problemNumber,
                emphasized: true,
                onTap: onOpenProblem,
              ),
              const Spacer(),
              if (canViewStatus)
                _metaPill(
                  icon: _statusIcon(item.idea.status),
                  label: badge.label,
                  fg: badge.fg,
                  bg: badge.bg,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(AppIcons.ideas, size: 20, color: Color(0xFF6A38FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ideaTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.idea.description.trim().isEmpty ? '-' : item.idea.description.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF475569)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(AppIcons.problems, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onOpenProblem,
                  child: Text(
                    problemTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onOpenProblem == null ? const Color(0xFF64748B) : const Color(0xFF334155),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _metaPill(
                icon: AppIcons.teams,
                label: 'Team: ${item.teamName.trim().isEmpty ? '-' : item.teamName}',
                onTap: onOpenTeam,
              ),
              _metaPill(icon: AppIcons.clock, label: 'Created: ${_formatDate(item.idea.createdAt)}'),
              if (item.idea.status == IdeaStatus.pendingSubmission || item.payment != null)
                _metaPill(icon: AppIcons.payments, label: _paymentChip(item.payment)),
              if (item.score != null)
                _metaPill(icon: AppIcons.scoring, label: 'Score: ${item.score!.score.toStringAsFixed(1)} / 10'),
              if (item.score != null)
                _metaPill(
                  icon: AppIcons.judges,
                  label: 'Judge: ${item.judgeName ?? item.score!.judgeId}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (showViewDetails)
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(AppIcons.openInNew, size: 16),
                  label: const Text('View Details'),
                ),
              if (showUploadPayment) ...<Widget>[
                SizedBox(width: showViewDetails ? 8 : 0),
                FilledButton.icon(
                  onPressed: onUploadPayment,
                  icon: const Icon(AppIcons.payments, size: 16),
                  label: const Text('Upload Payment'),
                ),
              ],
              if (canEvaluate) ...<Widget>[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onEvaluate,
                  icon: const Icon(AppIcons.scoring, size: 16),
                  label: const Text('Evaluate'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return AppIcons.statusSubmitted;
      case IdeaStatus.submitted:
        return AppIcons.submissions;
      case IdeaStatus.underReview:
        return AppIcons.statusUnderReview;
      case IdeaStatus.evaluated:
        return AppIcons.statusEvaluated;
      case IdeaStatus.approved:
        return AppIcons.statusApproved;
      case IdeaStatus.rejected:
        return AppIcons.statusRejected;
    }
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

  Widget _metaPill({
    required IconData icon,
    required String label,
    bool emphasized = false,
    Color? fg,
    Color? bg,
    VoidCallback? onTap,
  }) {
    final textColor = fg ?? (emphasized ? const Color(0xFF2E43C6) : const Color(0xFF334155));
    final background = bg ?? (emphasized ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9));
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
