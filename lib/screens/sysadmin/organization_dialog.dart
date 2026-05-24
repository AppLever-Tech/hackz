import 'package:flutter/material.dart';

import '../common/app_dialog_template.dart';
import 'create_org_screen.dart';

Future<bool> showOrganizationDialog({
  required BuildContext context,
}) async {
  final created = await showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.wide,
    child: const CreateOrganizationDialogForm(asDialog: true),
  );
  return created ?? false;
}
