import 'package:flutter/material.dart';

import '../../../core/ui/dialog/app_dialog_template.dart';
import '../screens/dept_domain_management_host.dart';
import '../screens/domain_management_screen.dart';

/// Opens college-wide domain management in a compact dialog/workspace.
Future<void> showCollegeDomainManagementDialog({
  required BuildContext context,
  required String orgId,
}) {
  return showAppDialog<void>(
    context: context,
    width: DialogWidthPreset.wide,
    child: DomainManagementScreen(
      orgId: orgId,
      compact: true,
    ),
  );
}

/// Opens department-scoped domain management in a compact dialog/workspace.
Future<void> showDeptDomainManagementDialog({
  required BuildContext context,
  required String orgId,
  required String departmentCode,
  required String departmentName,
}) {
  return showAppDialog<void>(
    context: context,
    width: DialogWidthPreset.wide,
    child: DeptDomainManagementHost(
      orgId: orgId,
      departmentCode: departmentCode,
      departmentName: departmentName,
      compact: true,
    ),
  );
}
