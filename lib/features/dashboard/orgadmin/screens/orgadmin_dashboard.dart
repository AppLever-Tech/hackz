import 'package:flutter/material.dart';

import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../../../../features/payment/screens/per_idea_payment_verification_screen.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../collegeadmin/screens/manage_college_screen.dart';

/// Hackz org admin tenant operations — reuses existing tenant modules.
class OrgAdminDashboard extends StatelessWidget {
  const OrgAdminDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.orgAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: Hackz Organisation Admin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        switch (selectedMenuIndex) {
          case 1:
            return ManageCollegeScreen(key: ValueKey<int>(refreshToken), user: user);
          case 2:
            return ProblemStatementsTableScreen(
              key: ValueKey<int>(refreshToken),
              currentUser: user,
              config: ProblemRoleConfig.configFor(UserRole.orgAdmin, user),
            );
          case 3:
            return IdeasListScreen(
              key: ValueKey<int>(refreshToken),
              currentUser: user,
              config: IdeaRoleConfig.configFor(UserRole.orgAdmin, user),
            );
          case 4:
            return IdeathonsListScreen(key: ValueKey<int>(refreshToken), user: user);
          case 5:
            return PerIdeaPaymentVerificationScreen(key: ValueKey<int>(refreshToken), user: user);
          default:
            return _OrgAdminOverview(user: user, refreshToken: refreshToken);
        }
      },
    );
  }
}

class _OrgAdminOverview extends StatelessWidget {
  const _OrgAdminOverview({required this.user, required this.refreshToken});

  final UserModel user;
  final int refreshToken;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF6A38FF)),
              const SizedBox(height: 16),
              Text(
                user.organisationName.trim().isEmpty ? 'Hackz Organisation Admin' : user.organisationName.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Text(
                'Use the navigation to monitor departments, problems, ideas, events, and verify '
                'PER_IDEA payments for this organisation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
