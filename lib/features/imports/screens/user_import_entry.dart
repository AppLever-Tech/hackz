import 'package:flutter/material.dart';

import '../models/import_type.dart';
import '../services/user_import_config.dart';
import '../services/user_import_handler.dart';
import 'import_workflow_dialog.dart';

/// Shared entry point for user CSV import (Manage Department + Judges Panel).
Future<bool?> showUserImportWorkflow({
  required BuildContext context,
  required UserImportConfig config,
}) {
  return showImportWorkflow(
    context: context,
    type: ImportType.users,
    contextData: UserImportHandlerContext.fromConfig(config),
  );
}
