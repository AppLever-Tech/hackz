import '../models/import_type.dart';
import 'import_handler.dart';
import 'problems_import_handler.dart';
import 'team_registration_import_handler.dart';
import 'user_import_handler.dart';

/// Resolves [ImportHandler] implementations by [ImportType].
abstract final class ImportRegistry {
  static ImportHandler handlerFor(ImportType type) {
    return switch (type) {
      ImportType.users => UserImportHandler(),
      ImportType.problems => ProblemsImportHandler(),
      ImportType.teamRegistration => TeamRegistrationImportHandler(),
    };
  }
}
