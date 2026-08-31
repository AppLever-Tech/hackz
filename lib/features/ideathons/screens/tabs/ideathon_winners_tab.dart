import 'package:flutter/material.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/features/events/models/event_winner_entry.dart';
import 'package:hackz/features/events/widgets/event_winner_picker.dart';
import 'package:hackz/features/events/widgets/event_winners_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonWinnersTab extends StatefulWidget {
  const IdeathonWinnersTab({
    super.key,
    required this.vm,
    required this.actor,
    this.onChanged,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;
  final VoidCallback? onChanged;

  @override
  State<IdeathonWinnersTab> createState() => _IdeathonWinnersTabState();
}

class _IdeathonWinnersTabState extends State<IdeathonWinnersTab> {
  late Future<List<EventWinnerEntry>> _candidatesFuture;
  late String _winnerId;
  late String _runnerId;
  bool _busy = false;

  bool get _canSelect =>
      IdeathonService.canManageEventOutcome(widget.actor) &&
      !IdeathonService.isEventCompleted(widget.vm.ideathon);

  @override
  void initState() {
    super.initState();
    _winnerId = widget.vm.ideathon.winnerIdeaId;
    _runnerId = widget.vm.ideathon.runnerUpIdeaId;
    _candidatesFuture = _loadCandidates();
  }

  @override
  void didUpdateWidget(covariant IdeathonWinnersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.ideathon.ideathonId != widget.vm.ideathon.ideathonId ||
        oldWidget.vm.ideathon.updatedAt != widget.vm.ideathon.updatedAt) {
      _winnerId = widget.vm.ideathon.winnerIdeaId;
      _runnerId = widget.vm.ideathon.runnerUpIdeaId;
      _candidatesFuture = _loadCandidates();
    }
  }

  Future<List<EventWinnerEntry>> _loadCandidates() async {
    final EvaluationResultsQueryResult result = await EvaluationResultsQueryService.fetch(
      EvaluationResultsQueryParams(
        viewer: widget.actor,
        ideathonId: widget.vm.ideathon.ideathonId,
      ),
    );
    final Map<String, String> teamByIdea = <String, String>{
      for (final IdeathonIdeaEntry row in widget.vm.ideas) row.ideaId: row.teamName,
    };
    final List<EventWinnerEntry> candidates = <EventWinnerEntry>[];
    for (final row in result.rows) {
      if (row.rank <= 0) continue;
      final String score = row.aggregate.averageScore == null
          ? '—'
          : row.aggregate.averageScore!.toStringAsFixed(2);
      candidates.add(
        EventWinnerEntry(
          rank: row.rank,
          placeLabel: row.evaluationComplete ? '#${row.rank}' : 'Pending',
          ideaId: row.idea.ideaId,
          ideaTitle: row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim(),
          teamId: row.idea.teamId,
          teamName: (teamByIdea[row.idea.ideaId] ?? '').trim(),
          scoreLabel: score,
          summary: row.assignedJudges > 0
              ? '${row.assignedJudges} judge${row.assignedJudges == 1 ? '' : 's'} · ${row.aggregate.totalEvaluators} score${row.aggregate.totalEvaluators == 1 ? '' : 's'}'
              : '${row.aggregate.totalEvaluators} evaluation${row.aggregate.totalEvaluators == 1 ? '' : 's'}',
          problemId: row.idea.problemId,
          problemTitle: row.problemTitle,
        ),
      );
    }
    candidates.sort((EventWinnerEntry a, EventWinnerEntry b) => a.rank.compareTo(b.rank));
    return candidates;
  }

  List<EventWinnerEntry> _selectedFrom(List<EventWinnerEntry> candidates) {
    EventWinnerEntry? byId(String id, int rank, String label) {
      final String ideaId = id.trim();
      if (ideaId.isEmpty) return null;
      for (final EventWinnerEntry e in candidates) {
        if (e.ideaId == ideaId) {
          return EventWinnerEntry(
            rank: rank,
            placeLabel: label,
            ideaId: e.ideaId,
            ideaTitle: e.ideaTitle,
            teamId: e.teamId,
            teamName: e.teamName,
            scoreLabel: e.scoreLabel,
            summary: e.summary,
            problemId: e.problemId,
            problemTitle: e.problemTitle,
          );
        }
      }
      return widget.vm.workspace.winner?.ideaId == ideaId
          ? widget.vm.workspace.winner
          : widget.vm.workspace.runnerUp?.ideaId == ideaId
              ? widget.vm.workspace.runnerUp
              : null;
    }

    return <EventWinnerEntry>[
      if (byId(_winnerId, 1, 'Winner') != null) byId(_winnerId, 1, 'Winner')!,
      if (byId(_runnerId, 2, 'Runner-up') != null) byId(_runnerId, 2, 'Runner-up')!,
    ];
  }

  Future<void> _save() async {
    final int pending = widget.vm.workspace.pendingEvaluationCount;
    if (pending > 0) {
      final bool ok = await FeedbackService.showConfirmation(
        context,
        title: 'Evaluations still pending',
        message:
            '$pending evaluation${pending == 1 ? '' : 's'} are not complete. Select official winners anyway?',
        confirmLabel: 'Select winners',
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await IdeathonService.selectWinners(
        actor: widget.actor,
        ideathonId: widget.vm.ideathon.ideathonId,
        winnerIdeaId: _winnerId,
        runnerUpIdeaId: _runnerId,
      );
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Winners saved',
        message: 'Official winner and runner-up are recorded for this event.',
      );
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to save winners', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventWinnerEntry>>(
      future: _candidatesFuture,
      builder: (BuildContext context, AsyncSnapshot<List<EventWinnerEntry>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 32));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load winners: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        final List<EventWinnerEntry> candidates = snapshot.data ?? const <EventWinnerEntry>[];
        final List<EventWinnerEntry> selected = _selectedFrom(candidates);

        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          children: <Widget>[
            if (_canSelect) ...<Widget>[
              EventWinnerPicker(
                candidates: candidates,
                winnerIdeaId: _winnerId,
                runnerUpIdeaId: _runnerId,
                pendingCount: widget.vm.workspace.pendingEvaluationCount,
                busy: _busy,
                onWinnerChanged: (String id) => setState(() => _winnerId = id),
                onRunnerUpChanged: (String id) => setState(() => _runnerId = id),
                onSave: _save,
              ),
              const SizedBox(height: 12),
            ],
            EventWinnersSection(
                entries: selected,
                shrinkWrap: true,
                emptyMessage: _canSelect
                    ? 'Select a winner above. Leaderboard ranks are not official places.'
                    : 'Winners are published after Department Admin selects official places.',
                onOpenIdea: (EventWinnerEntry e) => WorkspaceNavigator.openIdea(context, e.ideaId),
                onOpenTeam: (EventWinnerEntry e) {
                  if (e.teamId.trim().isEmpty) return;
                  WorkspaceNavigator.openTeam(context, e.teamId);
                },
                onOpenProblem: (EventWinnerEntry e) {
                  if (e.problemId.trim().isEmpty) return;
                  WorkspaceNavigator.openProblem(context, e.problemId);
                },
              ),
          ],
        );
      },
    );
  }
}
