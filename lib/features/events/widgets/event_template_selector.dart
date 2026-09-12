import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../models/event_kind.dart';

/// Event template picker for the generic Create Event flow.
class EventTemplateSelector extends StatelessWidget {
  const EventTemplateSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final EventKind value;
  final ValueChanged<EventKind> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Event Template',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        HackzSelectField<EventKind>(
          value: value,
          enabled: enabled,
          hint: 'Select event template',
          compact: true,
          prefixIcon: AppIcons.event,
          options: EventKind.values,
          labelBuilder: (EventKind kind) => kind.templateLabel,
          iconBuilder: (EventKind kind) => kind.icon,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
