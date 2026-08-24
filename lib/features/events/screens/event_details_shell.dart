import 'package:flutter/material.dart';

import '../../../core/ui/common/rich_tabs.dart';
import '../models/event_details_module.dart';

/// Shared Event Details body: compact header pills + tab/module switcher.
class EventDetailsShell extends StatelessWidget {
  const EventDetailsShell({
    super.key,
    required this.headerPills,
    required this.modules,
  });

  final List<Widget> headerPills;
  final List<EventDetailsModule> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (headerPills.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: headerPills,
            ),
          ),
        Expanded(
          child: RichTabs(
            switcherMaxWidth: 1080,
            tabs: modules
                .map(
                  (EventDetailsModule m) => RichTabItem(m.label, count: m.count),
                )
                .toList(growable: false),
            children: modules.map((EventDetailsModule m) => m.child).toList(growable: false),
          ),
        ),
      ],
    );
  }
}
