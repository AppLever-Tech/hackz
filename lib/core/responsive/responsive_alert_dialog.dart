import 'package:flutter/material.dart';

import 'responsive_dialog.dart';
import 'responsive_dialog_actions.dart';

/// [AlertDialog] replacement with fullscreen mobile and adaptive max width.
class ResponsiveAlertDialog extends StatelessWidget {
  const ResponsiveAlertDialog({
    super.key,
    this.title,
    required this.content,
    this.actions = const <Widget>[],
    this.widthPreset = DialogWidthPreset.standard,
    this.scrollable = true,
  });

  final Widget? title;
  final Widget content;
  final List<Widget> actions;
  final DialogWidthPreset widthPreset;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final fullscreen = ResponsiveDialogConstraints.useFullscreen(context);
    final maxW = ResponsiveDialogConstraints.maxWidth(context, preset: widthPreset);

    final body = scrollable
        ? SingleChildScrollView(
            child: content,
          )
        : content;

    if (fullscreen) {
      return Dialog.fullscreen(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: DefaultTextStyle.merge(style: Theme.of(context).textTheme.titleLarge, child: title!)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.viewInsetsOf(context).bottom),
                  child: body,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ResponsiveDialogActions(children: actions),
                ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: body,
      ),
      actions: actions.isEmpty ? null : actions,
    );
  }
}
