import 'package:flutter/material.dart';

import 'settings_tile.dart';

class SettingsSegmentedChipTile extends StatelessWidget {
  const SettingsSegmentedChipTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      trailing: loading
          ? const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: List<Widget>.generate(options.length, (int i) {
                final bool sel = i == selectedIndex;
                return ChoiceChip(
                  label: Text(options[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  selected: sel,
                  onSelected: loading ? null : (_) => onSelected(i),
                  selectedColor: const Color(0xFFE8ECFF),
                  labelStyle: TextStyle(color: sel ? const Color(0xFF4F46E5) : const Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: sel ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0)),
                );
              }),
            ),
    );
  }
}
