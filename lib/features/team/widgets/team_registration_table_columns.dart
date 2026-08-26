import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../utils/common_helpers.dart';
import '../../ideathons/widgets/ideathon_type_pill.dart';
import '../services/coordinator_team_registration_service.dart';

abstract final class TeamRegistrationTableColumns {
  TeamRegistrationTableColumns._();

  static List<DataTableColumn<CoordinatorTeamRegistrationRow>> build() {
    return <DataTableColumn<CoordinatorTeamRegistrationRow>>[
      DataTableColumn<CoordinatorTeamRegistrationRow>(
        label: 'Team',
        flex: 3,
        minWidth: 168,
        cell: (BuildContext context, CoordinatorTeamRegistrationRow row) {
          final String name = row.team.teamName.trim().isEmpty ? 'Team' : row.team.teamName.trim();
          final String teamId = row.team.teamId.trim();
          final Widget pill = teamId.isEmpty
              ? EntityCardPills.meta(name, icon: AppIcons.teams)
              : EntityCardPills.workspace(
                  name,
                  ContextPillSemantic.team,
                  () => WorkspaceNavigator.openTeam(context, teamId),
                  icon: AppIcons.teams,
                );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pill,
          );
        },
      ),
      DataTableColumn<CoordinatorTeamRegistrationRow>(
        label: 'Type',
        flex: 2,
        minWidth: 100,
        cell: (BuildContext context, CoordinatorTeamRegistrationRow row) =>
            IdeathonTypePill(type: row.originType),
      ),
      DataTableColumn<CoordinatorTeamRegistrationRow>(
        label: 'Ideathon',
        flex: 3,
        minWidth: 160,
        cell: (BuildContext context, CoordinatorTeamRegistrationRow row) {
          final String name = row.ideathonName.trim();
          if (name.isEmpty) return const SizedBox.shrink();
          final String eventId = row.ideathonId.trim();
          final Widget pill = eventId.isEmpty
              ? EntityCardPills.meta(name, icon: AppIcons.ideathons)
              : EntityCardPills.workspace(
                  name,
                  ContextPillSemantic.generic,
                  () => WorkspaceNavigator.openIdeathon(context, eventId),
                  icon: AppIcons.ideathons,
                );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pill,
          );
        },
      ),
      DataTableColumn<CoordinatorTeamRegistrationRow>(
        label: 'Date imported',
        flex: 2,
        minWidth: 128,
        cell: (BuildContext context, CoordinatorTeamRegistrationRow row) =>
            EntityCardPills.plainValue(formatDayMonthYear(row.importedAt)),
      ),
    ];
  }
}
