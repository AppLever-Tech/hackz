import 'package:flutter/material.dart';

import '../../../core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/workspace/entity_reference_tile.dart';
import '../models/idea_event_participation_summary.dart';
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
        const Text(
          'Event participation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          const Text(
            'This idea has not participated in an event yet.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          )
        else
          ...events.map(
            (IdeaEventParticipationSummary event) => EntityReferenceTile(
              category: 'Event',
              headline: event.eventName,
              detail: [
                event.paymentLabel,
                event.evaluationLabel,
                if (event.scoreLabel != null) event.scoreLabel!,
              ].join(' · '),
              semantic: ContextPillSemantic.event,
              onOpenWorkspace: () => IdeaWorkspace.openEvent(context, event.eventId),
            ),
          ),
      ],
    );
  }
}
