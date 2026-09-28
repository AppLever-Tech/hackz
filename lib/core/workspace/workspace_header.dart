import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../features/docs/widgets/help_action_button.dart';
import 'workspace_theme.dart';

/// Workspace chrome: internal back, title, optional Help, close.
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.onClose,
    this.helpPageId,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final String? helpPageId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WorkspaceTheme.divider)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: showBack
                ? IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(AppIcons.back, size: 22),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkspaceTheme.titleStyle,
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkspaceTheme.subtitleStyle,
                  ),
                ],
              ],
            ),
          ),
          if (helpPageId != null) HelpActionButton(pageId: helpPageId),
          IconButton(
            tooltip: 'Close workspace',
            onPressed: onClose,
            icon: const Icon(AppIcons.remove, size: 22),
          ),
        ],
      ),
    );
  }
}
