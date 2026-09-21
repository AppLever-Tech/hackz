import '../../evaluations/services/evaluation_results_query_service.dart';
import '../workspace/ideathon_workspace_loader.dart';
import 'event_details_evaluation_bundle.dart';
import 'event_details_tab_cache.dart';
import 'ideathon_details_loader.dart';
import 'ideathon_details_shell_loader.dart';

/// Cached evaluation bundle access for Event Details panes and tabs.
abstract final class EventDetailsEvaluationAccess {
  EventDetailsEvaluationAccess._();

  static Future<EventDetailsEvaluationBundle> bundle(
    EventDetailsTabCacheBucket cache,
    IdeathonDetailsShellViewModel shell,
  ) {
    return cache.getOrLoad<EventDetailsEvaluationBundle>(
      EventDetailsTabKeys.evaluationBundle,
      () => EventDetailsEvaluationBundleLoader.load(shell),
    );
  }

  static Future<IdeathonWorkspaceViewModel> workspace(
    EventDetailsTabCacheBucket cache,
    IdeathonDetailsShellViewModel shell,
  ) async {
    return (await bundle(cache, shell)).workspace;
  }

  static Future<EvaluationResultsQueryResult> unfilteredResults(
    EventDetailsTabCacheBucket cache,
    IdeathonDetailsShellViewModel shell,
  ) async {
    return (await bundle(cache, shell)).results;
  }

  static Future<List<IdeathonIdeaEntry>> ideaEntries(
    EventDetailsTabCacheBucket cache,
    IdeathonDetailsShellViewModel shell,
  ) async {
    return (await bundle(cache, shell)).ideaEntries;
  }
}
