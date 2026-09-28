import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_helper.dart';

/// Compact header action that opens domain management from Problem Statements.
class DomainsHeaderAction extends StatelessWidget {
  const DomainsHeaderAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    if (mobile) {
      return IconButton(
        tooltip: 'Domains',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: const Icon(AppIcons.domains, size: 20),
        onPressed: onPressed,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: MobileToolbarButtonStyles.outlinedIcon(
        onPressed: onPressed,
        label: 'Domains',
        icon: AppIcons.domains,
      ),
    );
  }
}
