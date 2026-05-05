import 'package:flutter/material.dart';

import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../common/dashboard_page_template.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'faculty_dashboard_screen.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.faculty, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.faculty, user),
          );
        }
        return FacultyDashboardScreen(
          key: ValueKey<int>(refreshToken),
          user: user,
          refreshToken: refreshToken,
          section: selectedMenuIndex == 1
              ? FacultyDashboardSection.teams
              : FacultyDashboardSection.dashboard,
        );
      },
    );
  }
}
