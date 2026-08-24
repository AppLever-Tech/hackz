import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/features/events/models/event_report_item.dart';
import 'package:hackz/features/events/widgets/event_reports_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonReportsTab extends StatefulWidget {
  const IdeathonReportsTab({
    super.key,
    required this.vm,
    required this.actor,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  State<IdeathonReportsTab> createState() => _IdeathonReportsTabState();
}

class _IdeathonReportsTabState extends State<IdeathonReportsTab> {
  late Future<({bool winner, bool runnerUp})> _ranks;

  @override
  void initState() {
    super.initState();
    _ranks = _loadRanks();
  }

  Future<({bool winner, bool runnerUp})> _loadRanks() async {
    try {
      final EvaluationResultsQueryResult result = await EvaluationResultsQueryService.fetch(
        EvaluationResultsQueryParams(
          viewer: widget.actor,
          ideathonId: widget.vm.ideathon.ideathonId,
        ),
      );
      var winner = false;
      var runnerUp = false;
      for (final row in result.rows) {
        if (!row.evaluationComplete) continue;
        if (row.rank == 1) winner = true;
        if (row.rank == 2) runnerUp = true;
      }
      return (winner: winner, runnerUp: runnerUp);
    } catch (_) {
      return (winner: false, runnerUp: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({bool winner, bool runnerUp})>(
      future: _ranks,
      builder: (BuildContext context, AsyncSnapshot<({bool winner, bool runnerUp})> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 32));
        }
        final bool hasIdeas = widget.vm.ideas.isNotEmpty;
        final bool hasWinner = snapshot.data?.winner ?? false;
        final bool hasRunnerUp = snapshot.data?.runnerUp ?? false;
        return EventReportsSection(
          items: <EventReportItem>[
            EventReportItem(
              id: 'participation',
              title: 'Participation e-certificates',
              description: 'Certificates for ideas registered in this event.',
              icon: AppIcons.ideas,
              available: hasIdeas,
              unavailableReason: 'Add participating ideas before generating certificates.',
              onDownload: () => _unavailable(context, 'Participation e-certificates'),
            ),
            EventReportItem(
              id: 'winner',
              title: 'Winner certificates',
              description: 'Certificates for the top-ranked idea from evaluation results.',
              icon: AppIcons.achievement,
              available: hasWinner,
              unavailableReason: 'Winner certificates are available after evaluation results include a rank-1 idea.',
              onDownload: () => _unavailable(context, 'Winner certificates'),
            ),
            EventReportItem(
              id: 'runnerUp',
              title: 'Runner-up certificates',
              description: 'Certificates for the second-ranked idea from evaluation results.',
              icon: AppIcons.results,
              available: hasRunnerUp,
              unavailableReason: 'Runner-up certificates are available after evaluation results include a rank-2 idea.',
              onDownload: () => _unavailable(context, 'Runner-up certificates'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _unavailable(BuildContext context, String title) {
    return FeedbackService.showInfo(
      context,
      title: title,
      message:
          'Certificate templates are not configured for this organisation yet. The Reports module is ready for Hackathon reuse once generation is enabled.',
    );
  }
}
