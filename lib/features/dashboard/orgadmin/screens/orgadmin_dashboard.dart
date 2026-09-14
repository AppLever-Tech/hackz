import 'package:flutter/material.dart';

import '../../../user/models/user_model.dart';
import '../../chrome/dashboard_page_template.dart';

/// Minimal tenant shell for `orgAdmin` until Phase 2+ capabilities ship.
class OrgAdminDashboard extends StatelessWidget {
  const OrgAdminDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (BuildContext context, int refreshToken, int selectedMenuIndex) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF6A38FF)),
                  const SizedBox(height: 16),
                  const Text(
                    'Hackz Organisation Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your account is recognised as a Hackz Organisation Admin. '
                    'Tenant operations for this role will be enabled after provisioning is complete.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
