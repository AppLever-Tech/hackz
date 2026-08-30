import '../../ideathons/services/ideathon_payment_service.dart';
import '../../user/models/user_model.dart';
import '../models/event_kind.dart';
import '../models/event_payment_entry.dart';

/// Event Payments dispatcher: Ideathon today, Hackathon later.
///
/// Payment documents stay on the shared [PaymentModel]. This service only
/// loads and mutates rows whose `ideathonId` / event id matches [eventId].
abstract final class EventPaymentsService {
  EventPaymentsService._();

  static Future<EventPaymentsViewModel> load({
    required EventKind kind,
    required String eventId,
  }) {
    final String id = eventId.trim();
    if (id.isEmpty) throw ArgumentError('eventId must be non-empty');
    return switch (kind) {
      EventKind.ideathon => IdeathonPaymentService.load(id),
      EventKind.hackathon => Future<EventPaymentsViewModel>.value(
          EventPaymentsViewModel.empty(eventId: id, kind: kind),
        ),
    };
  }

  static Future<void> confirm({
    required EventKind kind,
    required String eventId,
    required EventPaymentEntry entry,
    required UserModel actor,
  }) {
    return switch (kind) {
      EventKind.ideathon => IdeathonPaymentService.confirm(
          eventId: eventId,
          entry: entry,
          actor: actor,
        ),
      EventKind.hackathon => Future<void>.error(
          StateError('Hackathon payments are not available yet.'),
        ),
    };
  }

  static Future<void> markException({
    required EventKind kind,
    required String eventId,
    required EventPaymentEntry entry,
    required UserModel actor,
    String? remarks,
  }) {
    return switch (kind) {
      EventKind.ideathon => IdeathonPaymentService.markException(
          eventId: eventId,
          entry: entry,
          actor: actor,
          remarks: remarks,
        ),
      EventKind.hackathon => Future<void>.error(
          StateError('Hackathon payments are not available yet.'),
        ),
    };
  }

  static bool actorCanManage(UserModel? actor) => IdeathonPaymentService.actorCanManage(actor);
}
