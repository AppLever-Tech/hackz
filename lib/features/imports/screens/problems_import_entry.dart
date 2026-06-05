import 'package:flutter/material.dart';

import '../models/import_type.dart';
import '../services/import_handler.dart';
import 'import_workflow_dialog.dart';

/// Entry point for problem CSV import from Problem Management.
Future<bool?> showProblemsImportWorkflow({
  required BuildContext context,
  required String actorUserId,
  required String orgId,
  required String defaultDepartmentName,
  required String defaultDepartmentCode,
}) {
  return showImportWorkflow(
    context: context,
    type: ImportType.problems,
    contextData: ImportHandlerContext(
      actorUserId: actorUserId,
      orgId: orgId,
      defaultDepartmentName: defaultDepartmentName,
      defaultDepartmentCode: defaultDepartmentCode,
    ),
  );
}
