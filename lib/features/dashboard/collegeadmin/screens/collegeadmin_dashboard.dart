import 'package:flutter/material.dart';

import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/org_settings/collegeadmin/org_settings_dashboard.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/analysis/screens/ai_analysis_providers_screen.dart';
import '../widgets/college_admin_overview.dart';
import 'manage_college_screen.dart';

class CollegeAdminDashboard extends StatelessWidget {
  const CollegeAdminDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.collegeAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: CollegeAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ManageCollegeScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemStatementsTableScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.collegeAdmin, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.collegeAdmin, user),
          );
        }
        if (selectedMenuIndex == 4) {
          return IdeathonsListScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 5) {
          return OrgSettingsDashboard(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 6) {
          return AiAnalysisProvidersScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return CollegeAdminOverview(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}
