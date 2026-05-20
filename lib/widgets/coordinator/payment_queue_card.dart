import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/coordinator_dashboard_service.dart';

class PaymentQueueCard extends StatelessWidget {
  const PaymentQueueCard({
    super.key,
    required this.item,
    required this.onVerify,
    required this.onReject,
    required this.onViewProof,
    this.onOpenProblem,
  });

  final PaymentQueueItem item;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewProof;
  final VoidCallback? onOpenProblem;

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x10273B6A), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14)),
                child: const Icon(AppIcons.payments, color: Color(0xFFEA580C), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.teamName.isEmpty ? 'Unnamed team' : item.teamName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 3),
                    InkWell(
                      onTap: onOpenProblem,
                      child: Text(
                        item.problemName.isEmpty ? 'Problem not mapped' : item.problemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: onOpenProblem == null ? const Color(0xFF64748B) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Rs ${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(icon: AppIcons.clock, label: _relativeTime(item.submittedAt), color: const Color(0xFF475569), bg: const Color(0xFFF1F5F9)),
              _InfoPill(icon: item.hasProof ? AppIcons.attachmentImage : AppIcons.info, label: item.hasProof ? 'Proof ready' : 'Proof missing', color: item.hasProof ? const Color(0xFF047857) : const Color(0xFFB45309), bg: item.hasProof ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED)),
              if (item.isOverdue) const _InfoPill(icon: AppIcons.statusRejected, label: 'Overdue', color: Color(0xFFB91C1C), bg: Color(0xFFFEF2F2)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onVerify,
                icon: const Icon(AppIcons.statusApproved, size: 16),
                label: const Text('Verify'),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(AppIcons.statusRejected, size: 16),
                label: const Text('Reject'),
              ),
              TextButton.icon(
                onPressed: item.hasProof ? onViewProof : null,
                icon: const Icon(AppIcons.preview, size: 16),
                label: const Text('View Proof'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
