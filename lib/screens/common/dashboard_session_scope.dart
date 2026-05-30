import 'package:flutter/material.dart';

import '../../features/user/models/user_model.dart';

/// Exposes the signed-in user and logout callback to dashboard body widgets and overlays.
class DashboardSessionScope extends InheritedWidget {
  const DashboardSessionScope({
    super.key,
    required this.user,
    required this.onLogout,
    required super.child,
  });

  final UserModel user;
  final VoidCallback onLogout;

  static DashboardSessionScope of(BuildContext context) {
    final DashboardSessionScope? scope =
        context.dependOnInheritedWidgetOfExactType<DashboardSessionScope>();
    assert(scope != null, 'DashboardSessionScope not found.');
    return scope!;
  }

  static DashboardSessionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardSessionScope>();
  }

  @override
  bool updateShouldNotify(DashboardSessionScope oldWidget) {
    return user != oldWidget.user || onLogout != oldWidget.onLogout;
  }
}
