import '../../../utils/firestore_utils.dart';
import '../../evaluations/services/evaluation_ranking_service.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../organization/models/organization_model.dart';
import '../models/ideathon_model.dart';
import '../services/ideathon_service.dart';

class IdeathonResultsWorkspaceViewModel {
  const IdeathonResultsWorkspaceViewModel({
    required this.event,
    required this.organisationName,
    required this.results,
  });

  final IdeathonModel event;
  final String organisationName;
  final EvaluationResultsQueryResult results;

  List<EvaluationResultsRow> get rows => results.rows;
  EvaluationResultsMetrics get metrics => results.metrics;
}

abstract final class IdeathonResultsWorkspaceLoader {
  IdeathonResultsWorkspaceLoader._();

  static Future<IdeathonResultsWorkspaceViewModel> load(String ideathonId) async {
    final String id = ideathonId.trim();
    final IdeathonModel? event = await IdeathonService.fetchById(id);
    if (event == null) throw StateError('Ideathon not found.');

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      EvaluationResultsQueryService.fetch(
        EvaluationResultsQueryParams(ideathonId: id),
      ),
      event.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : FirestoreUtils.fetchOrganization(event.orgId),
    ]);

    final EvaluationResultsQueryResult results = parallel[0] as EvaluationResultsQueryResult;
    final OrganizationModel? org = parallel[1] as OrganizationModel?;

    return IdeathonResultsWorkspaceViewModel(
      event: event,
      organisationName: (org?.name ?? '').trim(),
      results: results,
    );
  }
}
