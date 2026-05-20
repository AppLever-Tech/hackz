import 'package:flutter/material.dart';

import '../../widgets/loading/hkz_progress_indicator.dart';
import '../problem/problem_workspace.dart';
import '../user/user_workspace.dart';
import 'workspace_controller.dart';
import 'workspace_header.dart';
import 'workspace_route.dart';
import 'workspace_transition.dart';

/// Renders the active workspace route with header + lazy-loaded body.
class WorkspaceNavigator extends StatelessWidget {
  const WorkspaceNavigator({
    super.key,
    required this.controller,
  });

  final WorkspaceController controller;

  /// Opens the read-only user workspace for [userId] (replaces the current workspace stack).
  static void openUser(BuildContext context, String userId) {
    UserWorkspace.open(context, userId);
  }

  /// Opens the read-only problem workspace for [problemId].
  static void openProblem(BuildContext context, String problemId) {
    ProblemWorkspace.open(context, problemId);
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceRoute? route = controller.current;
    if (route == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WorkspaceHeader(
          title: route.title,
          subtitle: route.subtitle,
          showBack: true,
          onBack: controller.pop,
          onClose: controller.close,
        ),
        Expanded(
          child: WorkspaceTransition(
            routeKey: route.id,
            child: _WorkspaceRouteBody(
              key: ValueKey<String>(route.id),
              route: route,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceRouteBody extends StatefulWidget {
  const _WorkspaceRouteBody({
    super.key,
    required this.route,
  });

  final WorkspaceRoute route;

  @override
  State<_WorkspaceRouteBody> createState() => _WorkspaceRouteBodyState();
}

class _WorkspaceRouteBodyState extends State<_WorkspaceRouteBody> {
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _WorkspaceRouteBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id ||
        oldWidget.route.prepare != widget.route.prepare) {
      _ready = false;
      _error = null;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final Future<void> Function()? prep = widget.route.prepare;
    if (prep == null) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    try {
      await prep();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _ready = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: HkzProgressIndicator(size: 36));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Failed to load: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB93838), fontSize: 13),
          ),
        ),
      );
    }
    return widget.route.builder(context);
  }
}
