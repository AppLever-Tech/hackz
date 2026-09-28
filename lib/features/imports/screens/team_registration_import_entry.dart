import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import '../models/import_type.dart';
import '../services/team_registration_import_handler.dart';
import 'import_workflow_dialog.dart';

/// Coordinator entry point for Team Registration CSV import.
Future<bool?> showTeamRegistrationImportWorkflow({
  required BuildContext context,
  required UserModel actor,
  required String orgName,
}) {
  return showImportWorkflow(
    context: context,
    type: ImportType.teamRegistration,
    contextData: TeamRegistrationImportHandlerContext(
      actor: actor,
      orgName: orgName,
    ),
  );
}
