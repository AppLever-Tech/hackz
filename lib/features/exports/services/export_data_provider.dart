import '../../user/models/user_model.dart';
import '../models/export_format.dart';
import '../models/export_module.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';

/// Module adapter: load the rows the current user can already see.
abstract class ExportDataProvider {
  ExportModule get module;

  List<ExportFormat> get supportedFormats;

  /// When true, [ExportRequest.eventId] must be set.
  bool get requiresEvent => false;

  bool canExport(UserModel actor);

  Future<ExportTable> load(ExportRequest request);
}
