import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../services/idea_query_service.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/common/form_value_row.dart';
import '../../../core/ui/common/mobile_row_card_pill.dart';
import 'idea_event_pills.dart';

/// Compact contextual idea feed card (workspace pills).
class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.item,
    this.onOpenIdea,
    this.onOpenTeam,
    this.onOpenEvent,
  });

  final IdeaListItem item;
  final VoidCallback? onOpenIdea;
  final VoidCallback? onOpenTeam;
  final void Function(String eventId)? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final IdeaModel idea = item.idea;
    final String ideaTitle = idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : idea.ideaTitle.trim();
    final String teamLabel = item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildIdeaTitle(ideaTitle),
          const SizedBox(height: 8),
          _buildContextPills(context, idea: idea, teamLabel: teamLabel),
        ],
      ),
    );
  }

  Widget _buildIdeaTitle(String ideaTitle) {
    if (onOpenIdea != null) {
      return EntityCardPills.workspace(
        ideaTitle,
        ContextPillSemantic.idea,
        onOpenIdea!,
        fullWidth: true,
        icon: AppIcons.ideas,
      );
    }
    return Text(
      ideaTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: EntityCardStyles.plainValue,
    );
  }

  Widget _buildContextPills(
    BuildContext context, {
    required IdeaModel idea,
    required String teamLabel,
  }) {
    final List<Widget> pills = <Widget>[
      if (onOpenTeam != null)
        EntityCardPills.workspace(teamLabel, ContextPillSemantic.team, onOpenTeam!, icon: AppIcons.teams)
      else
        EntityCardPills.meta(teamLabel, icon: AppIcons.teams),
      MobileRowCardPill.status(status: idea.status),
      IdeaEventPills(
        events: item.events,
        onOpenEvent: (event) => onOpenEvent?.call(event.eventId),
      ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pills,
    );
  }
}

