import '../../../utils/firestore_utils.dart';
import '../../events/models/event_kind.dart';
import '../../events/models/event_payment_entry.dart';
import '../../events/services/event_payments_service.dart';
import '../../organization/models/organization_model.dart';
import '../models/ideathon_model.dart';
import '../services/ideathon_service.dart';

class IdeathonPaymentWorkspaceViewModel {
  const IdeathonPaymentWorkspaceViewModel({
    required this.event,
    required this.organisationName,
    required this.payments,
  });

  final IdeathonModel event;
  final String organisationName;
  final EventPaymentsViewModel payments;

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
      EventPaymentsService.load(kind: EventKind.ideathon, eventId: id),
      event.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : FirestoreUtils.fetchOrganization(event.orgId),
    ]);

    final EventPaymentsViewModel payments = parallel[0] as EventPaymentsViewModel;
    final OrganizationModel? org = parallel[1] as OrganizationModel?;

    return IdeathonPaymentWorkspaceViewModel(
      event: event,
      organisationName: (org?.name ?? '').trim(),
      payments: payments,
    );
  }
}
