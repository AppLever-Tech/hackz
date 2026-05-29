import 'package:flutter/material.dart';

import '../../../core/theme/auth_theme.dart';

/// Shared centered title + subtitle for landing sections.
class LandingSectionHeader extends StatelessWidget {
  const LandingSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: AuthTheme.landingSectionTitle,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AuthTheme.sectionLeadStyle.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
