import 'package:flutter/material.dart';

import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../evaluations/widgets/judge_type_pill.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';

/// Compact single-line selectable judge/coordinator row for ideathon creation.
class IdeathonAssigneeSelectRow extends StatelessWidget {
  const IdeathonAssigneeSelectRow({
    super.key,
    required this.user,
    required this.selected,
    required this.onToggle,
    this.leadingIcon,
    this.showJudgeType = false,
  });

  final UserModel user;
  final bool selected;
  final VoidCallback onToggle;
  final IconData? leadingIcon;
  final bool showJudgeType;

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final String roleLabel = UserRoleLabels.labelForCode(user.role);
    final bool canOpenUser = user.userId.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
          width: selected ? 1.3 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: selected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => onToggle(),
            ),
          ),
          if (leadingIcon != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(leadingIcon, size: 15, color: const Color(0xFF64748B)),
          ],
          const SizedBox(width: 6),
          UserWorkspaceAvatar(
            user: user,
            radius: 13,
            ringPadding: 1.5,
            enabled: canOpenUser,
            onTap: canOpenUser ? () => WorkspaceNavigator.openUser(context, user.userId) : () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _RoleBadge(label: roleLabel),
                if (showJudgeType) ...<Widget>[
                  const SizedBox(width: 4),
                  JudgeTypePill(judgeType: user.profile?.judgeProfile?.judgeType, compact: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
