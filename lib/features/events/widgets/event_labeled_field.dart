import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';

/// Name/value row used in Event Overview, matching Problem/Idea details.
class EventLabeledField extends StatelessWidget {
  const EventLabeledField({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
    this.labelWidth,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;
  /// When set, used instead of the default 96 / 124 label column.
  final double? labelWidth;

  @override
  Widget build(BuildContext context) {
    final double labelWidth =
        this.labelWidth ?? (ResponsiveHelper.isMobile(context) ? 96 : 124);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 2 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: trailing != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 34),
                    child: Align(alignment: Alignment.centerLeft, child: trailing),
                  )
                : Text(
                    (value ?? '').trim().isEmpty ? '—' : value!.trim(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
          ),
        ],
      ),
    );
  }
}

class EventLabeledPill extends StatelessWidget {
  const EventLabeledPill({
    super.key,
    required this.label,
    required this.pillLabel,
    required this.semantic,
    required this.onTap,
    this.enabled = true,
    this.isLast = false,
    this.labelWidth,
  });

  final String label;
  final String pillLabel;
  final ContextPillSemantic semantic;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLast;
  final double? labelWidth;

  @override
  Widget build(BuildContext context) {
    return EventLabeledField(
      label: label,
      isLast: isLast,
      labelWidth: labelWidth,
      trailing: ContextPill(
        label: pillLabel,
        semantic: semantic,
        onTap: onTap,
        enabled: enabled,
        compact: true,
        fitContent: false,
        expandWidth: false,
        allowHoverScale: false,
      ),
    );
  }
}

class EventLabeledPills extends StatelessWidget {
  const EventLabeledPills({
    super.key,
    required this.label,
    required this.children,
    this.emptyLabel = '—',
    this.isLast = false,
  });

  final String label;
  final List<Widget> children;
  final String emptyLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return EventLabeledField(
      label: label,
      isLast: isLast,
      trailing: children.isEmpty
          ? Text(emptyLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)))
          : Wrap(spacing: 6, runSpacing: 6, children: children),
    );
  }
}
