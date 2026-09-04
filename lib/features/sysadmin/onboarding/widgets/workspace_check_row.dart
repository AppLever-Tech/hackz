import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../services/tenant_workspace_validator.dart';

class WorkspaceCheckRow extends StatelessWidget {
  const WorkspaceCheckRow({super.key, required this.check, this.pending = false});

  final TenantWorkspaceCheck check;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final Color fg = pending
        ? const Color(0xFF64748B)
        : check.ok
            ? const Color(0xFF047857)
            : const Color(0xFFB91C1C);
    final Color bg = pending
        ? const Color(0xFFF8FAFC)
        : check.ok
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            pending
                ? AppIcons.clock
                : check.ok
                    ? AppIcons.workflowApproved
                    : AppIcons.error,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  check.label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
                ),
                if (check.detail.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    check.detail,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
