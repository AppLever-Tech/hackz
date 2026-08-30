import '../../events/models/event_kind.dart';
import '../../events/widgets/event_workspace_header.dart';
import '../models/ideathon_model.dart';
import 'ideathon_status_pill.dart';
import 'ideathon_type_pill.dart';

/// Ideathon binding for [EventWorkspaceHeader] so event workspaces share one header.
EventWorkspaceHeader ideathonEventWorkspaceHeader({
  required IdeathonModel event,
  required String organisationName,
}) {
  return EventWorkspaceHeader(
    kind: EventKind.ideathon,
    name: event.name,
    description: event.description,
    startDateTime: event.startDateTime,
    endDateTime: event.endDateTime,
    organisationName: organisationName,
    entryCount: event.ideaCount,
    typePill: IdeathonTypePill(type: event.ideathonType, compact: true),
    statusPill: IdeathonStatusPill(status: event.status, compact: true),
  );
}
