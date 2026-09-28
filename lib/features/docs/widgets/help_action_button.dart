import 'package:flutter/material.dart';

import '../services/help_navigation.dart';

/// Compact contextual Help (?) action for AppBars and workspace headers.
class HelpActionButton extends StatelessWidget {
  const HelpActionButton({
    super.key,
    this.pageId,
    this.contextKey,
    this.iconSize = 20,
  }) : assert(pageId != null || contextKey != null);

  final String? pageId;
  final String? contextKey;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Icons.help_outline_rounded, size: iconSize),
      onPressed: () {
        if (pageId != null) {
          HelpNavigation.open(context, pageId: pageId);
        } else {
          HelpNavigation.openForContext(context, contextKey: contextKey!);
        }
      },
    );
  }
}
