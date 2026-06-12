import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../../../screens/common/dashboard_session_scope.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../models/problem_model.dart';
import '../../workspace/problem_workspace_loader.dart';
import 'problem_statement_details_body.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Fills the dashboard main content area with problem statement details (replaces the table).
class ProblemStatementDetailsPane extends StatefulWidget {
  const ProblemStatementDetailsPane({
    super.key,
    required this.problem,
    required this.onBack,
  });

  final ProblemModel problem;
  final VoidCallback onBack;

  @override
  State<ProblemStatementDetailsPane> createState() => _ProblemStatementDetailsPaneState();
}

class _ProblemStatementDetailsPaneState extends State<ProblemStatementDetailsPane> {
  late Future<ProblemWorkspaceViewModel> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = ProblemWorkspaceLoader.load(widget.problem.problemId);
  }

  void _reload() {
    setState(() {
      _loadFuture = ProblemWorkspaceLoader.load(widget.problem.problemId);
    });
  }

  String _headerTitle([ProblemWorkspaceViewModel? vm]) {
    final String fromVm = vm?.problem.title.trim() ?? '';
    if (fromVm.isNotEmpty) return fromVm;
    final String fromProblem = widget.problem.title.trim();
    if (fromProblem.isNotEmpty) return fromProblem;
    return 'Problem Statement';
  }

  Widget _backLeading() {
    return IconButton(
      onPressed: widget.onBack,
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back to Problem Statements',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<ProblemWorkspaceViewModel>(
        future: _loadFuture,
        builder: (BuildContext context, AsyncSnapshot<ProblemWorkspaceViewModel> snapshot) {
          final Widget header = DashboardPageHeader(
            title: _headerTitle(snapshot.data),
            titleIcon: AppIcons.problems,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId),
            onRefresh: _reload,
            leading: _backLeading(),
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                const Expanded(
                  child: Center(child: HkzProgressIndicator(size: 36)),
                ),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(AppIcons.problems, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.hasError
                              ? 'Unable to load: ${snapshot.error}'
                              : 'Problem statement not found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(onPressed: _reload, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 8),
              Expanded(
                child: ProblemStatementDetailsBody(vm: snapshot.data!),
              ),
            ],
          );
        },
      ),
    );
  }
}
