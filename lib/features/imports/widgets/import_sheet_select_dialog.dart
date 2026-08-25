import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';

/// Compact sheet picker used when an Excel workbook has more than one usable sheet.
Future<String?> showImportSheetSelectDialog({
  required BuildContext context,
  required List<String> sheetNames,
  String? initialSheet,
}) {
  if (sheetNames.isEmpty) return Future<String?>.value(null);
  return showAppDialog<String>(
    context: context,
    barrierDismissible: true,
    width: DialogWidthPreset.compact,
    child: _ImportSheetSelectBody(
      sheetNames: sheetNames,
      initialSheet: initialSheet ?? sheetNames.first,
    ),
  );
}

class _ImportSheetSelectBody extends StatefulWidget {
  const _ImportSheetSelectBody({
    required this.sheetNames,
    required this.initialSheet,
  });

  final List<String> sheetNames;
  final String initialSheet;

  @override
  State<_ImportSheetSelectBody> createState() => _ImportSheetSelectBodyState();
}

class _ImportSheetSelectBodyState extends State<_ImportSheetSelectBody> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.sheetNames.contains(widget.initialSheet)
        ? widget.initialSheet
        : widget.sheetNames.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(AppIcons.spreadsheet, size: 18, color: Color(0xFF334155)),
            SizedBox(width: 8),
            Text(
              'Select Sheet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'This workbook has multiple sheets. Continue with one sheet only.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: RadioGroup<String>(
            groupValue: _selected,
            onChanged: (String? value) {
              if (value == null) return;
              setState(() => _selected = value);
            },
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.sheetNames.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (BuildContext context, int index) {
                final String name = widget.sheetNames[index];
                return RadioListTile<String>(
                  value: name,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}
