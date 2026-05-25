import 'package:flutter/material.dart';

/// Premium multiline text field used by authoring sections.
class AuthoringTextArea extends StatelessWidget {
  const AuthoringTextArea({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helperPrompts = const <String>[],
    this.minLines = 3,
    this.maxLines = 6,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> helperPrompts;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
            letterSpacing: 0.1,
          ),
        ),
        if (helperPrompts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: helperPrompts
                .map(
                  (String prompt) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, height: 1.4),
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact single-line text input (premium style) used for links / contact / theme.
class AuthoringTextField extends StatelessWidget {
  const AuthoringTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip selector — supports free-text entry and optional preset suggestions.
class AuthoringChipInput extends StatefulWidget {
  const AuthoringChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.suggestions = const <String>[],
    this.enabled = true,
  });

  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;
  final bool enabled;

  @override
  State<AuthoringChipInput> createState() => _AuthoringChipInputState();
}

class _AuthoringChipInputState extends State<AuthoringChipInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (widget.values.any((v) => v.toLowerCase() == value.toLowerCase())) {
      _controller.clear();
      return;
    }
    widget.onChanged(<String>[...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> remainingSuggestions = widget.suggestions
        .where((String s) => !widget.values.any((v) => v.toLowerCase() == s.toLowerCase()))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onSubmitted: _add,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFFCFDFF),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: widget.enabled ? () => _add(_controller.text) : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4338CA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        if (remainingSuggestions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'Suggestions',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: remainingSuggestions
                .map(
                  (String s) => InkWell(
                    onTap: widget.enabled ? () => _add(s) : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        border: Border.all(color: const Color(0xFFD9E2F5)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.add, size: 13, color: Color(0xFF6A38FF)),
                          const SizedBox(width: 4),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (widget.values.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.values
                .map(
                  (String v) => Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFF6F3FF),
                    side: const BorderSide(color: Color(0xFFD9D3FF)),
                    label: Text(
                      v,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    deleteIconColor: const Color(0xFF6A38FF),
                    onDeleted: widget.enabled ? () => _remove(v) : null,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

/// Single-select chip group (Difficulty / Complexity / Category).
class AuthoringChoiceChips extends StatelessWidget {
  const AuthoringChoiceChips({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((String option) {
            final bool isSelected = option == selected;
            return InkWell(
              onTap: enabled ? () => onChanged(isSelected ? '' : option) : null,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6A38FF) : const Color(0xFFF8FAFF),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6A38FF) : const Color(0xFFD9E2F5),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

/// Dynamic list of link rows (used by reference links).
class AuthoringLinkList extends StatefulWidget {
  const AuthoringLinkList({
    super.key,
    required this.values,
    required this.onChanged,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final String hint;
  final bool enabled;

  @override
  State<AuthoringLinkList> createState() => _AuthoringLinkListState();
}

class _AuthoringLinkListState extends State<AuthoringLinkList> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (widget.values.contains(value)) {
      _controller.clear();
      return;
    }
    widget.onChanged(<String>[...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                onSubmitted: _add,
                keyboardType: TextInputType.url,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFFCFDFF),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: widget.enabled ? () => _add(_controller.text) : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add link'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4338CA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Column(
            children: widget.values
                .map(
                  (String link) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        border: Border.all(color: const Color(0xFFD9E2F5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.link_rounded, size: 16, color: Color(0xFF6A38FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove link',
                            onPressed: widget.enabled ? () => _remove(link) : null,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

/// Two-column row that stacks below [breakpoint].
class AuthoringPairRow extends StatelessWidget {
  const AuthoringPairRow({
    super.key,
    required this.first,
    required this.second,
    this.spacing = 12,
    this.breakpoint = 560,
  });

  final Widget first;
  final Widget second;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: first),
            SizedBox(width: spacing),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
