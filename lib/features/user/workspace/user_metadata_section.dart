import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../models/user_model.dart';
import '../widgets/user_profile_details.dart';

/// Contact, tenure, and role-specific profile context (read-only).
class UserMetadataSection extends StatelessWidget {
  const UserMetadataSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final List<({String label, String value})> profileRows =
        UserProfileDetails.rows(user.profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        _row(AppIcons.email, 'Email', user.email.trim().isEmpty ? '—' : user.email.trim()),
        _row(AppIcons.phone, 'Phone', user.phone.trim().isEmpty ? '—' : user.phone.trim()),
        _row(AppIcons.clock, 'Joined', formatDateTime(user.createdAt)),
        if (profileRows.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          for (final ({String label, String value}) row in profileRows)
            _row(AppIcons.adminProfile, row.label, row.value),
        ],
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Icon(icon, size: 18, color: const Color(0xFF57629A)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B556A), fontWeight: FontWeight.w600),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF4B556A))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
