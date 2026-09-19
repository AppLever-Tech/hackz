import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../../../../features/payment/screens/per_idea_payment_verification_screen.dart';
import '../../../../features/imports/imports.dart';
import '../../../../utils/firestore_utils.dart';
import '../org_admin_primary_menu.dart';
import '../services/org_admin_dashboard_service.dart';
import '../widgets/org_admin_dashboard_header.dart';
import '../widgets/org_admin_operational_snapshot.dart';
import '../widgets/org_admin_payment_approvals_card.dart';
import '../widgets/org_admin_quick_actions_section.dart';
import '../widgets/org_admin_tenant_readiness_card.dart';
import '../../chrome/dashboard_chrome_scope.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../../../features/analysis/screens/ai_analysis_providers_screen.dart';
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
          case 6:
            return AiAnalysisProvidersScreen(
              key: ValueKey<int>(refreshToken),
              user: user,
              readOnly: true,
            );
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
  late Future<OrgAdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
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
      _future = OrgAdminDashboardService.load(widget.user.orgId);
    });
  }

  void _navigateToModule(int index) {
    DashboardChromeScope.maybeOf(context)?.selectPrimaryMenu(index);
  }

  String _displayName() {
    final String name = widget.user.displayName.trim();
    return name.isEmpty ? 'Organisation Admin' : name;
  }

  String _organisationName(OrgAdminDashboardData data) {
    final String fromTenant = data.readiness.organizationName.trim();
    if (fromTenant.isNotEmpty) return fromTenant;
    final String fromUser = widget.user.organisationName.trim();
    if (fromUser.isNotEmpty) return fromUser;
    return widget.user.orgId.trim();
  }

  Future<void> _openImportTeams() async {
    if (!ImportPlatformSupport.isSupported(context)) {
      FeedbackService.showInfo(
        context,
        title: 'Use a larger screen',
        message: 'Team import is available on tablet and desktop.',
      );
      return;
    }
    final org = await FirestoreUtils.fetchOrganization(widget.user.orgId);
    final String fetched = (org?.name ?? '').trim();
    final String orgName = fetched.isNotEmpty ? fetched : widget.user.orgId.trim();
    if (!mounted) return;
    final bool? imported = await showTeamRegistrationImportWorkflow(
      context: context,
      actor: widget.user,
      orgName: orgName.isEmpty ? widget.user.orgId : orgName,
    );
    if (imported == true && mounted) _reload();
  }

  Future<void> _openImportProblems() async {
    if (!ImportPlatformSupport.isSupported(context)) {
      FeedbackService.showInfo(
        context,
        title: 'Use a larger screen',
        message: 'Problem import is available on tablet and desktop.',
      );
      return;
    }
    final bool? imported = await showProblemsImportWorkflow(
      context: context,
      actorUserId: widget.user.userId,
      orgId: widget.user.orgId,
      defaultDepartmentName: widget.user.department.trim(),
      defaultDepartmentCode: widget.user.departmentCode,
      orgType: widget.user.orgType?.name ?? 'college',
      lockDepartment: false,
    );
    if (imported == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final double gap = ResponsiveHelper.dashboardSectionGap(context);
    return FutureBuilder<OrgAdminDashboardData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<OrgAdminDashboardData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load dashboard: ${snapshot.error}');
        }
        final OrgAdminDashboardData data = snapshot.data!;
        final readiness = data.readiness;
        final bool showPayments = OrgAdminDashboardService.showPaymentApprovals(readiness.commercialPlan);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OrgAdminDashboardHeader(
                displayName: _displayName(),
                organisationName: _organisationName(data),
                commercialPlan: readiness.commercialPlan,
                organisationAccessGranted: readiness.organisationAccessGranted,
              ),
              SizedBox(height: gap),
              if (showPayments) ...<Widget>[
                OrgAdminPaymentApprovalsCard(
                  counts: data.paymentCounts,
                  onReviewPayments: () => _navigateToModule(OrgAdminPrimaryMenu.paymentVerification),
                ),
                SizedBox(height: gap),
              ],
              OrgAdminOperationalSnapshot(
                counts: readiness.counts,
                onNavigateToModule: _navigateToModule,
              ),
              SizedBox(height: gap),
              OrgAdminQuickActionsSection(
                actions: OrgAdminQuickActionsSection.buildActions(
                  plan: readiness.commercialPlan,
                  onImportTeams: _openImportTeams,
                  onImportProblems: _openImportProblems,
                  onCreateEvent: () => _navigateToModule(OrgAdminPrimaryMenu.events),
                  onReviewPayments: () => _navigateToModule(OrgAdminPrimaryMenu.paymentVerification),
                ),
              ),
              SizedBox(height: gap),
              OrgAdminTenantReadinessCard(
                readiness: readiness,
                onRefresh: _reload,
                onNavigateToModule: _navigateToModule,
              ),
            ],
          ),
        );
      },
    );
  }
}
