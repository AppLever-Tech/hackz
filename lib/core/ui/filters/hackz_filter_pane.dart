import 'package:flutter/material.dart';

import '../../responsive/mobile_filter_pane_styles.dart';
import '../../theme/app_icons.dart';
import '../common/mobile_compact_pill.dart';

/// Compact premium filter pane used under list search bars across Hackz.
class HackzFilterPane extends StatelessWidget {
  const HackzFilterPane({
    super.key,
    required this.sections,
    required this.onClearAll,
    this.onApply,
    this.clearLabel = 'Clear All',
    this.applyLabel = 'Apply',
  });

  /// Typically [HackzFilterSection] widgets. Skip omitted sections with `if`.
  final List<Widget> sections;
  final VoidCallback onClearAll;
  final VoidCallback? onApply;
  final String clearLabel;
  final String applyLabel;

  static const bool compact = true;

  @override
  Widget build(BuildContext context) {
    final double gap = MobileFilterPaneStyles.sectionGap(compact: compact);
    return MobileFilterPaneStyles.panelShell(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: gap),
            sections[i],
          ],
          if (sections.isNotEmpty) SizedBox(height: gap),
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: onClearAll,
            onApply: onApply,
            clearLabel: clearLabel,
            applyLabel: applyLabel,
          ),
        ],
      ),
    );
  }
}

/// One labeled filter row: icon + label on the left, chips or a field on the right.
class HackzFilterSection extends StatelessWidget {
  const HackzFilterSection({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });

  factory HackzFilterSection.chips({
    Key? key,
    required IconData icon,
    required String label,
    required List<Widget> chips,
  }) {
    return HackzFilterSection(
      key: key,
      icon: icon,
      label: label,
      child: HackzFilterChipGroup(children: chips),
    );
  }

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MobileFilterPaneStyles.labelValuesRow(
      icon: icon,
      label: label,
      compact: HackzFilterPane.compact,
      child: child,
    );
  }
}

/// Standard wrap spacing for chips inside a [HackzFilterSection].
class HackzFilterChipGroup extends StatelessWidget {
  const HackzFilterChipGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final double gap = MobileFilterPaneStyles.chipGap(compact: HackzFilterPane.compact);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// Compact filter / choice chips used inside [HackzFilterPane].
abstract final class HackzFilterChips {
  HackzFilterChips._();

  static Widget toggle({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    IconData? icon,
  }) {
    return HackzFilterChip(
      label: label,
      selected: selected,
      icon: icon,
      onPressed: () => onSelected(!selected),
    );
  }

  static Widget choice({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return HackzFilterChip(
      label: label,
      selected: selected,
      icon: icon,
      onPressed: onSelected,
    );
  }

  /// Removable chip for currently applied filter values.
  static Widget applied({
    required String label,
    required VoidCallback onDeleted,
    IconData? icon,
  }) {
    return HackzFilterChip.applied(
      label: label,
      icon: icon,
      onDeleted: onDeleted,
    );
  }
}

/// Wrap of applied-filter chips shown under a [HackzFilterPane].
class HackzActiveFiltersRow extends StatelessWidget {
  const HackzActiveFiltersRow({super.key, required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final double gap = MobileFilterPaneStyles.chipGap(compact: HackzFilterPane.compact);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

/// Selected state is border + fill + type — no checkmark over the icon.
class HackzFilterChip extends StatelessWidget {
  const HackzFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.onDeleted,
    this.icon,
  });

  /// Compact selected pill with a dismiss control for applied filters.
  factory HackzFilterChip.applied({
    Key? key,
    required String label,
    required VoidCallback onDeleted,
    IconData? icon,
  }) {
    return HackzFilterChip(
      key: key,
      label: label,
      selected: true,
      icon: icon,
      onDeleted: onDeleted,
    );
  }

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final IconData? icon;

  static const Duration _animDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final Color fg = selected
        ? MobileCompactPillMetrics.selectedForeground
        : MobileCompactPillMetrics.neutralForeground;
    final Color bg = selected
        ? MobileCompactPillMetrics.selectedBackground
        : MobileCompactPillMetrics.neutralBackground;
    final Color border = selected
        ? MobileCompactPillMetrics.selectedBorder
        : MobileCompactPillMetrics.neutralBorder;
    final BorderRadius radius = BorderRadius.circular(MobileCompactPillMetrics.borderRadius);
    final bool dismissible = onDeleted != null;

    final Widget chip = AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOut,
      padding: dismissible
          ? const EdgeInsets.fromLTRB(10, 5, 4, 5)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: selected ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: MobileFilterPaneStyles.chipAvatarSize, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: MobileFilterPaneStyles.compactChipFontSize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
          if (dismissible) ...<Widget>[
            const SizedBox(width: 2),
            InkWell(
              onTap: onDeleted,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(AppIcons.remove, size: 14, color: fg),
              ),
            ),
          ],
        ],
      ),
    );

    if (onPressed == null) {
      return Material(color: Colors.transparent, child: chip);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: chip,
      ),
    );
  }
}
