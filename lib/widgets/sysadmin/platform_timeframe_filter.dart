import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';

class PlatformTimeframeFilter extends StatelessWidget {
  const PlatformTimeframeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlatformAnalyticsTimeframe selected;
  final ValueChanged<PlatformAnalyticsTimeframe> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: PlatformAnalyticsTimeframe.values.map((PlatformAnalyticsTimeframe timeframe) {
        final bool isSelected = timeframe == selected;
        return ChoiceChip(
          label: Text(
            timeframe.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(timeframe),
          selectedColor: const Color(0xFFEDE9FE),
          backgroundColor: const Color(0xFFF8FAFC),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
        );
      }).toList(growable: false),
    );
  }
}
