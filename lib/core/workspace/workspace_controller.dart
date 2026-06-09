import 'package:flutter/foundation.dart';

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

  List<WorkspaceRoute> get stack => List<WorkspaceRoute>.unmodifiable(_stack);

  /// Opens workspace with a fresh stack (replaces any open workspace).
  void open(WorkspaceRoute route) {
    _stack
      ..clear()
      ..add(route);
    notifyListeners();
  }

  /// Pushes another entity inside the same workspace (internal back stack).
  void push(WorkspaceRoute route) {
    if (_stack.isEmpty) {
      open(route);
      return;
    }
    _stack.add(route);
    notifyListeners();
  }

  /// Replaces the top route (e.g. refresh same level).
  void replace(WorkspaceRoute route) {
    if (_stack.isEmpty) {
      open(route);
      return;
    }
    _stack[_stack.length - 1] = route;
    notifyListeners();
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
      WorkspaceRoute(
        id: top.id,
        title: title ?? top.title,
        subtitle: subtitle ?? top.subtitle,
        builder: top.builder,
        prepare: top.prepare,
      ),
    );
    notifyListeners();
  }
}
