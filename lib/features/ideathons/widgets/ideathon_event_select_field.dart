import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../utils/common_helpers.dart';
import '../models/ideathon_model.dart';

/// Compact Ideathon picker: select field plus event pill and date.
class IdeathonEventSelectField extends StatelessWidget {
  const IdeathonEventSelectField({
    super.key,
    required this.events,
    required this.selectedEventId,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
    this.loading = false,
  });

  final List<IdeathonModel> events;
  final String? selectedEventId;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;
  final bool loading;

  IdeathonModel? get _selected {
    final String id = (selectedEventId ?? '').trim();
    if (id.isEmpty) return null;
    for (final IdeathonModel event in events) {
      if (event.ideathonId.trim() == id) return event;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final IdeathonModel? selected = _selected;
    final bool canSelect = enabled && !loading && events.isNotEmpty;
    final String hint = loading
        ? 'Loading events…'
        : (events.isEmpty ? 'No eligible events' : 'Select an Ideathon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HackzInputDecoration.labeledField(
          label: 'Event',
          required: true,
          field: HackzSelectField<String>(
            value: selected?.ideathonId,
            options: events.map((IdeathonModel e) => e.ideathonId).toList(growable: false),
            labelBuilder: (String id) {
              for (final IdeathonModel event in events) {
                if (event.ideathonId == id) return event.name.trim().isEmpty ? id : event.name.trim();
              }
              return id;
            },
            onChanged: onChanged,
            hint: hint,
            enabled: canSelect,
            compact: true,
            prefixIcon: AppIcons.ideathons,
            errorText: errorText,
          ),
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ContextPill(
                label: selected.name.trim().isEmpty ? selected.ideathonId : selected.name.trim(),
                semantic: ContextPillSemantic.event,
                icon: AppIcons.ideathons,
                onTap: () {},
                enabled: false,
                compact: true,
                fitContent: true,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(AppIcons.event, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    formatShortDate(selected.startDateTime.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
