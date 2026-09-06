import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../utils/common_helpers.dart';

class ProvisioningAuthorizationPanel extends StatelessWidget {
  const ProvisioningAuthorizationPanel({
    super.key,
    required this.status,
    this.lastValidatedAt,
    this.onValidateAgain,
  });

  final ProvisioningAuthorizationStatus status;
  final DateTime? lastValidatedAt;
  final VoidCallback? onValidateAgain;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, Color border) = switch (status) {
      ProvisioningAuthorizationStatus.verified => (
          const Color(0xFF047857),
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
        ),
      ProvisioningAuthorizationStatus.revoked => (
          const Color(0xFFB91C1C),
          const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
        ),
      ProvisioningAuthorizationStatus.required ||
      ProvisioningAuthorizationStatus.pending => (
          const Color(0xFFC2410C),
          const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                status.isAuthorized
                    ? AppIcons.workflowApproved
                    : status.isRevoked
                        ? AppIcons.lock
                        : AppIcons.clock,
                size: 16,
                color: fg,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Provisioning Authorization',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
              ),
              Text(
                status.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.lifecycleMessage,
            style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: fg),
          ),
          if (lastValidatedAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Last validated ${formatDateTime(lastValidatedAt!.toLocal())}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
          if (onValidateAgain != null) ...<Widget>[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onValidateAgain,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Validate Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
