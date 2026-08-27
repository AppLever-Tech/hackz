import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/features/events/models/event_leaderboard_entry.dart';
import 'package:hackz/features/events/widgets/event_leaderboard_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

/// Event Leaderboard for an Ideathon — ranks from existing evaluation results.
class IdeathonLeaderboardTab extends StatefulWidget {
  const IdeathonLeaderboardTab({
    super.key,
    required this.vm,
    required this.actor,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  State<IdeathonLeaderboardTab> createState() => _IdeathonLeaderboardTabState();
}

class _IdeathonLeaderboardTabState extends State<IdeathonLeaderboardTab> {
  late Future<List<EventLeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<EventLeaderboardEntry>> _load() async {
    final EvaluationResultsQueryResult result = await EvaluationResultsQueryService.fetch(
      EvaluationResultsQueryParams(
        viewer: widget.actor,
        ideathonId: widget.vm.ideathon.ideathonId,
      ),
    );
    final Map<String, String> teamByIdea = <String, String>{
      for (final IdeathonIdeaEntry row in widget.vm.ideas) row.ideaId: row.teamName,
    };
    final List<EventLeaderboardEntry> ranked = <EventLeaderboardEntry>[];
    for (final row in result.rows) {
      if (row.rank <= 0 || !row.evaluationComplete) continue;
      ranked.add(
        EventLeaderboardEntry(
          rank: row.rank,
          ideaId: row.idea.ideaId,
          ideaTitle: row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim(),
          teamId: row.idea.teamId,
          teamName: (teamByIdea[row.idea.ideaId] ?? '').trim(),
          overallScore: row.aggregate.averageScore,
          peakScore: row.aggregate.highestScore,
        ),
      );
    }
    ranked.sort((EventLeaderboardEntry a, EventLeaderboardEntry b) => a.rank.compareTo(b.rank));
    return ranked;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventLeaderboardEntry>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<EventLeaderboardEntry>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 32));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load leaderboard: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        return EventLeaderboardSection(
          entries: snapshot.data ?? const <EventLeaderboardEntry>[],
          onOpenIdea: (EventLeaderboardEntry e) => WorkspaceNavigator.openIdea(context, e.ideaId),
          onOpenTeam: (EventLeaderboardEntry e) {
            if (e.teamId.trim().isEmpty) return;
            WorkspaceNavigator.openTeam(context, e.teamId);
          },
        );
      },
    );
  }
}
