import 'package:flutter/foundation.dart';

import '../../features/user/models/user_model.dart';
import 'workspace_actor.dart';
import 'workspace_route.dart';

/// Single active workspace: one stack, one visible panel.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController();

  static final WorkspaceController instance = WorkspaceController();

  final List<WorkspaceRoute> _stack = <WorkspaceRoute>[];

  bool get isOpen => _stack.isNotEmpty;

  bool get canPopInternal => _stack.length > 1;

  int get depth => _stack.length;

  WorkspaceRoute? get current => _stack.isEmpty ? null : _stack.last;

  /// Viewer carried on the current route (inherited across nested pushes).
  UserModel? get actor => current?.actor;

  List<WorkspaceRoute> get stack => List<WorkspaceRoute>.unmodifiable(_stack);

  /// Opens workspace with a fresh stack (replaces any open workspace).
  void open(WorkspaceRoute route, {UserModel? sessionUser}) {
    final WorkspaceRoute stamped = _withActor(route, sessionUser);
    _stack
      ..clear()
      ..add(stamped);
    notifyListeners();
  }

  /// Pushes another entity inside the same workspace (internal back stack).
  void push(WorkspaceRoute route, {UserModel? sessionUser}) {
    if (_stack.isEmpty) {
      open(route, sessionUser: sessionUser);
      return;
    }
    _stack.add(_withActor(route, sessionUser));
    notifyListeners();
  }

  /// Replaces the top route (e.g. refresh same level).
  void replace(WorkspaceRoute route, {UserModel? sessionUser}) {
    if (_stack.isEmpty) {
      open(route, sessionUser: sessionUser);
      return;
    }
    _stack[_stack.length - 1] = _withActor(route, sessionUser);
    notifyListeners();
  }

  WorkspaceRoute _withActor(WorkspaceRoute route, UserModel? sessionUser) {
    final UserModel? resolved = WorkspaceActor.resolve(
      actor: route.actor,
      stacked: current?.actor,
      session: sessionUser,
    );
    if (identical(resolved, route.actor)) return route;
    return route.copyWith(actor: resolved);
  }

  /// Internal back: previous workspace route, or closes if only one deep.
  void pop() {
    if (_stack.length <= 1) {
      close();
      return;
    }
    _stack.removeLast();
    notifyListeners();
  }

  void close() {
    if (_stack.isEmpty) return;
    _stack.clear();
    notifyListeners();
  }

  void updateTop({
    String? title,
    String? subtitle,
  }) {
    if (_stack.isEmpty) return;
    final WorkspaceRoute top = _stack.removeLast();
    _stack.add(
      top.copyWith(
        title: title ?? top.title,
        subtitle: subtitle ?? top.subtitle,
      ),
    );
    notifyListeners();
  }
}
