import '../../../utils/firestore_utils.dart';
import '../../events/models/event_payment_entry.dart';
import '../../events/services/event_payments_service.dart';
import '../../organization/models/enums/organization_commercial_plan.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/services/commercial_access.dart';
import '../../organization/services/organisation_access.dart';
import '../models/ideathon_model.dart';
import '../services/ideathon_service.dart';

class IdeathonPaymentWorkspaceViewModel {
  const IdeathonPaymentWorkspaceViewModel({
    required this.event,
    required this.organisationName,
    required this.payments,
    this.commercialPlan = OrganizationCommercialPlan.perIdea,
  });

  final IdeathonModel event;
  final String organisationName;
  final EventPaymentsViewModel payments;
  final OrganizationCommercialPlan commercialPlan;

  bool get requiresIdeaPayment => CommercialAccess.requiresIdeaPayment(commercialPlan);

  List<EventPaymentEntry> get entries => payments.entries;
  EventPaymentMetrics get metrics => payments.metrics;
}

abstract final class IdeathonPaymentWorkspaceLoader {
  IdeathonPaymentWorkspaceLoader._();

  static Future<IdeathonPaymentWorkspaceViewModel> load(String ideathonId) async {
    final String id = ideathonId.trim();
    final IdeathonModel? event = await IdeathonService.fetchById(id);
    if (event == null) throw StateError('Ideathon not found.');

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      EventPaymentsService.load(kind: event.eventKind, eventId: id),
      event.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : FirestoreUtils.fetchOrganization(event.orgId),
      event.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : OrganisationAccess.fetch(event.orgId),
    ]);

    final EventPaymentsViewModel payments = parallel[0] as EventPaymentsViewModel;
    final OrganizationModel? org = parallel[1] as OrganizationModel?;
    final OrganizationModel? controlPlaneOrg = parallel[2] as OrganizationModel?;

    return IdeathonPaymentWorkspaceViewModel(
      event: event,
      organisationName: (org?.name ?? '').trim(),
      payments: payments,
      commercialPlan: CommercialAccess.planOf(controlPlaneOrg),
    );
  }
}
