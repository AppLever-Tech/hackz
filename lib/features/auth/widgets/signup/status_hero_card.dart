import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../account_workspace_visuals.dart';
import '../../../../models/enums/account_workspace_phase.dart';
import '../../../../utils/common_helpers.dart';

class StatusHeroCard extends StatelessWidget {
  const StatusHeroCard({
    super.key,
    required this.phase,
    required this.submittedAt,
    this.rejectionReason,
  });

  final AccountWorkspacePhase phase;
  final DateTime submittedAt;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final fg = AccountWorkspaceVisuals.pillForeground(phase);
    final bg = AccountWorkspaceVisuals.pillBackground(phase);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AccountWorkspaceVisuals.heroGradient(phase),
        border: Border.all(color: AccountWorkspaceVisuals.heroBorder(phase), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.55),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x28000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Icon(
              AccountWorkspaceVisuals.heroIcon(phase),
              size: 38,
              color: fg,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: fg.withOpacity(0.25)),
            ),
            child: Text(
              AccountWorkspaceVisuals.pillLabel(phase),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AccountWorkspaceVisuals.heroTitle(phase),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AccountWorkspaceVisuals.heroSubtitle(phase),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black.withOpacity(0.58),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (phase == AccountWorkspacePhase.pendingApproval) ...<Widget>[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 3,
                children: <Widget>[
                  Icon(AppIcons.info, size: 15, color: Colors.black.withOpacity(0.58)),
                  Text(
                    'You can sigin anytime to track the approval status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.black.withOpacity(0.58),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (phase == AccountWorkspacePhase.rejected &&
              (rejectionReason ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                rejectionReason!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF7F1D1D)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(AppIcons.clock, size: 16, color: Colors.black.withOpacity(0.45)),
              const SizedBox(width: 6),
              Text(
                'Submitted ${formatDateTime(submittedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.52),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
