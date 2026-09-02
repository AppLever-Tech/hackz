import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/card_overflow_menu.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_chrome_scope.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_components.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_session_scope.dart';
import 'package:hackz/features/events/models/event_details_module.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/models/event_lifecycle.dart';
import 'package:hackz/features/events/screens/event_details_shell.dart';
import 'package:hackz/features/events/widgets/event_meta_chip.dart';
import 'package:hackz/features/ideathons/screens/create_ideathon_workspace.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_evaluation_template_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_ideas_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_judge_assignments_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_leaderboard_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_overview_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_payments_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_reports_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_results_tab.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_winners_tab.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/events/models/event_payment_entry.dart';
import 'package:hackz/features/events/services/event_payments_service.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
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
  late Future<EventPaymentsViewModel> _paymentsFuture;
  bool _editing = false;
  String _moduleId = 'overview';

  @override
  void initState() {
    super.initState();
    _future = IdeathonDetailsLoader.load(widget.ideathonId);
    _paymentsFuture = EventPaymentsService.load(
      kind: EventKind.ideathon,
      eventId: widget.ideathonId,
    );
  }

  void _reload() {
    setState(() {
      _future = IdeathonDetailsLoader.load(widget.ideathonId);
      _paymentsFuture = EventPaymentsService.load(
        kind: EventKind.ideathon,
        eventId: widget.ideathonId,
      );
    });
  }

  bool get _canEdit => RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(widget.actor.role));

  EventDetailsCommand _commandFor(IdeathonDetailsViewModel vm) {
    final EventLifecycleProgress progress = vm.workspace.lifecycleProgress;
    final EventPrimaryActionKind kind = EventLifecycle.primaryAction(
      progress,
      canManageOutcome: _canEdit,
    );
    switch (kind) {
      case EventPrimaryActionKind.completeEvent:
        return EventDetailsCommand(
          label: 'Complete Event',
          icon: AppIcons.workflowApproved,
          onPressed: () => _completeEvent(vm),
        );
      case EventPrimaryActionKind.selectWinners:
        return const EventDetailsCommand(
          label: 'Select Winners',
          icon: AppIcons.star,
          destinationId: 'winners',
        );
      case EventPrimaryActionKind.reviewResults:
        return EventDetailsCommand(
          label: 'Review Results',
          icon: AppIcons.results,
          destinationId: 'results',
          onPressed: _canEdit ? () => _reviewResults(vm) : null,
        );
      case EventPrimaryActionKind.viewResults:
        return const EventDetailsCommand(
          label: 'View Results',
          icon: AppIcons.results,
          destinationId: 'results',
        );
      case EventPrimaryActionKind.viewWinners:
        return const EventDetailsCommand(
          label: 'View Winners',
          icon: AppIcons.star,
          destinationId: 'winners',
        );
      case EventPrimaryActionKind.evaluationInProgress:
        return const EventDetailsCommand(
          label: 'Evaluation in Progress',
          icon: AppIcons.scoring,
          enabled: false,
        );
      case EventPrimaryActionKind.manageAssignments:
        return const EventDetailsCommand(
          label: 'Manage Assignments',
          icon: AppIcons.judges,
          destinationId: 'assignments',
        );
    }
  }

  Future<void> _reviewResults(IdeathonDetailsViewModel vm) async {
    try {
      await IdeathonService.markResultsReviewed(
        actor: widget.actor,
        ideathonId: vm.ideathon.ideathonId,
      );
      if (!mounted) return;
      setState(() => _moduleId = 'results');
      _reload();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to review results', message: '$e');
    }
  }

  Future<void> _completeEvent(IdeathonDetailsViewModel vm) async {
    final int pending = vm.workspace.pendingEvaluationCount;
    final String pendingLine = pending > 0
        ? '$pending evaluation${pending == 1 ? '' : 's'} are still pending. '
        : '';
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Complete event?',
      message:
          '${pendingLine}Completing locks evaluation configuration, judge assignments, the template, scores, results, and winner selection. Reports and results stay available.',
      confirmLabel: 'Complete Event',
      dangerConfirm: pending > 0,
    );
    if (!ok) return;
    try {
      await IdeathonService.completeEvent(
        actor: widget.actor,
        ideathonId: vm.ideathon.ideathonId,
      );
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Event completed',
        message: 'This Ideathon is read-only. Results and reports remain available.',
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to complete event', message: '$e');
    }
  }

  List<Widget> _statusPills(IdeathonDetailsViewModel vm) {
    final EventLifecycleProgress progress = vm.workspace.lifecycleProgress;
    return <Widget>[
      IdeathonStatusPill(status: vm.ideathon.status, compact: false),
      if (progress.pendingEvaluationCount > 0 && !progress.completed)
        EventMetaChip(
          icon: AppIcons.clock,
          label: '${progress.pendingEvaluationCount} pending',
          color: const Color(0xFFEA580C),
        )
      else if (progress.resultsReady && !progress.completed)
        const EventMetaChip(
          icon: AppIcons.results,
          label: 'Results ready',
          color: Color(0xFF059669),
        ),
      if (progress.winnersSelected && !progress.completed)
        const EventMetaChip(
          icon: AppIcons.star,
          label: 'Winners selected',
          color: Color(0xFFB45309),
        ),
      if (progress.completed)
        const EventMetaChip(
          icon: AppIcons.lock,
          label: 'Read-only',
          color: Color(0xFF047857),
        ),
    ];
  }

  List<Widget> _contextPills(IdeathonDetailsViewModel vm, String selectedId) {
    final event = vm.ideathon;
    final DateTime start = event.startDateTime.toLocal();
    final DateTime end = event.endDateTime.toLocal();
    final bool sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    final String dateLabel = sameDay
        ? formatShortDate(start)
        : '${formatShortDate(start)} – ${formatShortDate(end)}';
    final String timeLabel = '${formatShortTime(start)} – ${formatShortTime(end)}';
    final String org = vm.organisationName.trim().isEmpty ? event.orgId : vm.organisationName.trim();
    final String templateName =
        vm.evaluationTemplateName.trim().isEmpty ? event.evaluationTemplateId.trim() : vm.evaluationTemplateName.trim();
    final EventMetaChip ideasChip = EventMetaChip(
      icon: AppIcons.ideas,
      label: '${vm.ideas.length} ${vm.ideas.length == 1 ? 'idea' : 'ideas'}',
      color: const Color(0xFF4F46E5),
    );
    final List<Widget> statusPills = _statusPills(vm);

    switch (selectedId) {
      case 'ideas':
        return <Widget>[...statusPills, ideasChip, IdeathonTypePill(type: event.ideathonType, compact: false)];
      case 'payments':
        return <Widget>[
          ...statusPills,
          ideasChip,
          _PaymentContextPills(loadFuture: _paymentsFuture),
        ];
      case 'assignments':
        return <Widget>[
          ...statusPills,
          EventMetaChip(
            icon: AppIcons.judges,
            label: '${vm.workspace.assignmentCount} assignment${vm.workspace.assignmentCount == 1 ? '' : 's'}',
            color: const Color(0xFF7C3AED),
          ),
          EventMetaChip(
            icon: vm.workspace.evaluationStarted || IdeathonService.isEventCompleted(event)
                ? AppIcons.lock
                : AppIcons.judges,
            label: vm.workspace.evaluationStarted || IdeathonService.isEventCompleted(event)
                ? 'Assignments locked'
                : 'Assignments open',
            color: vm.workspace.evaluationStarted || IdeathonService.isEventCompleted(event)
                ? const Color(0xFFB45309)
                : const Color(0xFF059669),
          ),
        ];
      case 'template':
        final bool templateLocked = IdeathonService.isEvaluationTemplateLocked(
          event,
          evaluationStarted: vm.workspace.evaluationStarted,
        );
        return <Widget>[
          ...statusPills,
          if (templateName.isNotEmpty)
            EventMetaChip(icon: AppIcons.scoring, label: templateName, color: const Color(0xFF4F46E5)),
          EventMetaChip(
            icon: templateLocked ? AppIcons.lock : AppIcons.edit,
            label: templateLocked ? 'Template locked' : 'Template editable',
            color: templateLocked ? const Color(0xFFB45309) : const Color(0xFF047857),
          ),
        ];
      case 'results':
        return <Widget>[
          ...statusPills,
          EventMetaChip(
            icon: AppIcons.results,
            label: vm.workspace.evaluationProgressLabel,
            color: const Color(0xFF059669),
          ),
        ];
      case 'winners':
      case 'leaderboard':
      case 'reports':
        return <Widget>[
          ...statusPills,
          ideasChip,
          EventMetaChip(
            icon: AppIcons.results,
            label: vm.workspace.evaluationProgressLabel,
            color: const Color(0xFF059669),
          ),
        ];
      default:
        return <Widget>[
          ...statusPills,
          EventMetaChip(icon: AppIcons.event, label: dateLabel, color: const Color(0xFF0369A1)),
          EventMetaChip(icon: AppIcons.clock, label: timeLabel, color: const Color(0xFF0369A1)),
          IdeathonTypePill(type: event.ideathonType, compact: false),
          if (org.isNotEmpty)
            EventMetaChip(icon: AppIcons.organizations, label: org, color: const Color(0xFF0F766E)),
          ideasChip,
        ];
    }
  }

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
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId, actor: session.user),
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
          final bool eventCompleted = IdeathonService.isEventCompleted(event);
          final bool evaluationLocked = vm.workspace.evaluationStarted || eventCompleted;

          if (_editing && _canEdit && !eventCompleted) {
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
                  initialId: _moduleId,
                  onSelected: (String id) => _moduleId = id,
                  command: _commandFor(vm),
                  contextPillsFor: (String id) => _contextPills(vm, id),
                  headerActions: _canEdit && !eventCompleted
                      ? CardOverflowMenuButton(
                          tooltip: 'Event actions',
                          onSelected: (String value) {
                            if (value == 'edit') setState(() => _editing = true);
                          },
                          actions: <CardOverflowMenuAction>[
                            CardOverflowMenuAction(
                              value: 'edit',
                              icon: evaluationLocked ? AppIcons.lock : AppIcons.edit,
                              label: 'Edit event',
                            ),
                          ],
                        )
                      : null,
                  navigation: <EventDetailsNavGroup>[
                    EventDetailsNavGroup(
                      id: 'overview',
                      label: 'Overview',
                      icon: AppIcons.info,
                      items: <EventDetailsModule>[
                        EventDetailsModule(
                          id: 'overview',
                          label: 'Overview',
                          icon: AppIcons.info,
                          child: IdeathonOverviewTab(vm: vm),
                        ),
                      ],
                    ),
                    EventDetailsNavGroup(
                      id: 'entries',
                      label: EventKind.ideathon.entriesLabel,
                      icon: AppIcons.ideas,
                      items: <EventDetailsModule>[
                        EventDetailsModule(
                          id: 'ideas',
                          label: EventKind.ideathon.entriesLabel,
                          icon: AppIcons.ideas,
                          count: vm.ideas.isEmpty ? null : vm.ideas.length,
                          child: IdeathonIdeasTab(vm: vm, onRefresh: _reload),
                        ),
                      ],
                    ),
                    EventDetailsNavGroup(
                      id: 'payments',
                      label: 'Payments',
                      icon: AppIcons.payments,
                      items: <EventDetailsModule>[
                        EventDetailsModule(
                          id: 'payments',
                          label: 'Payments',
                          icon: AppIcons.payments,
                          child: IdeathonPaymentsTab(
                            ideathonId: event.ideathonId,
                            actor: widget.actor,
                            loadFuture: _paymentsFuture,
                            onChanged: _reload,
                          ),
                        ),
                      ],
                    ),
                    EventDetailsNavGroup(
                      id: 'evaluation',
                      label: 'Evaluation',
                      icon: AppIcons.scoring,
                      items: <EventDetailsModule>[
                        EventDetailsModule(
                          id: 'assignments',
                          label: 'Judge Assignments',
                          icon: AppIcons.judges,
                          count: vm.workspace.assignmentCount == 0 ? null : vm.workspace.assignmentCount,
                          child: IdeathonJudgeAssignmentsTab(
                            key: ValueKey<String>('${event.ideathonId}:${vm.ideas.length}'),
                            ideathonId: event.ideathonId,
                            actor: widget.actor,
                          ),
                        ),
                        EventDetailsModule(
                          id: 'template',
                          label: 'Evaluation Template',
                          icon: AppIcons.scoring,
                          child: IdeathonEvaluationTemplateTab(
                            vm: vm,
                            actor: widget.actor,
                            onSaved: _reload,
                          ),
                        ),
                        EventDetailsModule(
                          id: 'results',
                          label: 'Evaluation Results',
                          icon: AppIcons.results,
                          child: IdeathonResultsTab(event: event, actor: widget.actor),
                        ),
                      ],
                    ),
                    EventDetailsNavGroup(
                      id: 'outcome',
                      label: 'Outcome',
                      icon: AppIcons.leaderboard,
                      items: <EventDetailsModule>[
                        EventDetailsModule(
                          id: 'winners',
                          label: 'Winners',
                          icon: AppIcons.star,
                          child: IdeathonWinnersTab(vm: vm, actor: widget.actor, onChanged: _reload),
                        ),
                        EventDetailsModule(
                          id: 'leaderboard',
                          label: 'Leaderboard',
                          icon: AppIcons.leaderboard,
                          child: IdeathonLeaderboardTab(vm: vm, actor: widget.actor),
                        ),
                        EventDetailsModule(
                          id: 'reports',
                          label: 'Reports',
                          icon: AppIcons.docs,
                          child: IdeathonReportsTab(vm: vm, actor: widget.actor),
                        ),
                      ],
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

class _PaymentContextPills extends StatelessWidget {
  const _PaymentContextPills({required this.loadFuture});

  final Future<EventPaymentsViewModel> loadFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventPaymentsViewModel>(
      future: loadFuture,
      builder: (BuildContext context, AsyncSnapshot<EventPaymentsViewModel> snapshot) {
        final EventPaymentMetrics? metrics = snapshot.data?.metrics;
        if (metrics == null) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            EventMetaChip(
              icon: AppIcons.payments,
              label: '${metrics.confirmed} confirmed',
              color: const Color(0xFF059669),
            ),
            EventMetaChip(
              icon: AppIcons.clock,
              label: '${metrics.pending} pending',
              color: const Color(0xFFEA580C),
            ),
            if (metrics.exceptions > 0)
              EventMetaChip(
                icon: AppIcons.error,
                label: '${metrics.exceptions} exception${metrics.exceptions == 1 ? '' : 's'}',
                color: const Color(0xFFB91C1C),
              ),
          ],
        );
      },
    );
  }
}
