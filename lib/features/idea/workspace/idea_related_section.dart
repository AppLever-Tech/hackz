import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/idea_event_participation_summary.dart';
import '../widgets/idea_event_pills.dart';
import 'idea_workspace.dart';
import 'idea_workspace_loader.dart';

class IdeaRelatedSection extends StatelessWidget {
  const IdeaRelatedSection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final List<IdeaEventParticipationSummary> events = vm.eventParticipations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(AppIcons.ideathons, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              'Event participation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          const Text(
            'This idea has not participated in an event yet.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          )
        else
          ...events.map(
            (IdeaEventParticipationSummary event) => IdeaEventParticipationRow(
              event: event,
              onOpenEvent: () => IdeaWorkspace.openEvent(context, event.eventId),
            ),
          ),
      ],
    );
  }
}
