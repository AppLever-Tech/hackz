import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../shared/workspace/user_workspace_avatar.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../models/user_model.dart';
import '../../evaluations/widgets/judge_type_pill.dart';

/// Shared typography for mobile user/judge list row cards.
abstract final class MobileUserListRowStyles {
  MobileUserListRowStyles._();

  static const TextStyle name = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
    height: 1.25,
  );

  static const TextStyle meta = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
    height: 1.3,
  );
}

/// Compact two-row user card for mobile judge and user listing screens.
class MobileUserListRowCard extends StatelessWidget {
  const MobileUserListRowCard({
    super.key,
    required this.user,
    required this.trailing,
    this.showJudgeType = false,
    this.extraRow2Items = const <Widget>[],
  });

  final UserModel user;
  final List<Widget> trailing;
  final bool showJudgeType;
  final List<Widget> extraRow2Items;

  factory MobileUserListRowCard.editDelete({
    required UserModel user,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool showJudgeType = false,
    List<Widget> extraRow2Items = const <Widget>[],
  }) {
    return MobileUserListRowCard(
      user: user,
      showJudgeType: showJudgeType,
      extraRow2Items: extraRow2Items,
      trailing: <Widget>[
        MobileRowCardIconAction(
          tooltip: 'Edit',
          icon: AppIcons.edit,
          onTap: onEdit,
        ),
        MobileRowCardIconAction(
          tooltip: 'Delete',
          icon: AppIcons.remove,
          onTap: onDelete,
          foregroundColor: MobileRowCardIconActionMetrics.dangerForegroundColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final String email = user.email.trim().isEmpty ? '—' : user.email.trim();
    final String phone = user.phone.trim().isEmpty ? '—' : user.phone.trim();
    final VoidCallback? openUser = user.userId.trim().isEmpty
        ? null
        : () => WorkspaceNavigator.openUser(context, user.userId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                AppIcons.forUserRoleCode(user.role),
                size: 20,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              UserWorkspaceAvatar(
                user: user,
                radius: 16,
                ringPadding: 2,
                onTap: openUser ?? () {},
                enabled: openUser != null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MobileUserListRowStyles.name,
                ),
              ),
              if (trailing.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: spacedMobileRowCardIconActions(trailing),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _MobileUserMetaLine(icon: AppIcons.email, label: email),
              _MobileUserMetaLine(icon: AppIcons.phone, label: phone),
              if (showJudgeType)
                JudgeTypePill(judgeType: user.profile?.judgeProfile?.judgeType, compact: true),
              ...extraRow2Items,
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileUserMetaLine extends StatelessWidget {
  const _MobileUserMetaLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MobileUserListRowStyles.meta,
        ),
      ],
    );
  }
}
