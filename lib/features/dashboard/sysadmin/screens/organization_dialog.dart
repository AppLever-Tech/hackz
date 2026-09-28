import 'package:flutter/material.dart';

import '../../../../features/organization/models/organization_model.dart';
import 'create_org_screen.dart';

Future<bool> showOrganizationDialog({
  required BuildContext context,
  OrganizationModel? initialOrganization,
}) async {
  final bool? created = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return CreateOrganizationDialogForm(
        asDialog: true,
        initialOrganization: initialOrganization,
      );
    },
  );
  return created ?? false;
}
