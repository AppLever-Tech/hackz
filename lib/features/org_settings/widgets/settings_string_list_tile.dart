import 'package:flutter/material.dart';

import '../../../shared/feedback/feedback.dart';
import 'settings_tile.dart';

class SettingsStringListTile extends StatefulWidget {
  const SettingsStringListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onCommit,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final List<String> value;
  final Future<String?> Function(List<String> next) onCommit;
  final bool loading;

  @override
  State<SettingsStringListTile> createState() => _SettingsStringListTileState();
}

class _SettingsStringListTileState extends State<SettingsStringListTile> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _commit(List<String> next) async {
    final String? err = await widget.onCommit(next);
    if (!mounted) return;
    if (err != null) {
      FeedbackService.showWarning(
        context,
        title: 'Invalid format',
        message: err,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> items = List<String>.from(widget.value);
    return SettingsTile(
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: SizedBox(
        width: 280,
        child: widget.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: items
                        .map(
                          (String s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () {
                              final next = List<String>.from(items)..remove(s);
                              _commit(next);
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Add format (e.g. png)',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (String raw) async {
                            final t = raw.trim().toLowerCase().replaceAll('.', '');
                            if (t.isEmpty) return;
                            if (items.contains(t)) {
                              _controller.clear();
                              return;
                            }
                            final next = List<String>.from(items)..add(t);
                            _controller.clear();
                            await _commit(next);
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add',
                        onPressed: () async {
                          final t = _controller.text.trim().toLowerCase().replaceAll('.', '');
                          if (t.isEmpty) return;
                          if (items.contains(t)) {
                            _controller.clear();
                            return;
                          }
                          final next = List<String>.from(items)..add(t);
                          _controller.clear();
                          await _commit(next);
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6A38FF)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
