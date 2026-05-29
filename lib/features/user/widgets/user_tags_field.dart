import 'package:flutter/material.dart';

/// Comma-separated tags editor used for skills, expertise areas, etc.
class UserTagsField extends StatelessWidget {
  const UserTagsField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hintText = 'Add item and press Enter',
    this.enabled = true,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final String value in values)
              InputChip(
                label: Text(value, style: const TextStyle(fontSize: 11)),
                onDeleted: enabled ? () => onChanged(values.where((String v) => v != value).toList()) : null,
              ),
          ],
        ),
        const SizedBox(height: 6),
        _TagEntryField(
          hintText: hintText,
          enabled: enabled,
          onSubmit: (String raw) {
            final String next = raw.trim();
            if (next.isEmpty) return;
            if (values.contains(next)) return;
            onChanged(<String>[...values, next]);
          },
        ),
      ],
    );
  }
}

class _TagEntryField extends StatefulWidget {
  const _TagEntryField({
    required this.hintText,
    required this.enabled,
    required this.onSubmit,
  });

  final String hintText;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  @override
  State<_TagEntryField> createState() => _TagEntryFieldState();
}

class _TagEntryFieldState extends State<_TagEntryField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          onPressed: widget.enabled ? _submit : null,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
        ),
      ),
    );
  }
}
