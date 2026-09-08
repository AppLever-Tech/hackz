import '../../user/models/user_model.dart';
import 'export_format.dart';
import 'export_module.dart';

/// One export run. Tenant identity comes from [HackzFirebase.current], not a
/// `tenantId` field on this request or on business models.
class ExportRequest {
  const ExportRequest({
    required this.module,
    required this.format,
    required this.actor,
    this.eventId = '',
    this.eventName = '',
    this.filters = const <String, Object?>{},
  });

  final ExportModule module;
  final ExportFormat format;
  final UserModel actor;

  /// Existing event id (Ideathon today). Empty when the module is not event-scoped.
  final String eventId;
  final String eventName;

  /// Opaque filter snapshot from the calling workspace (search, status, …).
  final Map<String, Object?> filters;

  bool get hasEventScope => eventId.trim().isNotEmpty;
}
