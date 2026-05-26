import 'package:flutter/material.dart';

/// Section completion summary used by the authoring workspace.
class AuthoringSectionStatus {
  const AuthoringSectionStatus({
    required this.completed,
    required this.total,
    this.required = false,
  });

  final int completed;
  final int total;

  /// Whether the section is required to publish (renders the section as
  /// "incomplete" instead of optional when [completed] < [total]).
  final bool required;

  bool get isFull => total > 0 && completed >= total;

  bool get isEmpty => completed == 0;

  bool get isPartial => !isFull && !isEmpty;
}

/// Premium expandable section card used in the problem authoring workspace.
class ProblemAuthoringSection extends StatelessWidget {
  const ProblemAuthoringSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.status,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.headerHint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final AuthoringSectionStatus status;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  /// Short prompt rendered inside the body when collapsed-state is opened
  /// for the first time. Optional.
  final String? headerHint;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded ? const Color(0xFFD9D3FF) : const Color(0xFFE6EAF3),
          width: expanded ? 1.4 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF273B6A).withValues(alpha: expanded ? 0.10 : 0.05),
            blurRadius: expanded ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AuthoringStatusChip(status: status),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (headerHint != null) ...<Widget>[
                    _AuthoringSectionHint(text: headerHint!),
                    const SizedBox(height: 12),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthoringSectionHint extends StatelessWidget {
  const _AuthoringSectionHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF6F3FF), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2DAFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFF6A38FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF4C3B8E),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "X/Y" or "✓ done" status pill.
class AuthoringStatusChip extends StatelessWidget {
  const AuthoringStatusChip({super.key, required this.status});

  final AuthoringSectionStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.total == 0) return const SizedBox.shrink();

    final bool full = status.isFull;
    final bool empty = status.isEmpty;
    final Color fg;
    final Color bg;
    final IconData? icon;
    final String label;

    if (full) {
      fg = const Color(0xFF047857);
      bg = const Color(0xFFE6F8EF);
      icon = Icons.check_rounded;
      label = 'Done';
    } else if (empty) {
      fg = status.required ? const Color(0xFFB45309) : const Color(0xFF64748B);
      bg = status.required ? const Color(0xFFFFF7E6) : const Color(0xFFF1F5F9);
      icon = null;
      label = status.required ? 'Required' : 'Optional';
    } else {
      fg = const Color(0xFF4338CA);
      bg = const Color(0xFFEEF2FF);
      icon = null;
      label = '${status.completed}/${status.total}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
