import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../models/event_schedule_type.dart';

/// Day Event vs Evaluation Event picker for the generic Create Event flow.
class EventScheduleTypeSelector extends StatelessWidget {
  const EventScheduleTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final EventScheduleType value;
  final ValueChanged<EventScheduleType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Schedule Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  '${EventScheduleType.dayEvent.label}: ${EventScheduleType.dayEvent.helpText}\n'
                  '${EventScheduleType.evaluationEvent.label}: ${EventScheduleType.evaluationEvent.helpText}',
              child: const Icon(AppIcons.info, size: 16, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        HackzSelectField<EventScheduleType>(
          value: value,
          enabled: enabled,
          hint: 'Select schedule type',
          compact: true,
          prefixIcon: AppIcons.clock,
          options: EventScheduleType.values,
          labelBuilder: (EventScheduleType type) => type.label,
          iconBuilder: (EventScheduleType type) =>
              type.isEvaluationEvent ? AppIcons.scoring : AppIcons.event,
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        Text(
          value.helpText,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
