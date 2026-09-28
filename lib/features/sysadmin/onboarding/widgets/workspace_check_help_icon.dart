import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_alert_dialog.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../core/theme/app_icons.dart';
import '../services/tenant_workspace_validator.dart';

/// Info for one workspace check: hover tooltip and tap shows the same single-check help.
class WorkspaceCheckHelpIcon extends StatelessWidget {
  const WorkspaceCheckHelpIcon({super.key, required this.checkId});

  final String checkId;

  @override
  Widget build(BuildContext context) {
    final TenantWorkspaceCheckGuideEntry? guide = TenantWorkspaceValidator.guideForCheckId(checkId);
    if (guide == null) return const SizedBox.shrink();

    return Tooltip(
      message: guide.validates,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHelp(context, guide),
        child: const Padding(
          padding: EdgeInsets.all(2),
          child: Icon(AppIcons.info, size: 16, color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Future<void> _showHelp(BuildContext context, TenantWorkspaceCheckGuideEntry guide) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ResponsiveAlertDialog(
          title: Text(guide.label),
          widthPreset: DialogWidthPreset.compact,
          content: Text(
            guide.validates,
            style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
          ),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }
}
