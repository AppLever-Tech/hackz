import 'package:flutter/material.dart';

import '../../auth/widgets/signup/account_workspace_visuals.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../services/user_role_labels.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_identity_chip.dart';

/// Premium identity header for the read-only user workspace.
class UserWorkspaceIdentityHeader extends StatelessWidget {
  const UserWorkspaceIdentityHeader({super.key, required this.user});

  final UserModel user;

  static const double _desktopAvatarRadius = 80;
  static const double _tabletAvatarRadius = 70;
  static const double _mobileAvatarRadius = 58;
  static const double _desktopAvatarGap = 24;
  static const double _mobileStackGap = 16;
  static const double _nameToChipsGap = 10;

  static double _avatarRadiusForWidth(double maxWidth, {required bool compact}) {
    final double target = compact
        ? _mobileAvatarRadius
        : maxWidth < 720
            ? _tabletAvatarRadius
            : _desktopAvatarRadius;
    final double maxRadius = ((maxWidth.isFinite ? maxWidth : 420) - 12) / 2;
    return target.clamp(52, maxRadius.clamp(52, _desktopAvatarRadius));
  }

  static double _avatarCornerRadius(double radius) => (radius * 0.22).clamp(18, 24);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = ResponsiveHelper.isMobile(context) ||
            WorkspaceTheme.isCompactWidth(constraints.maxWidth);
        final String name = userDisplayName(user);
        final double radius = _avatarRadiusForWidth(constraints.maxWidth, compact: compact);
        final Widget avatar = UserAvatar(
          user: user,
          radius: radius,
          borderRadius: BorderRadius.circular(_avatarCornerRadius(radius)),
          framed: true,
        );
        final Widget info = _identityInfo(context, name, compact);

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              avatar,
              const SizedBox(height: _mobileStackGap),
              info,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            avatar,
            const SizedBox(width: _desktopAvatarGap),
            Expanded(child: info),
          ],
        );
      },
    );
  }

  Widget _identityInfo(BuildContext context, String name, bool mobile) {
    final double nameSize = mobile ? 24 : 28;
    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          name,
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: nameSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: const Color(0xFF0F172A),
            height: 1.15,
          ),
        ),
        const SizedBox(height: _nameToChipsGap),
        Wrap(
          alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            UserIdentityChip(
              icon: AppIcons.verification,
              label: AccountWorkspaceVisuals.userStatusDisplayLabel(user.status),
              fg: AccountWorkspaceVisuals.userStatusAccent(user.status),
              bg: AccountWorkspaceVisuals.chipBackgroundForUserStatus(user.status),
            ),
            UserIdentityChip(
              icon: AppIcons.forUserRoleCode(user.role),
              label: UserRoleLabels.labelForCode(user.role),
              fg: const Color(0xFF334155),
              bg: const Color(0xFFF1F5F9),
            ),
          ],
        ),
      ],
    );
  }
}
