import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../evaluations/services/evaluation_settings_service.dart';
import '../../idea/models/idea_model.dart';
import '../../problems/models/problem_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import 'ideathon_details_loader.dart';
import 'ideathon_details_shell_loader.dart';
import 'ideathon_evaluation_summary_loader.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/utils/firestore_utils.dart';
import '../workspace/ideathon_workspace_loader.dart';

/// Shared evaluation data for Event Details (one fetch set per cache generation).
class EventDetailsEvaluationBundle {
  const EventDetailsEvaluationBundle({
    required this.workspace,
    required this.results,
    required this.ideaEntries,
  });

  final IdeathonWorkspaceViewModel workspace;
  final EvaluationResultsQueryResult results;
  final List<IdeathonIdeaEntry> ideaEntries;
}

abstract final class EventDetailsEvaluationBundleLoader {
  EventDetailsEvaluationBundleLoader._();

  static Future<EventDetailsEvaluationBundle> load(IdeathonDetailsShellViewModel shell) async {
    final IdeathonModel ideathon = shell.ideathon;
    final String eventId = ideathon.ideathonId.trim();
    final String orgId = ideathon.orgId.trim();
    await EvaluationSettingsService.ensureLoaded(orgId: orgId);

    final List<String> ideaIds = ideathon.ideas
        .map((IdeathonIdeaSnapshot s) => s.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toList(growable: false);

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      EvaluationAssignmentService.listByIdeathon(ideathonId: eventId),
      HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzScores)
          .where('orgId', isEqualTo: orgId)
          .where('ideathonId', isEqualTo: eventId)
          .get(),
      EvaluationResultsQueryService.loadIdeasByIds(ideaIds),
    ]);

    final List<EvaluationAssignmentModel> assignments =
        parallel[0] as List<EvaluationAssignmentModel>;
    final QuerySnapshot<Map<String, dynamic>> scores =
        parallel[1] as QuerySnapshot<Map<String, dynamic>>;
    final Map<String, IdeaModel> ideasById = parallel[2] as Map<String, IdeaModel>;

    final Set<String> problemIds = <String>{
      for (final IdeaModel idea in ideasById.values)
        if (idea.problemId.trim().isNotEmpty) idea.problemId.trim(),
    };
    final Map<String, ProblemModel> problems =
        await EvaluationResultsQueryService.loadProblemsByIds(orgId: orgId, problemIds: problemIds);

    final EvaluationResultsQueryResult results = EvaluationResultsQueryService.composeIdeathonResults(
      params: EvaluationResultsQueryParams(ideathonId: eventId),
      ideathon: ideathon,
      assignments: assignments,
      scoresSnap: scores,
      ideasById: ideasById,
      problems: problems,
    );

    final IdeathonWorkspaceViewModel workspace = IdeathonEvaluationSummaryLoader.buildWorkspace(
      ideathon: ideathon,
      assignments: assignments,
      scores: scores,
      commercialPlan: shell.commercialPlan,
      organisationName: shell.organisationName,
    );

    final List<IdeathonIdeaEntry> ideaEntries = <IdeathonIdeaEntry>[
      for (final IdeathonIdeaSnapshot snapshot in ideathon.ideas)
        IdeathonIdeaEntry(
          snapshot: snapshot,
          idea: ideasById[snapshot.ideaId.trim()],
        ),
    ];

    return EventDetailsEvaluationBundle(
      workspace: workspace,
      results: results,
      ideaEntries: ideaEntries,
    );
  }
}
