import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/events/widgets/event_detail_section.dart';
import 'package:hackz/features/events/widgets/event_labeled_field.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_type.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_status_pill.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_type_pill.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonOverviewTab extends StatelessWidget {
  const IdeathonOverviewTab({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final IdeathonModel event = vm.ideathon;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        EventDetailSection(
          title: 'Event',
          icon: AppIcons.ideathons,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              if (event.description.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  event.description.trim(),
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        EventDetailSection(
          title: 'Schedule & type',
          icon: AppIcons.event,
          child: Column(
            children: <Widget>[
              EventLabeledField(label: 'Starts', value: formatDateTime(event.startDateTime.toLocal())),
              EventLabeledField(label: 'Ends', value: formatDateTime(event.endDateTime.toLocal())),
              EventLabeledField(
                label: 'Type',
                trailing: Align(
                  alignment: Alignment.centerLeft,
                  child: IdeathonTypePill(type: event.ideathonType, compact: false),
                ),
              ),
              EventLabeledField(
                label: 'Status',
                trailing: Align(
                  alignment: Alignment.centerLeft,
                  child: IdeathonStatusPill(status: event.status, compact: false),
                ),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        EventDetailSection(
          title: 'Organisation',
          icon: AppIcons.organizations,
          child: Column(
            children: <Widget>[
              EventLabeledField(
                label: 'Organisation',
                value: vm.organisationName.isEmpty ? event.orgId : vm.organisationName,
              ),
              EventLabeledField(label: 'Department', value: vm.departmentLabel, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
        EventDetailSection(
          title: 'Evaluation',
          icon: AppIcons.scoring,
          child: EventLabeledPill(
            label: 'Template',
            pillLabel: vm.evaluationTemplateName.isEmpty ? event.evaluationTemplateId : vm.evaluationTemplateName,
            semantic: ContextPillSemantic.evaluationTemplate,
            onTap: () => WorkspaceNavigator.openEvaluationTemplate(context, event.evaluationTemplateId),
            enabled: event.evaluationTemplateId.trim().isNotEmpty,
            isLast: true,
          ),
        ),
        const SizedBox(height: 10),
        EventDetailSection(
          title: 'People',
          icon: AppIcons.users,
          child: Column(
            children: <Widget>[
              EventLabeledPills(
                label: 'Coordinators',
                children: vm.coordinators.map((UserModel user) => _userPill(context, user)).toList(growable: false),
              ),
              EventLabeledPills(
                label: 'Judges',
                isLast: true,
                children: vm.judges
                    .map(
                      (UserModel user) => _userPill(context, user, semantic: ContextPillSemantic.judge),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        if (event.ideathonType == IdeathonType.external) ...<Widget>[
          const SizedBox(height: 10),
          const EventDetailSection(
            title: 'Participation',
            icon: AppIcons.ideas,
            child: Text(
              'External Ideathons include host, other-organisation, and mixed teams. Ideas below were paid and confirmed at create time.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _userPill(
    BuildContext context,
    UserModel user, {
    ContextPillSemantic semantic = ContextPillSemantic.user,
  }) {
    return ContextPill(
      label: userDisplayName(user),
      semantic: semantic,
      onTap: () => WorkspaceNavigator.openUser(context, user.userId),
      compact: true,
      fitContent: true,
    );
  }
}
