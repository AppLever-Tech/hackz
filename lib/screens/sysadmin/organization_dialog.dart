import 'package:flutter/material.dart';

import '../common/app_dialog_template.dart';
import 'create_org_screen.dart';

Future<bool> showOrganizationDialog({
  required BuildContext context,
}) async {
  final created = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return const AppDialogTemplate(
        child: CreateOrganizationDialogForm(asDialog: true),
      );
    },
  );
  return created ?? false;
}
