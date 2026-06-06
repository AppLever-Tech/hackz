import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../responsive/responsive_helper.dart';
import '../../utils/coordinator_dashboard_service.dart';
import '../../workspace/workspace.dart';

class PaymentQueueCard extends StatelessWidget {
  const PaymentQueueCard({
    super.key,
    required this.item,
    required this.onVerify,
    required this.onReject,
    this.onOpenProof,
    this.onOpenIdea,
  });

  final PaymentQueueItem item;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback? onOpenProof;
  final VoidCallback? onOpenIdea;

  ButtonStyle _actionButtonStyle(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return ButtonStyle(
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: mobile ? 10 : 14, vertical: mobile ? 6 : 8),
      ),
      minimumSize: WidgetStatePropertyAll<Size>(Size(0, mobile ? 32 : 36)),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontSize: mobile ? 11 : 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;
    final String teamLabel = item.teamName.isEmpty ? 'Unnamed team' : item.teamName;
    final String ideaLabel = item.ideaName.isEmpty ? 'Idea not mapped' : item.ideaName;
    final bool mobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: mobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AppIcons.teams, color: Color(0xFFEA580C), size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${payment.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: item.ideaId.trim().isEmpty || onOpenIdea == null
                ? Text(
                    ideaLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  )
                : ContextPill(
                    label: ideaLabel,
                    semantic: ContextPillSemantic.idea,
                    onTap: onOpenIdea!,
                    compact: true,
                    fitContent: true,
                    allowHoverScale: false,
                  ),
          ),
          const SizedBox(height: 6),
          _buildActionsRow(context),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget verifyButton = FilledButton(
      onPressed: onVerify,
      style: _actionButtonStyle(context),
      child: const Text('Verify'),
    );
    final Widget rejectButton = OutlinedButton(
      onPressed: onReject,
      style: _actionButtonStyle(context),
      child: const Text('Reject'),
    );
    final Widget? proofPill = item.hasProof && onOpenProof != null
        ? ContextPill(
            label: 'Proof',
            semantic: ContextPillSemantic.generic,
            icon: AppIcons.attachments,
            onTap: onOpenProof!,
            compact: true,
            fitContent: true,
            height: mobile ? 30 : ContextPillMetrics.workspaceHeight,
            iconSize: mobile ? 14 : null,
            allowHoverScale: false,
          )
        : null;

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _TimePill(label: _relativeTime(item.submittedAt)),
              const Spacer(),
              if (proofPill != null) proofPill,
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(child: verifyButton),
              const SizedBox(width: 6),
              Expanded(child: rejectButton),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _TimePill(label: _relativeTime(item.submittedAt)),
        const Spacer(),
        verifyButton,
        const SizedBox(width: 6),
        rejectButton,
        if (proofPill != null) ...<Widget>[
          const SizedBox(width: 6),
          proofPill,
        ],
      ],
    );
  }

  static String _relativeTime(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(AppIcons.clock, size: 12, color: Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
