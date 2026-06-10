import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../account_workspace_visuals.dart';
import '../../../../models/enums/account_workspace_phase.dart';
import 'platform_preview_section.dart';

class WhatHappensNextCard extends StatelessWidget {
  const WhatHappensNextCard({
    super.key,
    required this.phase,
  });

  final AccountWorkspacePhase phase;

  @override
  Widget build(BuildContext context) {
    final bullets = AccountWorkspaceVisuals.whatHappensNextBullets(phase);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'What happens next',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...bullets.map(
          (String line) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(AppIcons.onboardingNext, size: 18, color: const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(AppIcons.onboardingNext, size: 18, color: const Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Flexible(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: <Widget>[
                  const Text(
                    'A quick look at your workspace after activation',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
                  ),
                  Tooltip(
                    message: 'Open workspace preview',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showWorkspacePreviewDialog(context),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(AppIcons.preview, size: 17, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showWorkspacePreviewDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF8FAFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: const PlatformPreviewSection(),
              ),
            ),
          ),
        );
      },
    );
  }
}
