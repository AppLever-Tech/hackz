import 'package:flutter/material.dart';

import '../../features/user/models/user_model.dart';
import '../../workspace/core/workspace_navigator.dart';
import 'user_workspace_avatar.dart';

/// Avatar + plain name lead for user/judge list rows (workspace opens from avatar).
class UserListIdentityLead extends StatelessWidget {
  const UserListIdentityLead({
    super.key,
    required this.user,
    this.avatarRadius = 14,
    this.onTap,
  });

  final UserModel user;
  final double avatarRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final VoidCallback? openUser = onTap ??
        (user.userId.trim().isEmpty
            ? null
            : () => WorkspaceNavigator.openUser(context, user.userId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UserWorkspaceAvatar(
          user: user,
          radius: avatarRadius,
          onTap: openUser ?? () {},
          enabled: openUser != null,
        ),
        const SizedBox(width: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
