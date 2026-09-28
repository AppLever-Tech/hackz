import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../utils/common_helpers.dart';
import '../../evaluations/widgets/judge_type_pill.dart';
import '../../user/models/user_model.dart';

/// Stacked judges then coordinators, reused by Ideathon and future Hackathon.
class EventPeopleSection extends StatelessWidget {
  const EventPeopleSection({
    super.key,
    required this.judges,
    required this.coordinators,
    this.judgesTitle = 'Judges',
    this.coordinatorsTitle = 'Coordinators',
  });

  final List<UserModel> judges;
  final List<UserModel> coordinators;
  final String judgesTitle;
  final String coordinatorsTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PeopleColumn(
          title: judgesTitle,
          icon: AppIcons.judges,
          users: judges,
          semantic: ContextPillSemantic.judge,
          emptyMessage: 'No judges assigned.',
          showJudgeType: true,
        ),
        const SizedBox(height: 14),
        _PeopleColumn(
          title: coordinatorsTitle,
          icon: AppIcons.coordinator,
          users: coordinators,
          semantic: ContextPillSemantic.user,
          emptyMessage: 'No coordinators assigned.',
        ),
      ],
    );
  }
}

class _PeopleColumn extends StatelessWidget {
  const _PeopleColumn({
    required this.title,
    required this.icon,
    required this.users,
    required this.semantic,
    required this.emptyMessage,
    this.showJudgeType = false,
  });

  final String title;
  final IconData icon;
  final List<UserModel> users;
  final ContextPillSemantic semantic;
  final String emptyMessage;
  final bool showJudgeType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(width: 8),
            Text(
              '${users.length}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (users.isEmpty)
          Text(emptyMessage, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < users.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 8),
                _PersonRow(
                  user: users[i],
                  semantic: semantic,
                  showJudgeType: showJudgeType,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.user,
    required this.semantic,
    required this.showJudgeType,
  });

  final UserModel user;
  final ContextPillSemantic semantic;
  final bool showJudgeType;

  @override
  Widget build(BuildContext context) {
    final String name = userDisplayName(user);
    final bool canOpen = user.userId.trim().isNotEmpty;
    final List<Widget> meta = _metadataPills(user);

    return Row(
      children: <Widget>[
        UserWorkspaceAvatar(
          user: user,
          radius: 13,
          ringPadding: 2,
          semantic: semantic,
          allowHoverScale: false,
          enabled: canOpen,
          onTap: canOpen ? () => WorkspaceNavigator.openUser(context, user.userId) : () {},
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ),
              for (final Widget pill in meta) ...<Widget>[
                const SizedBox(width: 6),
                pill,
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _metadataPills(UserModel user) {
    final List<Widget> pills = <Widget>[];
    if (showJudgeType) {
      final type = user.profile?.judgeProfile?.judgeType;
      if (type != null) {
        pills.add(JudgeTypePill(judgeType: type, compact: true));
      }
    }
    if (user.hasExternalAffiliation) {
      pills.add(
        _PeopleMetaChip(
          icon: AppIcons.organizations,
          label: user.organisationName.trim(),
          color: const Color(0xFF0369A1),
        ),
      );
    }
    return pills;
  }
}

class _PeopleMetaChip extends StatelessWidget {
  const _PeopleMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
