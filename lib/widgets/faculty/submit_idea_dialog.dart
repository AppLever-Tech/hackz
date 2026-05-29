import 'package:flutter/material.dart';

import '../../features/problems/models/problem_model.dart';
import '../../features/user/models/user_model.dart';
import 'innovation_submission_workspace.dart';

/// @deprecated Use [showInnovationSubmissionWorkspace] from a Problem Card (problem-first flow).
@Deprecated('Launch showInnovationSubmissionWorkspace from Problem Card with a selected problem.')
Future<bool?> showSubmitIdeaFromProblem({
  required BuildContext context,
  required UserModel currentUser,
  required ProblemModel problem,
}) {
  return showInnovationSubmissionWorkspace(
    context: context,
    currentUser: currentUser,
    problem: problem,
  );
}
