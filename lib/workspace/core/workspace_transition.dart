import 'package:flutter/material.dart';

/// Internal workspace route transition (slide + fade).
class WorkspaceTransition extends StatelessWidget {
  const WorkspaceTransition({
    super.key,
    required this.routeKey,
    required this.child,
    this.reverse = false,
  });

  final Object routeKey;
  final Widget child;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? current, List<Widget> previous) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[...previous, if (current != null) current],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Offset begin = reverse
            ? const Offset(-0.06, 0)
            : const Offset(0.06, 0);
        final Animation<Offset> offset = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: offset,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(routeKey),
        child: child,
      ),
    );
  }
}
