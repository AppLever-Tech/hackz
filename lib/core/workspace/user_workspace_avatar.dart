import 'package:flutter/material.dart';

import '../../features/user/models/user_model.dart';
import '../../features/user/widgets/user_avatar.dart';
import '../ui/common/context_pill_theme.dart';
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
    this.semantic = ContextPillSemantic.user,
    this.allowHoverScale = true,
  });

  final UserModel user;
  final VoidCallback onTap;
  final double radius;
  final bool enabled;
  final String? tooltip;
  final double ringPadding;
  final ContextPillSemantic semantic;
  final bool allowHoverScale;

  @override
  Widget build(BuildContext context) {
    final String displayName = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final double outerRadius = radius + ringPadding;

    return ContextLaunchSurface(
      semantic: semantic,
      onTap: onTap,
      enabled: enabled,
      tooltip: tooltip,
      allowHoverScale: allowHoverScale,
      semanticsLabel: '$displayName. ${ContextPillTheme.workspaceTooltipFor(semantic)}',
      padding: EdgeInsets.all(ringPadding),
      borderRadius: BorderRadius.circular(outerRadius + 1),
      child: UserAvatar(user: user, radius: radius),
    );
  }
}
