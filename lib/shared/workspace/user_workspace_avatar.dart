import 'package:flutter/material.dart';

import '../../features/user/models/user_model.dart';
import '../../features/user/widgets/user_avatar.dart';
import '../../core/ui/common/context_pill_theme.dart';
import 'context_launch_surface.dart';

/// Clickable user avatar that opens the user workspace with context-pill hover styling.
class UserWorkspaceAvatar extends StatelessWidget {
  const UserWorkspaceAvatar({
    super.key,
    required this.user,
    required this.onTap,
    this.radius = 16,
    this.enabled = true,
    this.tooltip,
    this.ringPadding = 2,
  });

  final UserModel user;
  final VoidCallback onTap;
  final double radius;
  final bool enabled;
  final String? tooltip;
  final double ringPadding;

  @override
  Widget build(BuildContext context) {
    final String displayName = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final double outerRadius = radius + ringPadding;

    return ContextLaunchSurface(
      semantic: ContextPillSemantic.user,
      onTap: onTap,
      enabled: enabled,
      tooltip: tooltip,
      semanticsLabel: '$displayName. ${ContextPillTheme.workspaceTooltipFor(ContextPillSemantic.user)}',
      padding: EdgeInsets.all(ringPadding),
      borderRadius: BorderRadius.circular(outerRadius + 1),
      child: UserAvatar(user: user, radius: radius),
    );
  }
}
