import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/coordinator_dashboard_service.dart';
import 'coordinator_panel_card.dart';

class DepartmentOperationalSnapshot extends StatelessWidget {
  const DepartmentOperationalSnapshot({super.key, required this.snapshot});

  final DepartmentOperationalSnapshotVm snapshot;

  @override
  Widget build(BuildContext context) {
    return CoordinatorPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Department Operational Snapshot', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Compact processing health for coordinator workflow', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 300 ? 2 : 1;
                return GridView.count(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: crossAxisCount == 2 ? 2.45 : 4.2,
                  children: <Widget>[
                    _SnapshotTile(icon: AppIcons.ideas, label: 'Awaiting Payment', value: '${snapshot.ideasAwaitingPayment}', tint: const Color(0xFF7C3AED)),
                    _SnapshotTile(icon: AppIcons.teams, label: 'Blocked Teams', value: '${snapshot.blockedTeams}', tint: const Color(0xFFEA580C)),
                    _SnapshotTile(icon: AppIcons.verification, label: 'Completion', value: '${(snapshot.verificationCompletion * 100).round()}%', tint: const Color(0xFF16A34A)),
                    _SnapshotTile(icon: AppIcons.clock, label: 'Submission Window', value: snapshot.activeSubmissionWindow, tint: const Color(0xFF0284C7)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                const SizedBox(height: 1),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

