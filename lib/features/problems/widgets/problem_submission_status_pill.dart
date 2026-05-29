import 'package:flutter/material.dart';

import '../validators/problem_submission_validators.dart';

/// Compact one-line submission indicator for a problem.
///
/// Rendered in `ProblemCard`'s meta row (and inside the innovation submission
/// workspace hero). States:
///   * open                                   → "{remaining}/{total} ideas" or
///                                              "Closes in 2 days" when a
///                                              deadline is set and is the
///                                              tightest constraint
///   * limitReached                           → "Idea limit reached"
///   * deadlinePassed                         → "Submission closed"
///   * inactive                               → "Submissions inactive"
///
/// The widget stays small (28px tall) and never wraps — designed to be
/// dropped next to existing entity-card meta pills without breaking the row.
class ProblemSubmissionStatusPill extends StatelessWidget {
  const ProblemSubmissionStatusPill({
    super.key,
    required this.gate,
    this.dense = true,
  });

  final IdeaSubmissionGate gate;

  /// When true (default) the pill renders at the same height as
  /// `EntityCardPills.meta(...)`. Set false for slightly larger surfaces
  /// (e.g. innovation submission workspace hero).
  final bool dense;

  static const _PillStyle _open = _PillStyle(
    bg: Color(0xFFEEF6FF),
    border: Color(0xFFBFD9F8),
    fg: Color(0xFF1D4ED8),
    icon: Icons.bolt_rounded,
  );
  static const _PillStyle _amber = _PillStyle(
    bg: Color(0xFFFFF7E6),
    border: Color(0xFFFCD9A4),
    fg: Color(0xFFB45309),
    icon: Icons.schedule_rounded,
  );
  static const _PillStyle _blocked = _PillStyle(
    bg: Color(0xFFFDECEC),
    border: Color(0xFFF5C2C0),
    fg: Color(0xFFB91C1C),
    icon: Icons.block_rounded,
  );
  static const _PillStyle _muted = _PillStyle(
    bg: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    fg: Color(0xFF64748B),
    icon: Icons.pause_circle_outline_rounded,
  );

  @override
  Widget build(BuildContext context) {
    final _PillData data = _resolve();
    final EdgeInsets pad = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final double fontSize = dense ? 11 : 12;
    final double iconSize = dense ? 13 : 14;

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: data.style.bg,
        border: Border.all(color: data.style.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(data.style.icon, size: iconSize, color: data.style.fg),
          const SizedBox(width: 5),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: data.style.fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  _PillData _resolve() {
    switch (gate.state) {
      case IdeaSubmissionGateState.open:
        // If a deadline is configured and is the tighter constraint (i.e.
        // closing within 7 days), surface that instead of "X/Y ideas".
        final Duration? d = gate.timeUntilDeadline;
        if (d != null && d.inDays <= 7) {
          return _PillData(_amber, _formatDeadlineLabel(d));
        }
        return _PillData(
          _open,
          '${gate.submittedCount}/${gate.effectiveMaxIdeas} ideas',
        );
      case IdeaSubmissionGateState.limitReached:
        return const _PillData(_blocked, 'Idea limit reached');
      case IdeaSubmissionGateState.deadlinePassed:
        return const _PillData(_blocked, 'Submission closed');
      case IdeaSubmissionGateState.inactive:
        return const _PillData(_muted, 'Submissions inactive');
    }
  }

  static String _formatDeadlineLabel(Duration d) {
    if (d.inMinutes <= 0) return 'Deadline reached';
    if (d.inHours < 1) {
      final int m = d.inMinutes;
      return 'Closes in $m min';
    }
    if (d.inHours < 24) {
      final int h = d.inHours;
      return 'Closes in $h hour${h == 1 ? '' : 's'}';
    }
    final int days = d.inDays;
    return 'Closes in $days day${days == 1 ? '' : 's'}';
  }
}

class _PillStyle {
  const _PillStyle({
    required this.bg,
    required this.border,
    required this.fg,
    required this.icon,
  });
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;
}

class _PillData {
  const _PillData(this.style, this.label);
  final _PillStyle style;
  final String label;
}
