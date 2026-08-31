import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/ui/common/rich_tabs.dart';
import '../models/event_details_module.dart';
import '../widgets/event_details_nav_bar.dart';

/// Shared Event Details body: contextual pills, lifecycle command, grouped nav.
class EventDetailsShell extends StatefulWidget {
  const EventDetailsShell({
    super.key,
    required this.navigation,
    required this.contextPillsFor,
    this.command,
    this.headerActions,
    this.initialId,
    this.onSelected,
  });

  final List<EventDetailsNavGroup> navigation;
  final List<Widget> Function(String selectedId) contextPillsFor;
  final EventDetailsCommand? command;
  final Widget? headerActions;
  final String? initialId;
  final ValueChanged<String>? onSelected;

  @override
  State<EventDetailsShell> createState() => _EventDetailsShellState();
}

class _EventDetailsShellState extends State<EventDetailsShell> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = _resolveInitial(widget.initialId);
  }

  @override
  void didUpdateWidget(covariant EventDetailsShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigation.leafById(_selectedId) == null) {
      _selectedId = _resolveInitial(widget.initialId);
    } else {
      final String next = (widget.initialId ?? '').trim();
      if (next.isNotEmpty &&
          next != (oldWidget.initialId ?? '').trim() &&
          widget.navigation.leafById(next) != null) {
        _selectedId = next;
      }
    }
  }

  String _resolveInitial(String? preferred) {
    final String id = (preferred ?? '').trim();
    if (id.isNotEmpty && widget.navigation.leafById(id) != null) return id;
    final List<EventDetailsModule> leaves = widget.navigation.leaves;
    return leaves.isEmpty ? '' : leaves.first.id;
  }

  void _select(String id) {
    if (id == _selectedId || widget.navigation.leafById(id) == null) return;
    setState(() => _selectedId = id);
    widget.onSelected?.call(id);
  }

  void _runCommand(EventDetailsCommand command) {
    command.onPressed?.call();
    final String dest = (command.destinationId ?? '').trim();
    if (dest.isNotEmpty) _select(dest);
  }

  @override
  Widget build(BuildContext context) {
    final EventDetailsModule? selected = widget.navigation.leafById(_selectedId);
    if (selected == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> pills = widget.contextPillsFor(_selectedId);
    final EventDetailsCommand? command = widget.command;
    final bool mobile = ResponsiveHelper.isMobile(context);

    final Widget? commandButton = command == null
        ? null
        : FilledButton.icon(
            onPressed: !command.enabled ||
                    (command.onPressed == null && (command.destinationId ?? '').isEmpty)
                ? null
                : () => _runCommand(command),
            icon: Icon(command.icon, size: 16),
            label: Text(command.label),
            style: MobileToolbarButtonStyles.filled(compact: true),
          );

    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (commandButton != null) commandButton,
        if (commandButton != null && widget.headerActions != null) const SizedBox(width: 6),
        if (widget.headerActions != null) widget.headerActions!,
      ],
    );

    return Padding(
      padding: RichTabs.resolvePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (pills.isNotEmpty || commandButton != null || widget.headerActions != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (pills.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: pills,
                          ),
                        if (pills.isNotEmpty && (commandButton != null || widget.headerActions != null))
                          const SizedBox(height: 8),
                        if (commandButton != null || widget.headerActions != null)
                          Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: pills,
                          ),
                        ),
                        if (commandButton != null || widget.headerActions != null) ...<Widget>[
                          const SizedBox(width: 8),
                          actions,
                        ],
                      ],
                    ),
            ),
          EventDetailsNavBar(
            groups: widget.navigation,
            selectedId: _selectedId,
            onSelected: _select,
          ),
          const SizedBox(height: 12),
          Expanded(child: selected.child),
        ],
      ),
    );
  }
}
