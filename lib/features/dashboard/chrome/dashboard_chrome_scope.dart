import 'package:flutter/material.dart';

import 'dashboard_chrome_controller.dart';

/// Exposes [DashboardChromeController] to dashboard body widgets.
class DashboardChromeScope extends InheritedNotifier<DashboardChromeController> {
  const DashboardChromeScope({
    super.key,
    required DashboardChromeController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardChromeController of(BuildContext context) {
    final DashboardChromeScope? scope =
        context.dependOnInheritedWidgetOfExactType<DashboardChromeScope>();
    assert(scope != null, 'DashboardChromeScope not found.');
    return scope!.notifier!;
  }

  static DashboardChromeController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardChromeScope>()?.notifier;
  }
}
