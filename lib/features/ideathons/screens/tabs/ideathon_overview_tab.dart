import 'package:flutter/material.dart';
import 'package:hackz/core/responsive/responsive_helper.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/events/widgets/event_detail_section.dart';
import 'package:hackz/features/events/widgets/event_labeled_field.dart';
import 'package:hackz/features/events/widgets/event_people_section.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/screens/tabs/ideathon_lifecycle_tab.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_status_pill.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_type_pill.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonOverviewTab extends StatelessWidget {
  const IdeathonOverviewTab({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final IdeathonModel event = vm.ideathon;

    final Widget detailsCard = EventDetailSection(
      title: 'Details',
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
          const SizedBox(height: 12),
          EventLabeledField(label: 'Starts', value: formatDateTime(event.startDateTime.toLocal())),
          EventLabeledField(label: 'Ends', value: formatDateTime(event.endDateTime.toLocal())),
          EventLabeledField(
            label: 'Type',
            trailing: IdeathonTypePill(type: event.ideathonType, compact: true),
          ),
          EventLabeledField(
            label: 'Status',
            trailing: IdeathonStatusPill(status: event.status, compact: true),
            isLast: true,
          ),
          const SizedBox(height: 12),
          EventLabeledField(
            label: 'Organisation',
            value: vm.organisationName.isEmpty ? event.orgId : vm.organisationName,
          ),
          EventLabeledField(label: 'Department', value: vm.departmentLabel, isLast: true),
          const SizedBox(height: 12),
          EventLabeledPill(
            label: 'Template',
            pillLabel: vm.evaluationTemplateName.isEmpty ? event.evaluationTemplateId : vm.evaluationTemplateName,
            semantic: ContextPillSemantic.evaluationTemplate,
            onTap: () => WorkspaceNavigator.openEvaluationTemplate(context, event.evaluationTemplateId),
            enabled: event.evaluationTemplateId.trim().isNotEmpty,
            isLast: true,
          ),
        ],
      ),
    );

    final Widget peopleCard = EventDetailSection(
      title: 'People',
      icon: AppIcons.users,
      child: EventPeopleSection(judges: vm.judges, coordinators: vm.coordinators),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stack = ResponsiveHelper.isMobile(context) || constraints.maxWidth < 900;
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  detailsCard,
                  const SizedBox(height: 10),
                  peopleCard,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: detailsCard),
                  const SizedBox(width: 10),
                  Expanded(child: peopleCard),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        IdeathonLifecycleTab(vm: vm, embedded: true),
      ],
    );
  }
}
