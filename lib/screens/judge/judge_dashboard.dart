import 'package:flutter/material.dart';

import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../common/dashboard_page_template.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import '../common/role_dashboard_data_view.dart';

class JudgeDashboard extends StatelessWidget {
  const JudgeDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.judge, user),
          );
        }
        if (selectedMenuIndex == 2) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.judge, user),
          );
        }
        return Center(
          child: RoleDashboardDataView(
            user: user,
            refreshToken: refreshToken,
          ),
        );
      },
    );
  }
}
