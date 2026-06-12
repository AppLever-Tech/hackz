import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/team_change_request.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

/// Visual semantics for a team-member chip in a diff view.
enum TeamDiffStatus {
  unchanged,
  added,
  removed,
}

/// Compact context-pill that conveys diff status (kept/added/removed) over a
/// teammate. Reuses the platform [ContextPill] so navigation + theming stay
/// consistent with the rest of the app.
class TeamMemberDiffChip extends StatelessWidget {
  const TeamMemberDiffChip({
    super.key,
    required this.member,
    required this.status,
    this.onRemoveTap,
  });

  final TeamMemberSnapshot member;
  final TeamDiffStatus status;
  final VoidCallback? onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final _DiffVisuals v = _visualsFor(status);
    final String label = member.displayName.trim().isEmpty
        ? member.userId
        : member.displayName.trim();

    final Widget pill = ContextPill(
      label: label,
      semantic: ContextPillSemantic.user,
      icon: AppIcons.student,
      onTap: () => WorkspaceNavigator.openUser(context, member.userId),
      compact: true,
    );

    if (status == TeamDiffStatus.unchanged && onRemoveTap == null) {
      return pill;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: v.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (v.badge != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: v.foreground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                v.badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          pill,
          if (onRemoveTap != null) ...<Widget>[
            const SizedBox(width: 2),
            InkWell(
              onTap: onRemoveTap,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _DiffVisuals _visualsFor(TeamDiffStatus status) {
    switch (status) {
      case TeamDiffStatus.unchanged:
        return const _DiffVisuals(
          foreground: Color(0xFF475569),
          background: Color(0xFFF8FAFF),
          border: Color(0xFFE2E8F0),
          badge: null,
        );
      case TeamDiffStatus.added:
        return const _DiffVisuals(
          foreground: Color(0xFF047857),
          background: Color(0xFFE9FAF0),
          border: Color(0xFFB9EBC8),
          badge: '+',
        );
      case TeamDiffStatus.removed:
        return const _DiffVisuals(
          foreground: Color(0xFFB91C1C),
          background: Color(0xFFFEECEC),
          border: Color(0xFFF8C4C4),
          badge: '−',
        );
    }
  }
}

class _DiffVisuals {
  const _DiffVisuals({
    required this.foreground,
    required this.background,
    required this.border,
    required this.badge,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final String? badge;
}

/// Side-by-side (or stacked, on narrow widths) Current vs Proposed team
/// visualisation. Always renders the diff status overlay on the proposed
/// side so the change is obvious at a glance.
class TeamMemberDiffView extends StatelessWidget {
  const TeamMemberDiffView({
    super.key,
    required this.currentMembers,
    required this.proposedMembers,
    this.stackedBreakpoint = 560,
  });

  final List<TeamMemberSnapshot> currentMembers;
  final List<TeamMemberSnapshot> proposedMembers;
  final double stackedBreakpoint;

  @override
  Widget build(BuildContext context) {
    final Set<String> currentIds = currentMembers.map((m) => m.userId).toSet();
    final Set<String> proposedIds = proposedMembers.map((m) => m.userId).toSet();

    final List<TeamMemberSnapshot> sortedCurrent = _sortByName(currentMembers);
    final List<TeamMemberSnapshot> sortedProposed = _sortByName(<TeamMemberSnapshot>[
      ...proposedMembers,
      // include removed entries on the proposed side as visually struck out
      ...currentMembers.where((TeamMemberSnapshot m) => !proposedIds.contains(m.userId)),
    ]);

    final Widget current = _SidePanel(
      title: 'Current team',
      tone: const Color(0xFF475569),
      icon: AppIcons.teams,
      child: _MemberWrap(
        members: sortedCurrent,
        statusResolver: (TeamMemberSnapshot _) => TeamDiffStatus.unchanged,
        emptyText: 'No current members',
      ),
    );
    final Widget proposed = _SidePanel(
      title: 'Proposed team',
      tone: const Color(0xFF6A38FF),
      icon: AppIcons.teams,
      child: _MemberWrap(
        members: sortedProposed,
        statusResolver: (TeamMemberSnapshot m) {
          final bool inCurrent = currentIds.contains(m.userId);
          final bool inProposed = proposedIds.contains(m.userId);
          if (inCurrent && inProposed) return TeamDiffStatus.unchanged;
          if (!inCurrent && inProposed) return TeamDiffStatus.added;
          return TeamDiffStatus.removed;
        },
        emptyText: 'No proposed members',
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < stackedBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              current,
              const SizedBox(height: 12),
              proposed,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: current),
            const SizedBox(width: 12),
            Expanded(child: proposed),
          ],
        );
      },
    );
  }

  static List<TeamMemberSnapshot> _sortByName(List<TeamMemberSnapshot> items) {
    final List<TeamMemberSnapshot> sorted = List<TeamMemberSnapshot>.from(items);
    sorted.sort((TeamMemberSnapshot a, TeamMemberSnapshot b) {
      final String aName = a.displayName.trim().toLowerCase();
      final String bName = b.displayName.trim().toLowerCase();
      final int byName = aName.compareTo(bName);
      if (byName != 0) return byName;
      return a.userId.compareTo(b.userId);
    });
    return sorted;
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.tone,
    required this.icon,
    required this.child,
  });

  final String title;
  final Color tone;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: tone),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: tone,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MemberWrap extends StatelessWidget {
  const _MemberWrap({
    required this.members,
    required this.statusResolver,
    required this.emptyText,
  });

  final List<TeamMemberSnapshot> members;
  final TeamDiffStatus Function(TeamMemberSnapshot) statusResolver;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: members
          .map(
            (TeamMemberSnapshot m) => TeamMemberDiffChip(
              member: m,
              status: statusResolver(m),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Lightweight summary card with `Added:` and `Removed:` sections used in the
/// faculty review step and dept admin review pane.
class TeamMemberDiffSummary extends StatelessWidget {
  const TeamMemberDiffSummary({super.key, required this.payload});

  final TeamChangePayload payload;

  @override
  Widget build(BuildContext context) {
    final List<TeamMemberSnapshot> added = payload.addedMembers;
    final List<TeamMemberSnapshot> removed = payload.removedMembers;

    if (added.isEmpty && removed.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'No member changes yet — add or remove students above.',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (added.isNotEmpty) ...<Widget>[
          _line('Added', '+', const Color(0xFF047857), added),
        ],
        if (added.isNotEmpty && removed.isNotEmpty) const SizedBox(height: 8),
        if (removed.isNotEmpty) ...<Widget>[
          _line('Removed', '−', const Color(0xFFB91C1C), removed),
        ],
      ],
    );
  }

  Widget _line(String label, String badge, Color tone, List<TeamMemberSnapshot> members) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$label · ${members.length}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: tone,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: members
                    .map(
                      (TeamMemberSnapshot m) => TeamMemberDiffChip(
                        member: m,
                        status: label == 'Added' ? TeamDiffStatus.added : TeamDiffStatus.removed,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
