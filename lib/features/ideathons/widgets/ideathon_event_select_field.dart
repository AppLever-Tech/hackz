import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../utils/common_helpers.dart';
import '../../events/widgets/event_meta_chip.dart';
import '../models/ideathon_model.dart';

/// Compact Ideathon picker: select field plus event pill, date, and time.
class IdeathonEventSelectField extends StatelessWidget {
  const IdeathonEventSelectField({
    super.key,
    required this.events,
    required this.selectedEventId,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
    this.loading = false,
    this.inline = false,
    this.showLabel = true,
    this.labelWidth = 118,
  });

  final List<IdeathonModel> events;
  final String? selectedEventId;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;
  final bool loading;
  /// When true, the Event label sits on the same row as the select field.
  final bool inline;
  /// When false, only the select field and selected-event pills are shown.
  final bool showLabel;
  final double labelWidth;

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

    final Widget select = HackzSelectField<String>(
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showLabel && inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: labelWidth,
                child: HackzInputDecoration.fieldLabel('Event', required: true),
              ),
              const SizedBox(width: 10),
              Expanded(child: select),
            ],
          )
        else if (showLabel)
          HackzInputDecoration.labeledField(
            label: 'Event',
            required: true,
            field: select,
          )
        else
          select,
        if (selected != null) ...<Widget>[
          const SizedBox(height: 8),
          Padding(
            padding: (showLabel && inline) ? EdgeInsets.only(left: labelWidth + 10) : EdgeInsets.zero,
            child: Wrap(
              spacing: 6,
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
                EventMetaChip(
                  icon: AppIcons.event,
                  label: formatShortDate(selected.startDateTime.toLocal()),
                  color: const Color(0xFF0369A1),
                ),
                EventMetaChip(
                  icon: AppIcons.clock,
                  label: formatShortTime(selected.startDateTime.toLocal()),
                  color: const Color(0xFF0369A1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
