import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/ideathon_type.dart';

/// Compact Internal / External selector used on Ideathon creation.
class IdeathonTypeSelector extends StatelessWidget {
  const IdeathonTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final IdeathonType value;
  final ValueChanged<IdeathonType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Ideathon type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  '${IdeathonType.internal.label}: ${IdeathonType.internal.helpText}\n'
                  '${IdeathonType.external.label}: ${IdeathonType.external.helpText}',
              child: const Icon(AppIcons.info, size: 16, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<IdeathonType>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<IdeathonType>>[
              ButtonSegment<IdeathonType>(
                value: IdeathonType.internal,
                label: Text('Internal'),
              ),
              ButtonSegment<IdeathonType>(
                value: IdeathonType.external,
                label: Text('External'),
              ),
            ],
            selected: <IdeathonType>{value},
            onSelectionChanged: (Set<IdeathonType> next) {
              if (next.isEmpty) return;
              onChanged(next.first);
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.helpText,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.35),
        ),
      ],
    );
  }
}
