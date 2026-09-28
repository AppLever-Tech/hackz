import 'package:flutter/material.dart';

import 'responsive_helper.dart';

/// Shared spacing, typography, and chip styling for compact mobile filter panes.
abstract final class MobileFilterPaneStyles {
  MobileFilterPaneStyles._();

  static const Color panelColor = Color(0xFFF8FAFF);
  static const double compactPanelPadding = 8;
  static const double standardPanelPadding = 12;
  static const double compactBorderRadius = 12;
  static const double standardBorderRadius = 14;
  static const double compactSectionGap = 6;
  static const double standardSectionGap = 12;
  static const double compactChipGap = 6;
  static const double standardChipGap = 8;
  static const double compactLabelFontSize = 12;
  static const double standardLabelFontSize = 14;
  static const double compactChipFontSize = 12;
  static const double standardChipFontSize = 14;
  static const double compactFooterButtonHeight = 34;
  static const double standardFooterButtonHeight = 40;
  static const double compactLabelColumnWidth = 118;
  static const double standardLabelColumnWidth = 132;
  static const double chipAvatarSize = 14;
  static const Color paneBorderColor = Color(0xFFD9E2F5);
  static const List<BoxShadow> paneShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
  ];

  static bool useCompact(BuildContext context, {bool? compact}) {
    if (compact != null) return compact;
    return ResponsiveHelper.isMobile(context);
  }

  static EdgeInsets panelPadding({required bool compact}) {
    return EdgeInsets.all(compact ? compactPanelPadding : standardPanelPadding);
  }

  static BorderRadius panelBorderRadius({required bool compact}) {
    return BorderRadius.circular(compact ? compactBorderRadius : standardBorderRadius);
  }

  static double sectionGap({required bool compact}) {
    return compact ? compactSectionGap : standardSectionGap;
  }

  static double chipGap({required bool compact}) {
    return compact ? compactChipGap : standardChipGap;
  }

  static TextStyle sectionLabel({required bool compact}) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: compact ? compactLabelFontSize : standardLabelFontSize,
    );
  }

  static TextStyle chipLabel({required bool compact}) {
    return TextStyle(fontSize: compact ? compactChipFontSize : standardChipFontSize);
  }

  /// Compact “Status  [chips…]” row used by list filter panes.
  static Widget labelValuesRow({
    required IconData icon,
    required String label,
    required bool compact,
    required Widget child,
    Color iconColor = const Color(0xFF64748B),
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: compact ? compactLabelColumnWidth : standardLabelColumnWidth,
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sectionLabel(compact: compact),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  static BoxDecoration paneDecoration({required bool compact}) {
    return BoxDecoration(
      color: panelColor,
      borderRadius: panelBorderRadius(compact: compact),
      border: Border.all(color: paneBorderColor, width: 1.2),
      boxShadow: paneShadow,
    );
  }

  static Widget panelShell({
    required bool compact,
    required Widget child,
    BoxDecoration? decoration,
  }) {
    return Container(
      width: double.infinity,
      padding: panelPadding(compact: compact),
      decoration: decoration ?? paneDecoration(compact: compact),
      child: child,
    );
  }

  static Widget filterChip({
    required bool compact,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
  }) {
    return FilterChip(
      avatar: avatar,
      label: Text(label, style: chipLabel(compact: compact)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
      padding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
    );
  }

  static Widget choiceChip({
    required bool compact,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    Widget? avatar,
  }) {
    return ChoiceChip(
      avatar: avatar,
      label: Text(label, style: chipLabel(compact: compact)),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      materialTapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
      padding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
    );
  }

  static Widget footer({
    required bool compact,
    required VoidCallback onClearAll,
    VoidCallback? onApply,
    String clearLabel = 'Clear All',
    String applyLabel = 'Apply',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
          ),
          child: Text(clearLabel, style: chipLabel(compact: compact)),
        ),
        if (onApply != null) ...<Widget>[
          SizedBox(width: compact ? 4 : 6),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              minimumSize: Size(0, compact ? compactFooterButtonHeight : standardFooterButtonHeight),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
              tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(applyLabel, style: chipLabel(compact: compact)),
          ),
        ],
      ],
    );
  }
}

/// Icon-only filter toggle shared by mobile list toolbars.
class MobileFilterToggleButton extends StatelessWidget {
  const MobileFilterToggleButton({
    super.key,
    required this.expanded,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip ?? (expanded ? 'Hide filters' : 'Filters'),
      icon: Icon(
        Icons.tune,
        size: 18,
        color: expanded ? const Color(0xFF6A38FF) : const Color(0xFF475569),
      ),
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: expanded ? const Color(0xFFE8ECFF) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: expanded ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
