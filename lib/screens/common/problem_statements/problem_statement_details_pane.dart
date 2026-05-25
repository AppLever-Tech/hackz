import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/problem_model.dart';
import '../../../widgets/loading/hkz_progress_indicator.dart';
import '../../../workspace/problem/problem_workspace_loader.dart';
import 'problem_statement_details_body.dart';

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

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FutureBuilder<ProblemWorkspaceViewModel>(
        future: _loadFuture,
        builder: (BuildContext context, AsyncSnapshot<ProblemWorkspaceViewModel> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _DetailsBackButton(onPressed: widget.onBack),
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
                _DetailsBackButton(onPressed: widget.onBack),
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

          return ProblemStatementDetailsBody(
            vm: snapshot.data!,
            onBack: widget.onBack,
          );
        },
      ),
    );
  }
}

class _DetailsBackButton extends StatelessWidget {
  const _DetailsBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back to Problem Statements',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
