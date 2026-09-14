import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../../../../features/payment/screens/per_idea_payment_verification_screen.dart';
import '../services/tenant_setup_readiness_service.dart';
import '../widgets/tenant_setup_readiness_panel.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../chrome/dashboard_components.dart';
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

class _OrgAdminOverview extends StatefulWidget {
  const _OrgAdminOverview({required this.user, required this.refreshToken});

  final UserModel user;
  final int refreshToken;

  @override
  State<_OrgAdminOverview> createState() => _OrgAdminOverviewState();
}

class _OrgAdminOverviewState extends State<_OrgAdminOverview> {
  late Future<TenantSetupReadiness> _readinessFuture;

  @override
  void initState() {
    super.initState();
    _readinessFuture = TenantSetupReadinessService.load(widget.user.orgId);
  }

  @override
  void didUpdateWidget(covariant _OrgAdminOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _readinessFuture = TenantSetupReadinessService.load(widget.user.orgId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String orgLabel = widget.user.organisationName.trim().isEmpty
        ? (widget.user.orgId.trim().isEmpty ? 'Hackz Organisation Admin' : widget.user.orgId.trim())
        : widget.user.organisationName.trim();
    final double gap = ResponsiveHelper.dashboardSectionGap(context);

    return FutureBuilder<TenantSetupReadiness>(
      future: _readinessFuture,
      builder: (BuildContext context, AsyncSnapshot<TenantSetupReadiness> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load setup status: ${snapshot.error}');
        }
        final TenantSetupReadiness readiness = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionContainer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.support_agent_rounded, size: 40, color: Color(0xFF6A38FF)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            orgLabel,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Initial tenant setup uses the same modules as day-to-day operations: '
                            'departments, problems, teams, events, then PER_IDEA payment verification when applicable.',
                            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              TenantSetupReadinessPanel(readiness: readiness, onRefresh: _reload),
            ],
          ),
        );
      },
    );
  }
}
