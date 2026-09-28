import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/events/models/event_payment_entry.dart';
import 'package:hackz/features/events/services/event_payments_service.dart';
import 'package:hackz/features/ideathons/services/event_details_tab_cache.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_shell_loader.dart';
import 'package:hackz/features/ideathons/services/event_details_evaluation_access.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_workspace_loader.dart';

/// Loads a tab slice once, caches it, and builds an [IdeathonDetailsViewModel].
class EventDetailsLazyTab extends StatefulWidget {
  const EventDetailsLazyTab({
    super.key,
    required this.shell,
    required this.cache,
    required this.cacheKey,
    required this.load,
    required this.builder,
    this.evaluationWorkspace,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final String cacheKey;
  final Future<IdeathonDetailsViewModel> Function(
    IdeathonDetailsShellViewModel shell,
    IdeathonWorkspaceViewModel evaluationWorkspace,
  ) load;
  final Widget Function(IdeathonDetailsViewModel vm) builder;
  final IdeathonWorkspaceViewModel? evaluationWorkspace;

  @override
  State<EventDetailsLazyTab> createState() => _EventDetailsLazyTabState();
}

class _EventDetailsLazyTabState extends State<EventDetailsLazyTab> {
  late Future<IdeathonDetailsViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(covariant EventDetailsLazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shell.ideathon.ideathonId != widget.shell.ideathon.ideathonId ||
        oldWidget.cacheKey != widget.cacheKey) {
      setState(() => _future = _resolve());
    }
  }

  Future<IdeathonWorkspaceViewModel> _evaluationWorkspace() async {
    if (widget.evaluationWorkspace != null) return widget.evaluationWorkspace!;
    return EventDetailsEvaluationAccess.workspace(widget.cache, widget.shell);
  }

  Future<IdeathonDetailsViewModel> _resolve() {
    return widget.cache.getOrLoad<IdeathonDetailsViewModel>(
      widget.cacheKey,
      () async {
        final IdeathonWorkspaceViewModel evaluation = await _evaluationWorkspace();
        return widget.load(widget.shell, evaluation);
      },
    );
  }

  void _retry() => setState(() {
        widget.cache.invalidate(widget.cacheKey);
        _future = _resolve();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdeathonDetailsViewModel>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<IdeathonDetailsViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    snapshot.hasError ? 'Unable to load: ${snapshot.error}' : 'Unable to load tab',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        return widget.builder(snapshot.data!);
      },
    );
  }
}

/// Overview: event fields from shell + people roster.
class EventDetailsOverviewTabHost extends StatelessWidget {
  const EventDetailsOverviewTabHost({
    super.key,
    required this.shell,
    required this.cache,
    required this.builder,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final Widget Function(IdeathonDetailsViewModel vm) builder;

  @override
  Widget build(BuildContext context) {
    return EventDetailsLazyTab(
      shell: shell,
      cache: cache,
      cacheKey: EventDetailsTabKeys.overviewPeople,
      load: (IdeathonDetailsShellViewModel shell, IdeathonWorkspaceViewModel evaluation) async {
        final IdeathonOverviewPeople people = await IdeathonDetailsLoader.loadOverviewPeople(shell.ideathon);
        final IdeathonWorkspaceViewModel workspace = evaluation.copyWith(
          judges: people.judges,
          coordinators: people.coordinators,
        );
        return IdeathonDetailsViewModel.fromShell(shell: shell, workspace: workspace);
      },
      builder: builder,
    );
  }
}

/// Ideas tab: full idea documents.
class EventDetailsIdeasTabHost extends StatelessWidget {
  const EventDetailsIdeasTabHost({
    super.key,
    required this.shell,
    required this.cache,
    required this.evaluationWorkspace,
    required this.builder,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final IdeathonWorkspaceViewModel? evaluationWorkspace;
  final Widget Function(IdeathonDetailsViewModel vm) builder;

  @override
  Widget build(BuildContext context) {
    return EventDetailsLazyTab(
      shell: shell,
      cache: cache,
      cacheKey: EventDetailsTabKeys.ideas,
      evaluationWorkspace: evaluationWorkspace,
      load: (IdeathonDetailsShellViewModel shell, IdeathonWorkspaceViewModel evaluation) async {
        final List<IdeathonIdeaEntry> ideas =
            await EventDetailsEvaluationAccess.ideaEntries(cache, shell);
        return IdeathonDetailsViewModel.fromShell(
          shell: shell,
          workspace: evaluation,
          ideas: ideas,
        );
      },
      builder: builder,
    );
  }
}

/// Lifecycle / template / reports / winners: evaluation metrics only (no full ideas unless needed).
class EventDetailsEvaluationTabHost extends StatelessWidget {
  const EventDetailsEvaluationTabHost({
    super.key,
    required this.shell,
    required this.cache,
    required this.cacheKey,
    required this.evaluationWorkspace,
    required this.builder,
    this.includeIdeas = false,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final String cacheKey;
  final IdeathonWorkspaceViewModel? evaluationWorkspace;
  final Widget Function(IdeathonDetailsViewModel vm) builder;
  final bool includeIdeas;

  @override
  Widget build(BuildContext context) {
    return EventDetailsLazyTab(
      shell: shell,
      cache: cache,
      cacheKey: cacheKey,
      evaluationWorkspace: evaluationWorkspace,
      load: (IdeathonDetailsShellViewModel shell, IdeathonWorkspaceViewModel evaluation) async {
        List<IdeathonIdeaEntry> ideas = const <IdeathonIdeaEntry>[];
        if (includeIdeas) {
          ideas = await EventDetailsEvaluationAccess.ideaEntries(cache, shell);
        }
        return IdeathonDetailsViewModel.fromShell(
          shell: shell,
          workspace: evaluation,
          ideas: ideas,
        );
      },
      builder: builder,
    );
  }
}

/// Payments tab with cache.
class EventDetailsPaymentsTabHost extends StatefulWidget {
  const EventDetailsPaymentsTabHost({
    super.key,
    required this.shell,
    required this.cache,
    required this.builder,
  });

  final IdeathonDetailsShellViewModel shell;
  final EventDetailsTabCacheBucket cache;
  final Widget Function(Future<EventPaymentsViewModel> loadFuture) builder;

  @override
  State<EventDetailsPaymentsTabHost> createState() => _EventDetailsPaymentsTabHostState();
}

class _EventDetailsPaymentsTabHostState extends State<EventDetailsPaymentsTabHost> {
  late Future<EventPaymentsViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<EventPaymentsViewModel> _load() {
    return widget.cache.getOrLoad<EventPaymentsViewModel>(
      EventDetailsTabKeys.payments,
      () => EventPaymentsService.load(
        kind: widget.shell.ideathon.eventKind,
        eventId: widget.shell.ideathon.ideathonId,
      ),
    );
  }

  void reloadPayments() {
    widget.cache.invalidate(EventDetailsTabKeys.payments);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventPaymentsViewModel>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<EventPaymentsViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load payments: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        return widget.builder(_future);
      },
    );
  }
}
