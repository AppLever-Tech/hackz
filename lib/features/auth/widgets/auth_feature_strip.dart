import 'package:flutter/material.dart';

import '../../../core/theme/auth_theme.dart';

/// Horizontal feature highlights on the sign-in screen (matches landing palette).
class AuthFeatureStrip extends StatelessWidget {
  const AuthFeatureStrip({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: AuthTheme.label, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AuthTheme.helperStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.border),
      ),
      child: Row(
        children: <Widget>[
          item(Icons.shield_outlined, 'Secure\nAccess'),
          item(Icons.groups_outlined, 'Role Based\nDashboards'),
          item(Icons.auto_awesome_outlined, 'Smart\nCollaboration'),
          item(Icons.fact_check_outlined, 'Approval\nWorkflow'),
        ],
      ),
    );
  }
}
