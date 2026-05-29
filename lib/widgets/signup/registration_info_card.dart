import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../features/user/models/enums/user_role.dart';
import '../../features/user/models/user_model.dart';

class RegistrationInfoCard extends StatelessWidget {
  const RegistrationInfoCard({
    super.key,
    required this.user,
    required this.collegeName,
  });

  final UserModel user;
  final String collegeName;

  @override
  Widget build(BuildContext context) {
    final name = '${user.firstName} ${user.lastName}'.trim().isEmpty ? '—' : '${user.firstName} ${user.lastName}'.trim();
    final role = UserRole.fromCode(user.role);
    final roleLabel = switch (role) {
      UserRole.student => 'Student',
      UserRole.faculty => 'Faculty',
      UserRole.departmentAdmin => 'Department admin',
      UserRole.collegeAdmin => 'College admin',
      UserRole.judge => 'Judge',
      UserRole.coordinator => 'Coordinator',
      UserRole.sysAdmin => 'System admin',
    };
    final dept = user.department.trim().isEmpty ? user.departmentCode : user.department;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Registration details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _row(AppIcons.adminProfile, 'Name', name),
        _row(AppIcons.forUserRole(role), 'Role', roleLabel),
        _row(AppIcons.departments, 'Department', dept.trim().isEmpty ? '—' : dept),
        _row(AppIcons.organizations, 'College', collegeName.trim().isEmpty ? '—' : collegeName),
        _row(AppIcons.email, 'Email', user.email.trim().isEmpty ? '—' : user.email),
        _row(AppIcons.phone, 'Phone', user.phone.trim().isEmpty ? '—' : user.phone),
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
            width: 100,
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
