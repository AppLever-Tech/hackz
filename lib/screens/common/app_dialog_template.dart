import 'package:flutter/material.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  double maxWidth = 620,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.all(20),
  bool showBorder = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext _) {
      return AppDialogTemplate(
        maxWidth: maxWidth,
        contentPadding: contentPadding,
        showBorder: showBorder,
        child: child,
      );
    },
  );
}

class AppDialogTemplate extends StatelessWidget {
  const AppDialogTemplate({
    super.key,
    required this.child,
    this.maxWidth = 620,
    this.contentPadding = const EdgeInsets.all(20),
    this.showBorder = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: const Color(0xFFF4F0FF),
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF7F3FF), Color(0xFFEFE7FF)],
          ),
          border: showBorder ? Border.all(color: const Color(0xFFD9CBFF)) : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: contentPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
