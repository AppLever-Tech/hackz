import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/firebase/hackz_provisioning_identity.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../utils/common_helpers.dart';
import '../services/tenant_workspace_validator.dart';
import 'workspace_check_row.dart';

class CollegeAuthorizationPanel extends StatelessWidget {
  const CollegeAuthorizationPanel({
    super.key,
    required this.projectId,
    required this.identity,
    required this.status,
    this.lastValidatedAt,
    required this.checks,
    required this.checksRan,
  });

  final String projectId;
  final HackzProvisioningIdentity identity;
  final ProvisioningAuthorizationStatus status;
  final DateTime? lastValidatedAt;
  final List<TenantWorkspaceCheck> checks;
  final bool checksRan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'College controls the authorization.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4C1D95)),
              ),
              SizedBox(height: 8),
              Text(
                'Hackz needs limited access to this Firebase project only for Hackz tenant provisioning, such as creating the initial College Administrator.',
                style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'The Firebase project remains owned by the college. Hackz does not take ownership of the project, does not require Storage permission, and does not collect Google credentials or service-account keys. Normal Hackz business operations continue directly against the college Firebase project. The college can revoke the provisioning permission at any time through Google Cloud IAM.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 14),
        _MetaRow(label: 'Firebase project', value: projectId),
        const SizedBox(height: 8),
        _MetaRow(
          label: 'Hackz provisioning identity',
          value: identity.serviceAccountEmail,
          copyable: true,
        ),
        const SizedBox(height: 12),
        const Text(
          'Minimum IAM roles (do not grant Owner, Editor, or Storage)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < identity.iamRoles.length; i++) ...<Widget>[
          _RoleCard(role: identity.iamRoles[i]),
          if (i != identity.iamRoles.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: _StatusChip(status: status),
        ),
        const SizedBox(height: 8),
        Text(
          status.lifecycleMessage,
          style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        if (lastValidatedAt != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'Last validated ${formatDateTime(lastValidatedAt!.toLocal())}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
        const SizedBox(height: 12),
        for (int i = 0; i < checks.length; i++) ...<Widget>[
          WorkspaceCheckRow(check: checks[i], pending: !checksRan),
          if (i != checks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ProvisioningAuthorizationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (status) {
      ProvisioningAuthorizationStatus.verified => (const Color(0xFF047857), const Color(0xFFECFDF5)),
      ProvisioningAuthorizationStatus.revoked => (const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
      ProvisioningAuthorizationStatus.pending ||
      ProvisioningAuthorizationStatus.required => (const Color(0xFFC2410C), const Color(0xFFFFF7ED)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          if (copyable) _CopyIcon(value: value),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role});

  final ProvisioningIamRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  role.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  role.role,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95)),
                ),
                const SizedBox(height: 4),
                Text(
                  role.reason,
                  style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          _CopyIcon(value: role.role),
        ],
      ),
    );
  }
}

class _CopyIcon extends StatefulWidget {
  const _CopyIcon({required this.value});

  final String value;

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final String value = widget.value.trim();
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _copied ? 'Copied' : 'Copy',
      onPressed: _copy,
      icon: Icon(
        _copied ? AppIcons.copied : AppIcons.copy,
        size: 18,
        color: _copied ? const Color(0xFF047857) : const Color(0xFF64748B),
      ),
    );
  }
}
