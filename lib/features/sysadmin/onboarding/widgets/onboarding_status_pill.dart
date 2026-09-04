import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/theme/app_icons.dart';

class OnboardingStatusPill extends StatelessWidget {
  const OnboardingStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final TenantStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      TenantStatus.active => (const Color(0xFF047857), const Color(0xFFECFDF5)),
      TenantStatus.setup => (const Color(0xFFC2410C), const Color(0xFFFFF7ED)),
      TenantStatus.inactive => (const Color(0xFF64748B), const Color(0xFFF1F5F9)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class WorkspaceConnectionPill extends StatelessWidget {
  const WorkspaceConnectionPill({
    super.key,
    required this.label,
    required this.ready,
    required this.connected,
  });

  final String label;
  final bool ready;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final Color fg = ready
        ? const Color(0xFF047857)
        : connected
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF64748B);
    final Color bg = ready
        ? const Color(0xFFECFDF5)
        : connected
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            ready
                ? AppIcons.workflowApproved
                : connected
                    ? AppIcons.verification
                    : AppIcons.clock,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
