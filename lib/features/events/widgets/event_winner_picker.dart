import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../models/event_winner_entry.dart';

/// Compact Department Admin picker for official winner / runner-up.
class EventWinnerPicker extends StatelessWidget {
  const EventWinnerPicker({
    super.key,
    required this.candidates,
    required this.winnerIdeaId,
    required this.runnerUpIdeaId,
    required this.onWinnerChanged,
    required this.onRunnerUpChanged,
    required this.onSave,
    this.pendingCount = 0,
    this.busy = false,
  });

  final List<EventWinnerEntry> candidates;
  final String winnerIdeaId;
  final String runnerUpIdeaId;
  final ValueChanged<String> onWinnerChanged;
  final ValueChanged<String> onRunnerUpChanged;
  final VoidCallback onSave;
  final int pendingCount;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const Text(
        'No evaluated ideas yet. Rankings appear on the Leaderboard as scores are submitted.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Select official winners',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            pendingCount > 0
                ? '$pendingCount evaluation${pendingCount == 1 ? '' : 's'} still pending. Prefer completing scoring first.'
                : 'Leaderboard ranking is informational. Official places are selected here.',
            style: const TextStyle(fontSize: 11.5, height: 1.35, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          _placeRow(
            label: 'Winner',
            value: winnerIdeaId,
            exclude: runnerUpIdeaId,
            onChanged: onWinnerChanged,
          ),
          const SizedBox(height: 8),
          _placeRow(
            label: 'Runner-up',
            value: runnerUpIdeaId,
            exclude: winnerIdeaId,
            onChanged: onRunnerUpChanged,
            optional: true,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy || winnerIdeaId.trim().isEmpty ? null : onSave,
              icon: Icon(busy ? AppIcons.clock : AppIcons.save, size: 16),
              label: Text(busy ? 'Saving…' : 'Save winners'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeRow({
    required String label,
    required String value,
    required String exclude,
    required ValueChanged<String> onChanged,
    bool optional = false,
  }) {
    final String selected = value.trim();
    final List<String> options = <String>[
      if (optional) '',
      for (final EventWinnerEntry entry in candidates)
        if (entry.ideaId != exclude || entry.ideaId == selected) entry.ideaId,
    ];
    final bool selectedKnown =
        selected.isNotEmpty && candidates.any((EventWinnerEntry e) => e.ideaId == selected);

    return HackzInputDecoration.labeledField(
      label: label,
      required: !optional,
      field: HackzSelectField<String>(
        value: selected.isEmpty ? (optional ? '' : null) : (selectedKnown ? selected : null),
        hint: optional ? 'None' : 'Choose ranked idea',
        enabled: !busy,
        compact: true,
        prefixIcon: optional ? AppIcons.starOutline : AppIcons.achievement,
        options: options,
        labelBuilder: _optionLabel,
        iconBuilder: _optionIcon,
        onChanged: onChanged,
      ),
    );
  }

  String _optionLabel(String ideaId) {
    if (ideaId.isEmpty) return 'None';
    for (final EventWinnerEntry entry in candidates) {
      if (entry.ideaId == ideaId) {
        final List<String> parts = <String>[
          if (entry.placeLabel.isNotEmpty) entry.placeLabel,
          entry.ideaTitle,
          if (entry.teamName.trim().isNotEmpty) entry.teamName.trim(),
          if (entry.scoreLabel.isNotEmpty && entry.scoreLabel != '—') entry.scoreLabel,
        ];
        return parts.join(' · ');
      }
    }
    return ideaId;
  }

  IconData _optionIcon(String ideaId) {
    if (ideaId.isEmpty) return AppIcons.remove;
    for (final EventWinnerEntry entry in candidates) {
      if (entry.ideaId != ideaId) continue;
      if (entry.rank == 1) return AppIcons.achievement;
      if (entry.rank == 2) return AppIcons.star;
      return AppIcons.ideas;
    }
    return AppIcons.ideas;
  }
}
