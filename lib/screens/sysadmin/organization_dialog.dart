import 'package:flutter/material.dart';

import '../../models/organization_model.dart';
import '../common/app_dialog_template.dart';
import 'create_org_screen.dart';

Future<bool> showOrganizationDialog({
  required BuildContext context,
  OrganizationModel? initialOrganization,
}) async {
  final created = await showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.wide,
    child: CreateOrganizationDialogForm(
      asDialog: true,
      initialOrganization: initialOrganization,
    ),
  );
  return created ?? false;
}
