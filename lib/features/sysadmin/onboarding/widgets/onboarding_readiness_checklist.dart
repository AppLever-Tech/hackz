import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/organisation_onboarding_item.dart';

class OnboardingReadinessChecklist extends StatelessWidget {
  const OnboardingReadinessChecklist({super.key, required this.item});

  final OrganisationOnboardingItem item;

  @override
  Widget build(BuildContext context) {
    final List<(String, bool)> rows = <(String, bool)>[
      ('Firebase Connected', item.firebaseConnected && item.firebaseValidated),
      ('College Authorization', item.authorizationVerified),
      ('Initial Administrator', item.initialAdminConfigured),
      ('Organisation Ready', item.isActivated),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          _Row(label: rows[i].$1, done: rows[i].$2),
          if (i != rows.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color fg = done ? const Color(0xFF047857) : const Color(0xFF64748B);
    return Row(
      children: <Widget>[
        Icon(
          done ? AppIcons.workflowApproved : AppIcons.clock,
          size: 16,
          color: fg,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            done ? '$label  ✓' : label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    );
  }
}
