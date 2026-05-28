import 'package:flutter/material.dart';

/// Brand-filled action style aligned with [FilledButton] / “Create Team”.
abstract final class ProblemWorkflowActionStyles {
  ProblemWorkflowActionStyles._();

  static const Color brandFill = Color(0xFF6A38FF);
  static const Color brandOnFill = Colors.white;

  static ButtonStyle brandFilledButtonStyle({double minHeight = 36}) {
    return FilledButton.styleFrom(
      minimumSize: Size(0, minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: brandFill,
      foregroundColor: brandOnFill,
      disabledBackgroundColor: Color(0xFFE2E8F0),
      disabledForegroundColor: Color(0xFF94A3B8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Compact semantic workflow pill for table rows.
class ProblemWorkflowActionPill extends StatelessWidget {
  const ProblemWorkflowActionPill({
    super.key,
    required this.label,
    this.icon,
    this.contentIcon,
    this.showPlusPrefix = false,
    this.onTap,
    this.semantic = ProblemWorkflowPillSemantic.primary,
    this.enabled = true,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  /// Optional icon shown between [showPlusPrefix] and [label] (e.g. ideas).
  final IconData? contentIcon;
  final bool showPlusPrefix;
  final VoidCallback? onTap;
  final ProblemWorkflowPillSemantic semantic;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && onTap != null;
    final bool filledBrand = semantic == ProblemWorkflowPillSemantic.filledBrand;
    final _PillColors colors = _PillColors.forSemantic(semantic, enabled: interactive);

    final List<Widget> rowChildren = <Widget>[];
    if (showPlusPrefix) {
      rowChildren.add(Text(
        '+',
        style: TextStyle(
          fontSize: filledBrand ? 14 : 12,
          fontWeight: FontWeight.w800,
          color: colors.text,
          height: 1,
        ),
      ));
      rowChildren.add(SizedBox(width: filledBrand ? 4 : 3));
    }
    if (contentIcon != null) {
      rowChildren.add(Icon(contentIcon, size: filledBrand ? 16 : 14, color: colors.text));
      rowChildren.add(SizedBox(width: filledBrand ? 5 : 4));
    } else if (icon != null) {
      rowChildren.add(Icon(icon, size: filledBrand ? 16 : 14, color: colors.text));
      rowChildren.add(SizedBox(width: filledBrand ? 5 : 4));
    }
    rowChildren.add(Text(
      label,
      style: TextStyle(
        fontSize: filledBrand ? 12.5 : 12,
        fontWeight: FontWeight.w700,
        color: colors.text,
        height: 1.1,
      ),
    ));

    final Widget pill = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: interactive ? onTap : null,
        borderRadius: BorderRadius.circular(filledBrand ? 12 : 999),
        hoverColor: filledBrand
            ? Colors.white.withValues(alpha: 0.12)
            : colors.hover,
        splashColor: filledBrand ? Colors.white.withValues(alpha: 0.18) : null,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(filledBrand ? 12 : 999),
            border: filledBrand ? null : Border.all(color: colors.border),
            boxShadow: interactive && !filledBrand
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0F1E293B),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : interactive && filledBrand
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x266A38FF),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: filledBrand ? 12 : 10,
              vertical: filledBrand ? 8 : 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: rowChildren,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.trim().isEmpty) return pill;
    return Tooltip(message: tooltip, child: pill);
  }
}

enum ProblemWorkflowPillSemantic {
  primary,
  pending,
  closed,
  filledBrand,
}

class _PillColors {
  const _PillColors({
    required this.surface,
    required this.border,
    required this.text,
    required this.hover,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color hover;

  static _PillColors forSemantic(
    ProblemWorkflowPillSemantic semantic, {
    required bool enabled,
  }) {
    if (!enabled || semantic == ProblemWorkflowPillSemantic.closed) {
      return const _PillColors(
        surface: Color(0xFFF1F5F9),
        border: Color(0xFFE2E8F0),
        text: Color(0xFF64748B),
        hover: Color(0x00000000),
      );
    }
    return switch (semantic) {
      ProblemWorkflowPillSemantic.filledBrand => const _PillColors(
          surface: ProblemWorkflowActionStyles.brandFill,
          border: ProblemWorkflowActionStyles.brandFill,
          text: ProblemWorkflowActionStyles.brandOnFill,
          hover: Color(0x1AFFFFFF),
        ),
      ProblemWorkflowPillSemantic.primary => const _PillColors(
          surface: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          text: Color(0xFF1D4ED8),
          hover: Color(0x122563EB),
        ),
      ProblemWorkflowPillSemantic.pending => const _PillColors(
          surface: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          text: Color(0xFF9A3412),
          hover: Color(0x12EA580C),
        ),
      ProblemWorkflowPillSemantic.closed => const _PillColors(
          surface: Color(0xFFF1F5F9),
          border: Color(0xFFE2E8F0),
          text: Color(0xFF64748B),
          hover: Color(0x00000000),
        ),
    };
  }
}
