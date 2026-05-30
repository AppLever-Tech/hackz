import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import 'evaluation_assignment_workspace.dart';

/// Fills the dashboard main content area with evaluation assignment management.
class EvaluationAssignmentDetailsPane extends StatelessWidget {
  const EvaluationAssignmentDetailsPane({
    super.key,
    required this.user,
    required this.onBack,
    this.problemId,
    this.ideaId,
    this.backTooltip = 'Back',
  });

  final UserModel user;
  final VoidCallback onBack;
  final String? problemId;
  final String? ideaId;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: backTooltip,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          Expanded(
            child: EvaluationAssignmentWorkspace(
              user: user,
              problemId: problemId,
              ideaId: ideaId,
            ),
          ),
        ],
      ),
    );
  }
}
