import 'package:flutter/material.dart';

import '../../../theme/auth_theme.dart';

/// Shared centered title + subtitle for landing sections (18px title).
abstract final class LandingSectionHeaderStyles {
  static TextStyle get title =>
      AuthTheme.sectionTitleStyle.copyWith(fontSize: 18);

  static TextStyle get subtitle =>
      AuthTheme.sectionLeadStyle.copyWith(fontSize: 13);
}

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
          style: LandingSectionHeaderStyles.title,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: LandingSectionHeaderStyles.subtitle,
        ),
      ],
    );
  }
}
