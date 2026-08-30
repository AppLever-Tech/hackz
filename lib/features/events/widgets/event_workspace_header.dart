import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../models/event_kind.dart';
import 'event_labeled_field.dart';

/// Shared identity block for event-scoped workspaces (overview, payments, etc.).
class EventWorkspaceHeader extends StatelessWidget {
  const EventWorkspaceHeader({
    super.key,
    required this.kind,
    required this.name,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.organisationName,
    required this.entryCount,
    required this.typePill,
    required this.statusPill,
  });

  final EventKind kind;
  final String name;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String organisationName;
  final int entryCount;
  final Widget typePill;
  final Widget statusPill;

  static const double _labelWidth = 110;
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
  );

  String get _kindTitle => 'Event - ${kind.label}';

  String get _entriesLabel => 'Total ${kind.entriesLabel.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final String title = name.trim().isEmpty ? 'Event' : name.trim();
    final String desc = description.trim();
    final String org = organisationName.trim().isEmpty ? '—' : organisationName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _kindTitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334155),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(kind.icon, size: 22, color: const Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                typePill,
                const SizedBox(width: 6),
                statusPill,
              ],
            ),
          ],
        ),
        if (desc.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 10),
        EventLabeledField(
          icon: AppIcons.clock,
          label: 'Starts',
          value: formatDateTime(startDateTime.toLocal()),
          labelWidth: _labelWidth,
          valueStyle: _valueStyle,
        ),
        EventLabeledField(
          icon: AppIcons.event,
          label: 'Ends',
          value: formatDateTime(endDateTime.toLocal()),
          labelWidth: _labelWidth,
          valueStyle: _valueStyle,
        ),
        EventLabeledField(
          icon: AppIcons.organizations,
          label: 'Organisation',
          value: org,
          labelWidth: _labelWidth,
          valueStyle: _valueStyle,
        ),
        EventLabeledField(
          icon: kind.entriesIcon,
          label: _entriesLabel,
          value: '$entryCount',
          labelWidth: _labelWidth,
          valueStyle: _valueStyle,
          isLast: true,
        ),
      ],
    );
  }
}
