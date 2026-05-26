import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/idea_list_config.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../utils/idea_query_service.dart';
import 'common/context_pill_theme.dart';
import 'common/entity_card_pills.dart';
import 'data_view/data_table_column.dart';

/// Action bundle for [IdeaTableColumns]. Mirrors the callbacks already wired
/// into `IdeaCard` so the table view stays behaviorally identical to the list
/// view — just laid out differently.
class IdeaTableActions {
  const IdeaTableActions({
    required this.onOpenIdea,
    required this.onOpenTeam,
    required this.onOpenPayment,
    required this.onOpenEvaluation,
    required this.onOpenAttachments,
    required this.onEvaluate,
    required this.onUploadPayment,
  });

  final void Function(IdeaListItem item) onOpenIdea;
  final void Function(IdeaListItem item) onOpenTeam;
  final void Function(IdeaListItem item) onOpenPayment;
  final void Function(IdeaListItem item) onOpenEvaluation;
  final void Function(IdeaListItem item) onOpenAttachments;
  final void Function(IdeaListItem item) onEvaluate;
  final void Function(IdeaListItem item) onUploadPayment;
}

/// Per-feature column factory for the Ideas dashboard.
///
/// Sortable header keys (`'newest'`, `'status'`, `'score'`) match the screen's
/// `IdeaSortType` so the toolbar sort menu and the table header taps share a
/// single source of truth (`_sort`).
abstract final class IdeaTableColumns {
  static List<DataTableColumn<IdeaListItem>> build({
    required IdeaListConfig config,
    required IdeaTableActions actions,
  }) {
    final Set<IdeaSortType> enabledSorts = config.enabledSorts;
    return <DataTableColumn<IdeaListItem>>[
      DataTableColumn<IdeaListItem>(
        label: 'Idea',
        flex: 5,
        minWidth: 220,
        sortKey: enabledSorts.contains(IdeaSortType.newest) ? 'newest' : null,
        cell: (BuildContext context, IdeaListItem item) {
          final String title = item.idea.ideaTitle.trim().isEmpty
              ? 'Untitled Idea'
              : item.idea.ideaTitle.trim();
          return EntityCardPills.workspace(
            title,
            ContextPillSemantic.idea,
            () => actions.onOpenIdea(item),
            icon: AppIcons.ideas,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Team',
        flex: 3,
        minWidth: 140,
        cell: (BuildContext context, IdeaListItem item) {
          final String teamLabel =
              item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();
          final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
          if (teamId.isEmpty) {
            return EntityCardPills.meta(teamLabel, icon: AppIcons.teams);
          }
          return EntityCardPills.workspace(
            teamLabel,
            ContextPillSemantic.team,
            () => actions.onOpenTeam(item),
            icon: AppIcons.teams,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Problem',
        flex: 4,
        minWidth: 180,
        cell: (BuildContext context, IdeaListItem item) =>
            _ProblemCell(idea: item.idea),
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Dept',
        flex: 2,
        minWidth: 90,
        cell: (BuildContext context, IdeaListItem item) {
          final String dept = item.idea.teamDepartmentCode.trim();
          if (dept.isEmpty) return const _MutedDash();
          return _MutedTag(label: dept, icon: AppIcons.departments);
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Status',
        flex: 3,
        minWidth: 140,
        sortKey: enabledSorts.contains(IdeaSortType.status) ? 'status' : null,
        cell: (BuildContext context, IdeaListItem item) =>
            _StatusCell(status: item.idea.status),
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Score',
        flex: 1,
        minWidth: 80,
        align: Alignment.center,
        sortKey: enabledSorts.contains(IdeaSortType.score) ? 'score' : null,
        cell: (BuildContext context, IdeaListItem item) {
          final double? score = item.score?.score;
          if (score == null) return const _MutedDash();
          final bool clickable = canOpenEvaluation(item);
          final Widget chip = _ScoreChip(value: score);
          if (!clickable) return chip;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => actions.onOpenEvaluation(item),
            child: chip,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Payment',
        flex: 3,
        minWidth: 140,
        cell: (BuildContext context, IdeaListItem item) {
          final PaymentModel? payment = item.payment;
          final Widget paymentLabel = _PaymentCell(payment: payment);
          if (payment == null) return paymentLabel;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => actions.onOpenPayment(item),
            child: paymentLabel,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Files',
        flex: 1,
        minWidth: 90,
        align: Alignment.center,
        cell: (BuildContext context, IdeaListItem item) {
          if (item.attachmentCount <= 0) return const _MutedDash();
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => actions.onOpenAttachments(item),
            child: _AttachmentsBadge(count: item.attachmentCount),
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Actions',
        flex: 2,
        minWidth: 110,
        align: Alignment.centerRight,
        cell: (BuildContext context, IdeaListItem item) {
          final bool showPay =
              config.canUploadPayment && item.canUploadPayment && item.team != null;
          final bool canEval =
              config.canEvaluate && item.idea.status != IdeaStatus.pendingSubmission;
          if (!showPay && !canEval) return const _MutedDash();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showPay)
                _ActionIconButton(
                  icon: AppIcons.payments,
                  tooltip: 'Upload payment',
                  onPressed: () => actions.onUploadPayment(item),
                ),
              if (canEval)
                _ActionIconButton(
                  icon: AppIcons.scoring,
                  tooltip: 'Evaluate',
                  onPressed: () => actions.onEvaluate(item),
                ),
            ],
          );
        },
      ),
    ];
  }

  /// Mirrors `_IdeasListScreenState._canOpenEvaluation` so the score column's
  /// click affordance matches the list view's evaluation pill.
  static bool canOpenEvaluation(IdeaListItem item) {
    if (item.score != null) return true;
    return item.idea.status == IdeaStatus.evaluated ||
        item.idea.status == IdeaStatus.approved ||
        item.idea.status == IdeaStatus.underReview;
  }
}

class _ProblemCell extends StatelessWidget {
  const _ProblemCell({required this.idea});
  final IdeaModel idea;

  @override
  Widget build(BuildContext context) {
    final String number = idea.problemNumber.trim();
    final String title = idea.problemTitle.trim();
    if (number.isEmpty && title.isEmpty) return const _MutedDash();
    final String label = number.isEmpty
        ? title
        : title.isEmpty
            ? number
            : '$number  $title';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(AppIcons.problems, size: 14, color: Color(0xFF64748B)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.status});
  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(_iconFor(status), size: 14, color: _colorFor(status)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _labelFor(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _colorFor(status),
            ),
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => AppIcons.statusPendingSubmission,
        IdeaStatus.submitted => AppIcons.statusSubmitted,
        IdeaStatus.underReview => AppIcons.statusUnderReview,
        IdeaStatus.evaluated => AppIcons.statusEvaluated,
        IdeaStatus.approved => AppIcons.statusApproved,
        IdeaStatus.rejected => AppIcons.statusRejected,
      };

  static Color _colorFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => const Color(0xFF94A3B8),
        IdeaStatus.submitted => const Color(0xFF7C3AED),
        IdeaStatus.underReview => const Color(0xFFEA580C),
        IdeaStatus.evaluated => const Color(0xFF0EA5E9),
        IdeaStatus.approved => const Color(0xFF059669),
        IdeaStatus.rejected => const Color(0xFFDC2626),
      };

  static String _labelFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => 'Pending',
        IdeaStatus.submitted => 'Submitted',
        IdeaStatus.underReview => 'Under Review',
        IdeaStatus.evaluated => 'Evaluated',
        IdeaStatus.approved => 'Approved',
        IdeaStatus.rejected => 'Rejected',
      };
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD9A8)),
      ),
      child: Text(
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45309),
        ),
      ),
    );
  }
}

class _PaymentCell extends StatelessWidget {
  const _PaymentCell({required this.payment});
  final PaymentModel? payment;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color, String label}) v = _resolve(payment);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(v.icon, size: 14, color: v.color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            v.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: v.color,
            ),
          ),
        ),
      ],
    );
  }

  static ({IconData icon, Color color, String label}) _resolve(PaymentModel? p) {
    if (p == null) {
      return (
        icon: AppIcons.payments,
        color: const Color(0xFF94A3B8),
        label: 'No payment',
      );
    }
    return switch (p.status) {
      PaymentRecordStatus.pending => (
          icon: AppIcons.statusUnderReview,
          color: const Color(0xFFEA580C),
          label: 'Pending',
        ),
      PaymentRecordStatus.verified => (
          icon: AppIcons.statusApproved,
          color: const Color(0xFF059669),
          label: 'Verified',
        ),
      PaymentRecordStatus.rejected => (
          icon: AppIcons.statusRejected,
          color: const Color(0xFFDC2626),
          label: 'Rejected',
        ),
    };
  }
}

class _AttachmentsBadge extends StatelessWidget {
  const _AttachmentsBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(AppIcons.attachments, size: 12, color: Color(0xFF1D4ED8)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedTag extends StatelessWidget {
  const _MutedTag({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

class _MutedDash extends StatelessWidget {
  const _MutedDash();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }
}
