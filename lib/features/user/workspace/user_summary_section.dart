import 'package:flutter/material.dart';

import '../../auth/widgets/signup/account_workspace_visuals.dart';
import '../../../core/theme/app_icons.dart';
import '../models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../services/user_role_labels.dart';
import '../widgets/user_avatar.dart';

class UserSummarySection extends StatelessWidget {
  const UserSummarySection({
    super.key,
    required this.user,
    this.organizationName,
  });

  final UserModel user;
  final String? organizationName;

  static String _roleLabel(String roleCode) => UserRoleLabels.labelForCode(roleCode);

  @override
  Widget build(BuildContext context) {
    final String name = userDisplayName(user);
    final String dept = user.department.trim().isEmpty ? user.departmentCode.trim() : user.department.trim();
    final String org = (organizationName ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            UserAvatar(user: user, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _softChip(
              icon: AppIcons.forUserRoleCode(user.role),
              label: _roleLabel(user.role),
              fg: const Color(0xFF334155),
              bg: const Color(0xFFF1F5F9),
            ),
            _softChip(
              icon: AppIcons.verification,
              label: AccountWorkspaceVisuals.userStatusDisplayLabel(user.status),
              fg: AccountWorkspaceVisuals.userStatusAccent(user.status),
              bg: AccountWorkspaceVisuals.chipBackgroundForUserStatus(user.status),
            ),
          ],
        ),
        if (dept.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _metaRow(AppIcons.departments, 'Department', dept),
        ],
        if (org.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _metaRow(AppIcons.organizations, 'Organization', org),
        ],
      ],
    );
  }

  static Widget _softChip({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  static Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: const Color(0xFF57629A)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.35),
              children: <TextSpan>[
                TextSpan(
                  text: '$label · ',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4B556A)),
                ),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
