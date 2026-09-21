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
import 'package:hackz/features/evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/features/events/models/event_details_module.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/models/event_lifecycle.dart';
import 'package:hackz/features/events/screens/event_details_shell.dart';
import 'package:hackz/features/events/widgets/event_meta_chip.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
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
import 'package:hackz/features/ideathons/services/event_details_tab_cache.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_shell_loader.dart';
import 'package:hackz/features/ideathons/services/event_details_evaluation_access.dart';
import 'package:hackz/features/ideathons/services/event_details_evaluation_bundle.dart';
import 'package:hackz/features/ideathons/widgets/event_details_lazy_tabs.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_workspace_loader.dart';
import 'package:hackz/features/events/models/event_payment_entry.dart';
import 'package:hackz/features/events/services/event_payments_service.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
import 'package:hackz/features/ideathons/widgets/event_commercial_access_pill.dart';
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
  EventKind eventKind = EventKind.ideathon,
  String backTooltip = 'Back to Events',
  VoidCallback? onDeleted,
}) {
  WorkspaceController.instance.close();
  final chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    IdeathonDetailsPane(
      key: ValueKey<String>(ideathonId),
      ideathonId: ideathonId,
      actor: actor,
      eventKind: eventKind,
      onBack: chrome.clearOverlay,
      backTooltip: backTooltip,
      onDeleted: onDeleted,
    ),
  );
}

class IdeathonDetailsPane extends StatefulWidget {
  const IdeathonDetailsPane({
    super.key,
    required this.ideathonId,
    required this.actor,
    required this.onBack,
    this.eventKind = EventKind.ideathon,
    this.backTooltip = 'Back to Events',
    this.onDeleted,
  });

  final String ideathonId;
  final UserModel actor;
  final VoidCallback onBack;
  final EventKind eventKind;
  final String backTooltip;
  final VoidCallback? onDeleted;

  @override
  State<IdeathonDetailsPane> createState() => _IdeathonDetailsPaneState();
}

class _IdeathonDetailsPaneState extends State<IdeathonDetailsPane> {
  late Future<IdeathonDetailsShellViewModel> _shellFuture;
  late Future<IdeathonWorkspaceViewModel> _evaluationFuture;
  late EventDetailsTabCacheBucket _tabCache;
  IdeathonWorkspaceViewModel? _evaluationWorkspace;
  bool _editing = false;
  String _moduleId = 'overview';

  @override
  void initState() {
    super.initState();
    _tabCache = EventDetailsTabCache.forEvent(widget.ideathonId);
    _shellFuture = IdeathonDetailsShellLoader.load(widget.ideathonId);
    _evaluationFuture = _loadEvaluationBundle();
    _shellFuture.then(_runBackgroundMaintenance);
  }

  Future<IdeathonWorkspaceViewModel> _loadEvaluationBundle() {
    return _shellFuture.then((IdeathonDetailsShellViewModel shell) {
      return EventDetailsEvaluationAccess.bundle(_tabCache, shell);
    }).then((EventDetailsEvaluationBundle bundle) {
      if (mounted) {
        setState(() => _evaluationWorkspace = bundle.workspace);
      }
      return bundle.workspace;
    });
  }

  Future<void> _runBackgroundMaintenance(IdeathonDetailsShellViewModel shell) async {
    IdeathonModel ideathon = shell.ideathon;
    try {
      await IdeathonService.ensurePerEventEntitlement(ideathon);
      final IdeathonModel? refreshed = await IdeathonService.fetchById(ideathon.ideathonId);
      if (refreshed != null) ideathon = refreshed;
    } catch (_) {
      // Non-blocking; event details remain usable.
    }

    try {
      if (await IdeathonService.promoteEligibleSubmissionsWithoutIdeaPayment(ideathon.ideathonId)) {
        if (!mounted) return;
        _refreshAfterRosterChange();
      }
    } catch (_) {
      // Non-blocking.
    }
  }

  void _refreshAfterRosterChange() {
    _tabCache.invalidate(EventDetailsTabKeys.payments);
    _tabCache.invalidateEvaluationData();
    setState(() {
      _evaluationWorkspace = null;
      _shellFuture = IdeathonDetailsShellLoader.load(widget.ideathonId);
      _evaluationFuture = _loadEvaluationBundle();
    });
    _shellFuture.then(_runBackgroundMaintenance);
  }

  void _invalidateEvaluationOnly() {
    _tabCache.invalidateEvaluationData();
    setState(() {
      _evaluationWorkspace = null;
      _shellFuture = IdeathonDetailsShellLoader.load(widget.ideathonId);
      _evaluationFuture = _loadEvaluationBundle();
    });
  }

  void _reload() {
    EventDetailsTabCache.invalidateEvent(widget.ideathonId);
    setState(() {
      _evaluationWorkspace = null;
      _tabCache = EventDetailsTabCache.forEvent(widget.ideathonId);
      _shellFuture = IdeathonDetailsShellLoader.load(widget.ideathonId);
      _evaluationFuture = _loadEvaluationBundle();
    });
    _shellFuture.then(_runBackgroundMaintenance);
  }

  IdeathonDetailsViewModel? _viewModelForActions(IdeathonDetailsShellViewModel shell) {
    final IdeathonWorkspaceViewModel? evaluation = _evaluationWorkspace;
    if (evaluation == null) return null;
    return IdeathonDetailsViewModel.fromShell(shell: shell, workspace: evaluation);
  }

  String _initialModuleId(IdeathonDetailsShellViewModel shell) {
    if (!shell.requiresIdeaPayment && _moduleId == 'payments') return 'overview';
    if (_moduleId == 'lifecycle') return 'overview';
    return _moduleId;
  }

  bool get _canEdit => RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(widget.actor.role));

  bool get _canExtend =>
      RoleVisibilityHelpers.canExtendEventSchedule(UserRole.fromCode(widget.actor.role));

  EventDetailsCommand _commandFor(IdeathonDetailsShellViewModel shell) {
    final IdeathonDetailsViewModel? vm = _viewModelForActions(shell);
    if (vm == null) {
      return const EventDetailsCommand(
        label: 'Loading…',
        icon: AppIcons.scoring,
        enabled: false,
      );
    }
    final EventLifecycleProgress progress = vm.workspace.lifecycleProgress;
    final EventPrimaryActionKind kind = EventLifecycle.primaryAction(
      progress,
      canManageOutcome: _canEdit,
      usesWinners: vm.ideathon.eventKind.usesWinners,
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
      _invalidateEvaluationOnly();
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
      message: vm.ideathon.eventKind.usesWinners
          ? '${pendingLine}Completing locks evaluation configuration, judge assignments, the template, scores, results, and winner selection. Reports and results stay available.'
          : '${pendingLine}Completing locks evaluation configuration, judge assignments, the template, and scores. Results stay available.',
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
        message: 'This ${vm.ideathon.eventKind.label} is read-only. Results remain available.',
      );
      _invalidateEvaluationOnly();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to complete event', message: '$e');
    }
  }

  Future<void> _extendEndDate(IdeathonModel event) async {
    final DateTime current = event.endDateTime.toLocal();
    final DateTime start = event.startDateTime.toLocal();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(start) ? current : start.add(const Duration(days: 1)),
      firstDate: start,
      lastDate: DateTime.now().add(Duration(days: 365 * (event.isLongRunning ? 5 : 2))),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null || !mounted) return;
    final DateTime next = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await IdeathonService.extendEndDate(
        actor: widget.actor,
        ideathonId: event.ideathonId,
        endDateTime: next,
      );
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'End date extended',
        message: 'The scheduled end is now ${formatDateTime(next)}. The event lifecycle is unchanged.',
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to extend end date', message: '$e');
    }
  }

  List<Widget> _statusPills(IdeathonDetailsShellViewModel shell) {
    final IdeathonDetailsViewModel? vm = _viewModelForActions(shell);
    final EventLifecycleProgress? progress = vm?.workspace.lifecycleProgress;
    return <Widget>[
      IdeathonStatusPill(status: shell.ideathon.status, compact: false),
      EventCommercialAccessPill.forEvent(
        event: shell.ideathon,
        plan: shell.commercialPlan,
        compact: false,
      ),
      if (progress != null && progress.pendingEvaluationCount > 0 && !progress.completed)
        EventMetaChip(
          icon: AppIcons.clock,
          label: '${progress.pendingEvaluationCount} pending',
          color: const Color(0xFFEA580C),
        )
      else if (progress != null && progress.resultsReady && !progress.completed)
        const EventMetaChip(
          icon: AppIcons.results,
          label: 'Results ready',
          color: Color(0xFF059669),
        ),
      if (progress != null && progress.winnersSelected && !progress.completed)
        const EventMetaChip(
          icon: AppIcons.star,
          label: 'Winners selected',
          color: Color(0xFFB45309),
        ),
      if (progress != null && progress.completed)
        const EventMetaChip(
          icon: AppIcons.lock,
          label: 'Read-only',
          color: Color(0xFF047857),
        ),
    ];
  }

  List<Widget> _contextPills(IdeathonDetailsShellViewModel shell, String selectedId) {
    final event = shell.ideathon;
    final IdeathonDetailsViewModel? vm = _viewModelForActions(shell);
    final DateTime start = event.startDateTime.toLocal();
    final DateTime end = event.endDateTime.toLocal();
    final bool sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    final String dateLabel = sameDay
        ? formatShortDate(start)
        : '${formatShortDate(start)} – ${formatShortDate(end)}';
    final String timeLabel = '${formatShortTime(start)} – ${formatShortTime(end)}';
    final String org = shell.organisationName.trim();
    final String templateName = shell.evaluationTemplateName.trim().isEmpty
        ? event.evaluationTemplateId.trim()
        : shell.evaluationTemplateName.trim();
    final int ideaCount = shell.ideaCount;
    final EventMetaChip ideasChip = EventMetaChip(
      icon: event.eventKind.entriesIcon,
      label:
          '$ideaCount ${ideaCount == 1 ? event.eventKind.payableItemLabel.toLowerCase() : event.eventKind.entriesLabel.toLowerCase()}',
      color: const Color(0xFF4F46E5),
    );
    final List<Widget> statusPills = _statusPills(shell);

    switch (selectedId) {
      case 'ideas':
        return <Widget>[...statusPills, ideasChip, IdeathonTypePill(type: event.ideathonType, compact: false)];
      case 'payments':
        return <Widget>[
          ...statusPills,
          ideasChip,
          _PaymentContextPills(cache: _tabCache, shell: shell),
        ];
      case 'assignments':
        final int assignmentCount = vm?.workspace.assignmentCount ?? 0;
        final bool evaluationStarted = vm?.workspace.evaluationStarted ?? false;
        return <Widget>[
          ...statusPills,
          if (vm != null)
            EventMetaChip(
              icon: AppIcons.judges,
              label: '$assignmentCount assignment${assignmentCount == 1 ? '' : 's'}',
              color: const Color(0xFF7C3AED),
            ),
          EventMetaChip(
            icon: evaluationStarted || IdeathonService.isEventCompleted(event)
                ? AppIcons.lock
                : AppIcons.judges,
            label: evaluationStarted || IdeathonService.isEventCompleted(event)
                ? 'Assignments locked'
                : 'Assignments open',
            color: evaluationStarted || IdeathonService.isEventCompleted(event)
                ? const Color(0xFFB45309)
                : const Color(0xFF059669),
          ),
        ];
      case 'template':
        final bool templateLocked = IdeathonService.isEvaluationTemplateLocked(
          event,
          evaluationStarted: vm?.workspace.evaluationStarted ?? false,
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
          if (vm != null)
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
          if (vm != null)
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

  Widget? _eventActions(
    IdeathonDetailsShellViewModel shell, {
    required bool eventCompleted,
    required bool evaluationLocked,
  }) {
    return _EventOverflowActions(
      shell: shell,
      tabCache: _tabCache,
      canEdit: _canEdit,
      canExtend: _canExtend,
      eventCompleted: eventCompleted,
      evaluationLocked: evaluationLocked,
      onEdit: () => setState(() => _editing = true),
      onExtend: () => _extendEndDate(shell.ideathon),
      onDelete: () => _deleteEvent(shell),
      actor: widget.actor,
      onBack: widget.onBack,
      onDeleted: widget.onDeleted,
    );
  }

  Future<void> _deleteEvent(IdeathonDetailsShellViewModel shell) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete event?',
      message:
          'Delete ${shell.ideathon.name.trim().isEmpty ? 'this event' : '"${shell.ideathon.name.trim()}"'}? '
          'This cannot be undone. Only unused events with no submissions, payments, or evaluation records can be deleted.',
      confirmLabel: 'Delete Event',
      dangerConfirm: true,
    );
    if (!ok) return;
    try {
      await IdeathonService.deleteUnusedEvent(
        actor: widget.actor,
        ideathonId: shell.ideathon.ideathonId,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to delete event', message: '$e');
      return;
    }
    if (!mounted) return;
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    widget.onBack();
    widget.onDeleted?.call();
    if (!navigator.mounted) return;
    FeedbackService.showSuccess(
      navigator.context,
      title: 'Event deleted',
      message: 'The unused event was removed.',
    );
  }

  Future<EvaluationResultsQueryResult> _sharedResultsFuture(IdeathonDetailsShellViewModel shell) {
    return EventDetailsEvaluationAccess.unfilteredResults(_tabCache, shell);
  }

  List<EventDetailsNavGroup> _navigationFor(IdeathonDetailsShellViewModel shell) {
    final IdeathonModel event = shell.ideathon;
    final EventKind kind = event.eventKind;
    final int? assignmentCount = _evaluationWorkspace?.assignmentCount;
    final Future<EvaluationResultsQueryResult> sharedResults = _sharedResultsFuture(shell);
    final List<EventDetailsNavGroup> groups = <EventDetailsNavGroup>[
      EventDetailsNavGroup(
        id: 'overview',
        label: 'Overview',
        icon: AppIcons.info,
        items: <EventDetailsModule>[
          EventDetailsModule(
            id: 'overview',
            label: 'Overview',
            icon: AppIcons.info,
            child: EventDetailsOverviewTabHost(
              shell: shell,
              cache: _tabCache,
              builder: (IdeathonDetailsViewModel vm) => IdeathonOverviewTab(vm: vm),
            ),
          ),
        ],
      ),
      EventDetailsNavGroup(
        id: 'entries',
        label: kind.entriesLabel,
        icon: kind.entriesIcon,
        items: <EventDetailsModule>[
          EventDetailsModule(
            id: 'ideas',
            label: kind.entriesLabel,
            icon: kind.entriesIcon,
            count: shell.ideaCount == 0 ? null : shell.ideaCount,
            child: EventDetailsIdeasTabHost(
              shell: shell,
              cache: _tabCache,
              evaluationWorkspace: _evaluationWorkspace,
              builder: (IdeathonDetailsViewModel vm) =>
                  IdeathonIdeasTab(vm: vm, actor: widget.actor, onRefresh: _reload),
            ),
          ),
        ],
      ),
      if (shell.requiresIdeaPayment)
        EventDetailsNavGroup(
          id: 'payments',
          label: 'Payments',
          icon: AppIcons.payments,
          items: <EventDetailsModule>[
            EventDetailsModule(
              id: 'payments',
              label: 'Payments',
              icon: AppIcons.payments,
              child: EventDetailsPaymentsTabHost(
                shell: shell,
                cache: _tabCache,
                builder: (Future<EventPaymentsViewModel> loadFuture) => IdeathonPaymentsTab(
                  ideathonId: event.ideathonId,
                  eventName: event.name,
                  actor: widget.actor,
                  kind: kind,
                  loadFuture: loadFuture,
                  onChanged: _reload,
                ),
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
            count: assignmentCount == null || assignmentCount == 0 ? null : assignmentCount,
            child: IdeathonJudgeAssignmentsTab(
              key: ValueKey<String>('${event.ideathonId}:${shell.ideaCount}'),
              ideathonId: event.ideathonId,
              actor: widget.actor,
            ),
          ),
          EventDetailsModule(
            id: 'template',
            label: 'Evaluation Template',
            icon: AppIcons.scoring,
            child: EventDetailsEvaluationTabHost(
              shell: shell,
              cache: _tabCache,
              cacheKey: 'template',
              evaluationWorkspace: _evaluationWorkspace,
              builder: (IdeathonDetailsViewModel vm) => IdeathonEvaluationTemplateTab(
                vm: vm,
                actor: widget.actor,
                onSaved: _reload,
              ),
            ),
          ),
          EventDetailsModule(
            id: 'results',
            label: 'Evaluation Results',
            icon: AppIcons.results,
            child: IdeathonResultsTab(
              event: event,
              actor: widget.actor,
              sharedResultsFuture: sharedResults,
            ),
          ),
        ],
      ),
    ];
    if (kind.usesWinners) {
      groups.add(
        EventDetailsNavGroup(
          id: 'outcome',
          label: 'Outcome',
          icon: AppIcons.leaderboard,
          items: <EventDetailsModule>[
            EventDetailsModule(
              id: 'winners',
              label: 'Winners',
              icon: AppIcons.star,
              child: EventDetailsEvaluationTabHost(
                shell: shell,
                cache: _tabCache,
                cacheKey: 'winners',
                evaluationWorkspace: _evaluationWorkspace,
                builder: (IdeathonDetailsViewModel vm) => IdeathonWinnersTab(
                  vm: vm,
                  actor: widget.actor,
                  onChanged: _invalidateEvaluationOnly,
                  sharedResultsFuture: sharedResults,
                ),
              ),
            ),
            EventDetailsModule(
              id: 'leaderboard',
              label: 'Leaderboard',
              icon: AppIcons.leaderboard,
              child: EventDetailsEvaluationTabHost(
                shell: shell,
                cache: _tabCache,
                cacheKey: 'leaderboard_vm',
                evaluationWorkspace: _evaluationWorkspace,
                builder: (IdeathonDetailsViewModel vm) => IdeathonLeaderboardTab(
                  vm: vm,
                  actor: widget.actor,
                  sharedResultsFuture: sharedResults,
                ),
              ),
            ),
            EventDetailsModule(
              id: 'reports',
              label: 'Reports',
              icon: AppIcons.docs,
              child: EventDetailsEvaluationTabHost(
                shell: shell,
                cache: _tabCache,
                cacheKey: 'reports',
                evaluationWorkspace: _evaluationWorkspace,
                includeIdeas: true,
                builder: (IdeathonDetailsViewModel vm) =>
                    IdeathonReportsTab(vm: vm, actor: widget.actor),
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<IdeathonDetailsShellViewModel>(
        future: _shellFuture,
        builder: (BuildContext context, AsyncSnapshot<IdeathonDetailsShellViewModel> snapshot) {
          final String title = snapshot.data?.ideathon.name.trim() ?? '';
          final EventKind kind = snapshot.data?.ideathon.eventKind ?? widget.eventKind;
          final Widget header = DashboardPageHeader(
            title: title.isEmpty ? kind.label : title,
            titleIcon: kind.icon,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId, actor: session.user),
            onRefresh: _reload,
            helpPageId: kind.helpPageId,
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
                        const Icon(AppIcons.event, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.hasError ? 'Unable to load: ${snapshot.error}' : 'Event not found',
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

          final IdeathonDetailsShellViewModel shell = snapshot.data!;
          final IdeathonModel event = shell.ideathon;
          final bool eventCompleted = IdeathonService.isEventCompleted(event);
          final bool evaluationLocked =
              (_evaluationWorkspace?.evaluationStarted ?? false) || eventCompleted;

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
                      const Text('Edit event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: CreateIdeathonWorkspace(
                    user: widget.actor,
                    eventKind: event.eventKind,
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
                child: FutureBuilder<IdeathonWorkspaceViewModel>(
                  future: _evaluationFuture,
                  builder: (BuildContext context, AsyncSnapshot<IdeathonWorkspaceViewModel> evalSnapshot) {
                    return EventDetailsShell(
                      initialId: _initialModuleId(shell),
                      onSelected: (String id) => _moduleId = id,
                      command: _commandFor(shell),
                      contextPillsFor: (String id) => _contextPills(shell, id),
                      headerActions: _eventActions(
                        shell,
                        eventCompleted: eventCompleted,
                        evaluationLocked: evaluationLocked,
                      ),
                      navigation: _navigationFor(shell),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventOverflowActions extends StatefulWidget {
  const _EventOverflowActions({
    required this.shell,
    required this.tabCache,
    required this.canEdit,
    required this.canExtend,
    required this.eventCompleted,
    required this.evaluationLocked,
    required this.onEdit,
    required this.onExtend,
    required this.onDelete,
    required this.actor,
    required this.onBack,
    this.onDeleted,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket tabCache;
  final bool canEdit;
  final bool canExtend;
  final bool eventCompleted;
  final bool evaluationLocked;
  final VoidCallback onEdit;
  final VoidCallback onExtend;
  final VoidCallback onDelete;
  final UserModel actor;
  final VoidCallback onBack;
  final VoidCallback? onDeleted;

  @override
  State<_EventOverflowActions> createState() => _EventOverflowActionsState();
}

class _EventOverflowActionsState extends State<_EventOverflowActions> {
  bool? _unusedDeletable;

  @override
  void initState() {
    super.initState();
    _resolveUnused();
  }

  Future<void> _resolveUnused() async {
    if (widget.shell.ideathon.ideas.isNotEmpty) {
      if (mounted) setState(() => _unusedDeletable = false);
      return;
    }
    final bool unused = await widget.tabCache.getOrLoad<bool>(
      EventDetailsTabKeys.unusedDeletable,
      () => IdeathonService.isUnusedEvent(widget.shell.ideathon),
    );
    if (mounted) setState(() => _unusedDeletable = unused);
  }

  @override
  Widget build(BuildContext context) {
    final List<CardOverflowMenuAction> actions = <CardOverflowMenuAction>[
      if (widget.canEdit && !widget.eventCompleted)
        CardOverflowMenuAction(
          value: 'edit',
          icon: widget.evaluationLocked ? AppIcons.lock : AppIcons.edit,
          label: 'Edit event',
        ),
      if (widget.canExtend && !widget.eventCompleted)
        const CardOverflowMenuAction(
          value: 'extend',
          icon: AppIcons.clock,
          label: 'Extend end date',
        ),
      if (widget.canEdit && _unusedDeletable == true)
        const CardOverflowMenuAction(
          value: 'delete',
          icon: AppIcons.delete,
          label: 'Delete event',
          danger: true,
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return CardOverflowMenuButton(
      tooltip: 'Event actions',
      dividersBefore: const <String>{'delete'},
      onSelected: (String value) {
        if (value == 'edit') widget.onEdit();
        if (value == 'extend') widget.onExtend();
        if (value == 'delete') widget.onDelete();
      },
      actions: actions,
    );
  }
}

class _PaymentContextPills extends StatelessWidget {
  const _PaymentContextPills({required this.cache, required this.shell});

  final EventDetailsTabCacheBucket cache;
  final IdeathonDetailsShellViewModel shell;

  @override
  Widget build(BuildContext context) {
    final Future<EventPaymentsViewModel> loadFuture = cache.getOrLoad<EventPaymentsViewModel>(
      EventDetailsTabKeys.payments,
      () => EventPaymentsService.load(
        kind: shell.ideathon.eventKind,
        eventId: shell.ideathon.ideathonId,
      ),
    );
    return FutureBuilder<EventPaymentsViewModel>(
      future: loadFuture,
      builder: (BuildContext context, AsyncSnapshot<EventPaymentsViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: HkzProgressIndicator(size: 20),
          );
        }
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
