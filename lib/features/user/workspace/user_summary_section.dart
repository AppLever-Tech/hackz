import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/user_model.dart';
import 'user_workspace_identity_header.dart';

class UserSummarySection extends StatelessWidget {
  const UserSummarySection({
    super.key,
    required this.user,
    this.organizationName,
  });

  final UserModel user;
  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    final String dept = user.department.trim().isEmpty ? user.departmentCode.trim() : user.department.trim();
    final String org = (organizationName ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UserWorkspaceIdentityHeader(user: user),
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
