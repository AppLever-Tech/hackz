import 'package:flutter/material.dart';

import 'workspace_container.dart';
import 'workspace_controller.dart';
import 'workspace_route.dart';
import 'workspace_theme.dart';

/// Provides [WorkspaceController] to descendants and renders the active workspace layer.
class WorkspaceScope extends InheritedWidget {
  const WorkspaceScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final WorkspaceController controller;

  static WorkspaceController of(BuildContext context) {
    final WorkspaceScope? scope =
        context.dependOnInheritedWidgetOfExactType<WorkspaceScope>();
    assert(scope != null, 'WorkspaceScope not found. Wrap app with WorkspaceHost.');
    return scope!.controller;
  }

  static WorkspaceController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WorkspaceScope>()?.controller;
  }

  @override
  bool updateShouldNotify(WorkspaceScope oldWidget) =>
      oldWidget.controller != controller;
}

/// App-level host: single active contextual workspace (panel / bottom sheet).
class WorkspaceHost extends StatefulWidget {
  const WorkspaceHost({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final WorkspaceController? controller;

  @override
  State<WorkspaceHost> createState() => _WorkspaceHostState();
}

class _WorkspaceHostState extends State<WorkspaceHost>
    with SingleTickerProviderStateMixin {
  late final WorkspaceController _controller;
  late final AnimationController _present;
  late final Animation<double> _fade;
  late final Animation<Offset> _panelSlide;
  late final Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WorkspaceController.instance;
    _controller.addListener(_onControllerChanged);
    _present = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _present.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed ||
          status == AnimationStatus.completed) {
        setState(() {});
      }
    });
    final CurvedAnimation curved =
        CurvedAnimation(parent: _present, curve: Curves.easeOutCubic);
    _fade = curved;
    _panelSlide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(curved);
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(curved);
    if (_controller.isOpen) {
      _present.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _present.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.isOpen) {
      _present.forward();
    } else {
      _present.reverse();
    }
    setState(() {});
  }

  bool get _showWorkspaceLayer =>
      _controller.isOpen || _present.isAnimating;

  @override
  Widget build(BuildContext context) {
    return WorkspaceScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          if (_showWorkspaceLayer)
            IgnorePointer(
              // After [close], stop intercepting taps while the panel fades out.
              ignoring: !_controller.isOpen,
              child: _WorkspaceLayer(
                controller: _controller,
                fade: _fade,
                panelSlide: _panelSlide,
                sheetSlide: _sheetSlide,
              ),
            ),
        ],
      ),
    );
  }
}

/// Right/bottom anchored panel only — never a full-screen hit target.
class _WorkspaceLayer extends StatelessWidget {
  const _WorkspaceLayer({
    required this.controller,
    required this.fade,
    required this.panelSlide,
    required this.sheetSlide,
  });

  final WorkspaceController controller;
  final Animation<double> fade;
  final Animation<Offset> panelSlide;
  final Animation<Offset> sheetSlide;

  /// Local [Overlay] so header tooltips work; scoped to the panel, not the whole app.
  static Widget _panelOverlayShell({
    required WorkspaceController controller,
    required bool isMobile,
  }) {
    return Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) => WorkspaceContainer(
            controller: controller,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = workspaceUseMobileSheet(context);
    final double panelWidth = WorkspaceTheme.panelWidth(context, isMobile: isMobile);
    const double desktopPanelTrailingPadding = 8;

    final Widget panel = _panelOverlayShell(
      controller: controller,
      isMobile: isMobile,
    );

    if (isMobile) {
      final double sheetHeight = WorkspaceTheme.mobileSheetHeight(context);
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: sheetHeight,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: sheetSlide,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: panelWidth,
                height: sheetHeight,
                child: panel,
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: panelWidth + desktopPanelTrailingPadding,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: panelSlide,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: panelWidth,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, desktopPanelTrailingPadding, 8),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height - 16,
                    child: panel,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience API for opening the shared workspace from any screen.
abstract final class HkzWorkspace {
  static WorkspaceController controllerOf(BuildContext context) =>
      WorkspaceScope.of(context);

  static WorkspaceController get global => WorkspaceController.instance;

  static void open(BuildContext context, WorkspaceRoute route) {
    WorkspaceScope.of(context).open(route);
  }

  static void push(BuildContext context, WorkspaceRoute route) {
    WorkspaceScope.of(context).push(route);
  }

  static void replace(BuildContext context, WorkspaceRoute route) {
    WorkspaceScope.of(context).replace(route);
  }

  static void pop(BuildContext context) {
    WorkspaceScope.of(context).pop();
  }

  static void close(BuildContext context) {
    WorkspaceScope.of(context).close();
  }

  static void updateMessage(
    BuildContext context, {
    String? title,
    String? subtitle,
  }) {
    WorkspaceScope.of(context).updateTop(title: title, subtitle: subtitle);
  }
}
