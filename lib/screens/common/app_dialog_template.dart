import 'package:flutter/material.dart';

import '../../responsive/responsive_dialog.dart';

export '../../responsive/responsive_dialog.dart' show DialogWidthPreset;

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  DialogWidthPreset width = DialogWidthPreset.standard,
  double? maxWidth,
  EdgeInsetsGeometry? contentPadding,
  bool showBorder = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext _) {
      return AppDialogTemplate(
        width: width,
        maxWidth: maxWidth,
        contentPadding: contentPadding,
        showBorder: showBorder,
        child: child,
      );
    },
  );
}

/// Premium centered dialog on desktop/tablet; fullscreen scrollable sheet on mobile.
class AppDialogTemplate extends StatelessWidget {
  const AppDialogTemplate({
    super.key,
    required this.child,
    this.width = DialogWidthPreset.standard,
    this.maxWidth,
    this.contentPadding,
    this.showBorder = true,
  });

  final Widget child;
  final DialogWidthPreset width;
  final double? maxWidth;
  final EdgeInsetsGeometry? contentPadding;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final fullscreen = ResponsiveDialogConstraints.useFullscreen(context);
    final resolvedPadding = contentPadding ?? ResponsiveDialogConstraints.contentPadding(context);
    final resolvedMaxWidth = ResponsiveDialogConstraints.maxWidth(context, preset: width, override: maxWidth);

    final decoration = BoxDecoration(
      borderRadius: fullscreen ? null : BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF7F3FF), Color(0xFFEFE7FF)],
      ),
      border: showBorder && !fullscreen ? Border.all(color: const Color(0xFFD9CBFF)) : null,
    );

    final scrollChild = Padding(
      padding: resolvedPadding,
      child: child,
    );

    final body = fullscreen
        ? SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                    child: scrollChild,
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            child: scrollChild,
          );

    if (fullscreen) {
      return Dialog.fullscreen(
        backgroundColor: const Color(0xFFF4F0FF),
        child: DecoratedBox(decoration: decoration, child: body),
      );
    }

    return Dialog(
      insetPadding: ResponsiveDialogConstraints.dialogInsets(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: const Color(0xFFF4F0FF),
      child: Container(
        decoration: decoration,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
          child: body,
        ),
      ),
    );
  }
}
