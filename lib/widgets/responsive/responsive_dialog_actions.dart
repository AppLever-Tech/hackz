import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// Dialog / form footer actions: inline on desktop, wrapped or stacked on mobile.
class ResponsiveDialogActions extends StatelessWidget {
  const ResponsiveDialogActions({
    super.key,
    required this.children,
    this.leading,
    this.stackOnMobile = true,
  });

  final List<Widget> children;
  final Widget? leading;
  final bool stackOnMobile;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty && leading == null) return const SizedBox.shrink();

    if (ResponsiveHelper.isMobile(context) && stackOnMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(height: 10),
          ],
          ...children.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _stretchAction(w),
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading!,
          if (children.isNotEmpty) const SizedBox(width: 4),
        ],
        ...children,
      ],
    );
  }

  static Widget _stretchAction(Widget child) {
    if (child is FilledButton || child is OutlinedButton || child is TextButton || child is ElevatedButton) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
