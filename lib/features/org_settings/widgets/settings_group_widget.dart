import 'package:flutter/material.dart';

import '../../../features/dashboard/chrome/dashboard_components.dart';

class SettingsGroupWidget extends StatelessWidget {
  const SettingsGroupWidget({
    super.key,
    required this.title,
    required this.children,
    this.showBorderTitle = true,
  });

  final String title;
  final List<Widget> children;
  final bool showBorderTitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: showBorderTitle ? 7 : 0),
          decoration: kDashboardCardDecoration.copyWith(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, showBorderTitle ? 18 : 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (showBorderTitle)
          Positioned(
            top: 0,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD9E2F5), width: 1.1),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
