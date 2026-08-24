import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/features/events/models/event_winner_entry.dart';
import 'package:hackz/features/events/widgets/event_winners_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonWinnersTab extends StatefulWidget {
  const IdeathonWinnersTab({
    super.key,
    required this.vm,
    required this.actor,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  State<IdeathonWinnersTab> createState() => _IdeathonWinnersTabState();
}

class _IdeathonWinnersTabState extends State<IdeathonWinnersTab> {
  late Future<List<EventWinnerEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<EventWinnerEntry>> _load() async {
    final EvaluationResultsQueryResult result = await EvaluationResultsQueryService.fetch(
      EvaluationResultsQueryParams(
        viewer: widget.actor,
        ideathonId: widget.vm.ideathon.ideathonId,
      ),
    );
    final Map<String, String> teamByIdea = <String, String>{
      for (final IdeathonIdeaEntry row in widget.vm.ideas) row.ideaId: row.teamName,
    };
    final List<EventWinnerEntry> winners = <EventWinnerEntry>[];
    for (final row in result.rows) {
      if (row.rank != 1 && row.rank != 2) continue;
      if (!row.evaluationComplete) continue;
      final String score = row.aggregate.averageScore == null
          ? '—'
          : row.aggregate.averageScore!.toStringAsFixed(2);
      winners.add(
        EventWinnerEntry(
          rank: row.rank,
          placeLabel: row.rank == 1 ? 'Winner' : 'Runner-up',
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
    winners.sort((EventWinnerEntry a, EventWinnerEntry b) => a.rank.compareTo(b.rank));
    return winners;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventWinnerEntry>>(
      future: _future,
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
        return EventWinnersSection(
          entries: snapshot.data ?? const <EventWinnerEntry>[],
          onOpenIdea: (EventWinnerEntry e) => WorkspaceNavigator.openIdea(context, e.ideaId),
          onOpenTeam: (EventWinnerEntry e) {
            if (e.teamId.trim().isEmpty) return;
            WorkspaceNavigator.openTeam(context, e.teamId);
          },
          onOpenProblem: (EventWinnerEntry e) {
            if (e.problemId.trim().isEmpty) return;
            WorkspaceNavigator.openProblem(context, e.problemId);
          },
        );
      },
    );
  }
}
