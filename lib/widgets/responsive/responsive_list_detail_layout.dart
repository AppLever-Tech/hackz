import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// List + optional detail: side-by-side on desktop, full-screen detail on mobile/tablet.
class ResponsiveListDetailLayout extends StatelessWidget {
  const ResponsiveListDetailLayout({
    super.key,
    required this.hasSelection,
    required this.list,
    required this.detail,
    required this.onCloseDetail,
    this.backLabel,
    this.listFlex = 5,
    this.detailFlex = 6,
    this.showDivider = true,
  });

  final bool hasSelection;
  final Widget list;
  final Widget detail;
  final VoidCallback onCloseDetail;
  final String? backLabel;
  final int listFlex;
  final int detailFlex;
  final bool showDivider;

  bool _useSplit(BuildContext context) =>
      hasSelection && ResponsiveHelper.useDashboardMultiColumn(context);

  @override
  Widget build(BuildContext context) {
    if (!hasSelection) {
      return list;
    }

    if (!_useSplit(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResponsiveDetailBackButton(onPressed: onCloseDetail, label: backLabel),
          Expanded(child: detail),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: listFlex, child: list),
        if (showDivider) const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        Expanded(flex: detailFlex, child: detail),
      ],
    );
  }
}

/// Compact back control for embedded detail panes on mobile.
class ResponsiveDetailBackButton extends StatelessWidget {
  const ResponsiveDetailBackButton({
    super.key,
    required this.onPressed,
    this.label,
  });

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final showLabel = label != null && label!.trim().isNotEmpty && !ResponsiveHelper.isMobile(context);
    if (showLabel) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: Text(label!),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        tooltip: label ?? 'Back',
      ),
    );
  }
}
