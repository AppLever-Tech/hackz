import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/enums/user_role.dart';
import '../../../utils/common_helpers.dart';
import '../widgets/user_profile_details.dart';
import 'user_workspace_loader.dart';

/// Contact, tenure, and role-specific context (read-only).
class UserMetadataSection extends StatelessWidget {
  const UserMetadataSection({super.key, required this.vm});

  final UserWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final user = vm.user;
    final List<String> roleNotes = <String>[];
    final List<({String label, String value})> profileRows =
        UserProfileDetails.rows(user.profile);

    switch (UserRole.fromCode(user.role)) {
      case UserRole.faculty:
        if (vm.teamLinksCount > 0) {
          roleNotes.add('Mentor scope · linked to ${vm.teamLinksCount} team${vm.teamLinksCount == 1 ? '' : 's'} in this organization.');
        } else {
          roleNotes.add('Faculty profile · no team mentor links recorded in this organization.');
        }
        break;
      case UserRole.judge:
        if (vm.evaluationCount > 0) {
          roleNotes.add('Judge activity · ${vm.evaluationCount} evaluation record${vm.evaluationCount == 1 ? '' : 's'} in this organization.');
        } else {
          roleNotes.add('Judge profile · no evaluation records in this organization yet.');
        }
        break;
      case UserRole.coordinator:
        roleNotes.add('Coordinator · helps run department workflows and approvals when assigned.');
        break;
      default:
        break;
    }

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
        if (user.approvedAt != null) _row(AppIcons.verification, 'Approval', formatDateTime(user.approvedAt!)),
        if (user.approvedBy != null && user.approvedBy!.trim().isNotEmpty)
          _row(AppIcons.adminProfile, 'Approved by user ID', user.approvedBy!.trim()),
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
        for (final String note in roleNotes) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569), fontWeight: FontWeight.w600),
          ),
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
