import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';

class SupportHelpCard extends StatelessWidget {
  const SupportHelpCard({
    super.key,
    this.departmentHint,
    this.coordinatorHint,
  });

  /// Optional org-specific line (e.g. department name).
  final String? departmentHint;
  final String? coordinatorHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(AppIcons.helpSupport, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text(
              'Support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _line(
          AppIcons.departments,
          'Department administrator',
          'They review new accounts for your college or department.',
        ),
        if ((departmentHint ?? '').trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'Related area: ${departmentHint!.trim()}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 12),
        _line(
          AppIcons.coordinator,
          'Coordinator',
          (coordinatorHint ?? '').trim().isEmpty
              ? 'Your organization may assign a coordinator for onboarding help.'
              : coordinatorHint!.trim(),
        ),
        const SizedBox(height: 12),
        _line(
          AppIcons.email,
          'Email & phone',
          'Use the contact details you provided if your admin reaches out.',
        ),
      ],
    );
  }

  Widget _line(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
