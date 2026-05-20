import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import 'workspace_controller.dart';
import 'workspace_navigator.dart';
import 'workspace_theme.dart';

/// Premium elevated surface wrapping [WorkspaceNavigator].
class WorkspaceContainer extends StatelessWidget {
  const WorkspaceContainer({
    super.key,
    required this.controller,
    required this.isMobile,
  });

  final WorkspaceController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: isMobile
          ? const BorderRadius.vertical(top: Radius.circular(WorkspaceTheme.mobileTopRadius))
          : const BorderRadius.horizontal(left: Radius.circular(WorkspaceTheme.panelRadius)),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: WorkspaceTheme.panelDecoration(isMobile: isMobile),
          child: WorkspaceNavigator(controller: controller),
        ),
      ),
    );
  }
}

/// Resolves mobile vs desktop presentation for [WorkspaceHost].
bool workspaceUseMobileSheet(BuildContext context) =>
    ResponsiveHelper.isMobile(context);
