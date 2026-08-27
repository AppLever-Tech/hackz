import 'package:flutter/material.dart';
import 'package:hackz/core/responsive/mobile_toolbar_button_styles.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/card_overflow_menu.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_chrome_scope.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_components.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_session_scope.dart';
import 'package:hackz/features/events/models/event_details_module.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/screens/event_details_shell.dart';
import 'package:hackz/features/events/widgets/event_meta_chip.dart';
import 'package:hackz/features/ideathons/screens/create_ideathon_workspace.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_ideas_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_judge_assignments_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_leaderboard_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_lifecycle_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_overview_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_payments_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_reports_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_results_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_winners_tab.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_payment_service.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_status_pill.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_type_pill.dart';
import 'package:hackz/features/user/models/enums/user_role.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/features/user/services/role_visibility_helpers.dart';
import 'package:hackz/utils/common_helpers.dart';

/// Opens Ideathon Details in the dashboard main panel (not the right-side workspace).
void showIdeathonDetailsPane(
  BuildContext context, {
  required String ideathonId,
  required UserModel actor,
  String backTooltip = 'Back to Ideathons',
}) {
  WorkspaceController.instance.close();
  final chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    IdeathonDetailsPane(
      key: ValueKey<String>(ideathonId),
      ideathonId: ideathonId,
      actor: actor,
      onBack: chrome.clearOverlay,
      backTooltip: backTooltip,
    ),
  );
}

class IdeathonDetailsPane extends StatefulWidget {
  const IdeathonDetailsPane({
    super.key,
    required this.ideathonId,
    required this.actor,
    required this.onBack,
    this.backTooltip = 'Back to Ideathons',
  });

  final String ideathonId;
  final UserModel actor;
  final VoidCallback onBack;
  final String backTooltip;

  @override
  State<IdeathonDetailsPane> createState() => _IdeathonDetailsPaneState();
}

class _IdeathonDetailsPaneState extends State<IdeathonDetailsPane> {
  late Future<IdeathonDetailsViewModel> _future;
  late Future<IdeathonPaymentWorkspaceViewModel> _paymentsFuture;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _future = IdeathonDetailsLoader.load(widget.ideathonId);
    _paymentsFuture = IdeathonPaymentService.load(widget.ideathonId);
  }

  void _reload() {
    setState(() {
      _future = IdeathonDetailsLoader.load(widget.ideathonId);
      _paymentsFuture = IdeathonPaymentService.load(widget.ideathonId);
    });
  }

  bool get _canEdit => RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(widget.actor.role));

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<IdeathonDetailsViewModel>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<IdeathonDetailsViewModel> snapshot) {
          final String title = snapshot.data?.ideathon.name.trim() ?? '';
          final Widget header = DashboardPageHeader(
            title: title.isEmpty ? EventKind.ideathon.label : title,
            titleIcon: AppIcons.ideathons,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId),
            onRefresh: _reload,
            helpPageId: EventKind.ideathon.helpPageId,
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: widget.backTooltip,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          );

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                const Expanded(child: Center(child: HkzProgressIndicator(size: 36))),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(AppIcons.ideathons, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.hasError ? 'Unable to load: ${snapshot.error}' : 'Ideathon not found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(onPressed: _reload, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final IdeathonDetailsViewModel vm = snapshot.data!;
          final event = vm.ideathon;
          final DateTime start = event.startDateTime.toLocal();
          final DateTime end = event.endDateTime.toLocal();
          final bool sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
          final String dateLabel = sameDay
              ? formatShortDate(start)
              : '${formatShortDate(start)} – ${formatShortDate(end)}';
          final String timeLabel = '${formatShortTime(start)} – ${formatShortTime(end)}';
          final String org = vm.organisationName.trim().isEmpty ? event.orgId : vm.organisationName.trim();
          final bool evaluationLocked = vm.workspace.evaluationStarted;

          if (_editing && _canEdit) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => setState(() => _editing = false),
                        icon: const Icon(AppIcons.back),
                        tooltip: 'Back to details',
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('Edit Ideathon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: CreateIdeathonWorkspace(
                    user: widget.actor,
                    initialEvent: event,
                    onCreated: (_) {
                      setState(() => _editing = false);
                      _reload();
                    },
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 8),
              Expanded(
                child: EventDetailsShell(
                  headerActions: _canEdit
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () => setState(() => _editing = true),
                              icon: Icon(evaluationLocked ? AppIcons.lock : AppIcons.edit, size: 16),
                              label: const Text('Edit'),
                              style: MobileToolbarButtonStyles.filled(compact: true),
                            ),
                            const SizedBox(width: 6),
                            CardOverflowMenuButton(
                              tooltip: 'Ideathon actions',
                              onSelected: (String value) {
                                switch (value) {
                                  case 'assignments':
                                    WorkspaceNavigator.openIdeathonJudgeAssignment(
                                      context,
                                      event.ideathonId,
                                      actor: widget.actor,
                                    );
                                  case 'template':
                                    if (event.evaluationTemplateId.trim().isNotEmpty) {
                                      WorkspaceNavigator.openEvaluationTemplate(
                                        context,
                                        event.evaluationTemplateId,
                                      );
                                    }
                                }
                              },
                              actions: <CardOverflowMenuAction>[
                                const CardOverflowMenuAction(
                                  value: 'assignments',
                                  icon: AppIcons.judges,
                                  label: 'Manage Judge Assignments',
                                ),
                                CardOverflowMenuAction(
                                  value: 'template',
                                  icon: AppIcons.scoring,
                                  label: 'Evaluation template',
                                  enabled: event.evaluationTemplateId.trim().isNotEmpty,
                                ),
                              ],
                            ),
                          ],
                        )
                      : null,
                  headerPills: <Widget>[
                    IdeathonStatusPill(status: event.status, compact: false),
                    EventMetaChip(icon: AppIcons.event, label: dateLabel, color: const Color(0xFF0369A1)),
                    EventMetaChip(icon: AppIcons.clock, label: timeLabel, color: const Color(0xFF0369A1)),
                    IdeathonTypePill(type: event.ideathonType, compact: false),
                    if (org.isNotEmpty)
                      EventMetaChip(icon: AppIcons.organizations, label: org, color: const Color(0xFF0F766E)),
                    EventMetaChip(
                      icon: AppIcons.ideas,
                      label: '${vm.ideas.length} idea${vm.ideas.length == 1 ? '' : 's'}',
                      color: const Color(0xFF4F46E5),
                    ),
                  ],
                  modules: <EventDetailsModule>[
                    EventDetailsModule(id: 'overview', label: 'Overview', child: IdeathonOverviewTab(vm: vm)),
                    EventDetailsModule(
                      id: 'ideas',
                      label: EventKind.ideathon.entriesLabel,
                      count: vm.ideas.isEmpty ? null : vm.ideas.length,
                      child: IdeathonIdeasTab(vm: vm),
                    ),
                    EventDetailsModule(
                      id: 'assignments',
                      label: 'Judge Assignments',
                      count: vm.workspace.assignmentCount == 0 ? null : vm.workspace.assignmentCount,
                      child: IdeathonJudgeAssignmentsTab(
                        ideathonId: event.ideathonId,
                        actor: widget.actor,
                      ),
                    ),
                    EventDetailsModule(
                      id: 'results',
                      label: 'Evaluation Results',
                      child: IdeathonResultsTab(event: event, actor: widget.actor),
                    ),
                    EventDetailsModule(
                      id: 'leaderboard',
                      label: 'Leaderboard',
                      child: IdeathonLeaderboardTab(vm: vm, actor: widget.actor),
                    ),
                    EventDetailsModule(
                      id: 'payments',
                      label: 'Payments',
                      child: IdeathonPaymentsTab(
                        ideathonId: event.ideathonId,
                        actor: widget.actor,
                        loadFuture: _paymentsFuture,
                      ),
                    ),
                    EventDetailsModule(
                      id: 'lifecycle',
                      label: 'Lifecycle',
                      child: IdeathonLifecycleTab(vm: vm),
                    ),
                    EventDetailsModule(
                      id: 'winners',
                      label: 'Winners',
                      child: IdeathonWinnersTab(vm: vm, actor: widget.actor),
                    ),
                    EventDetailsModule(
                      id: 'reports',
                      label: 'Reports',
                      child: IdeathonReportsTab(vm: vm, actor: widget.actor),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
