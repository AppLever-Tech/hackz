import '../../models/problem_model.dart';
import '../../models/user_model.dart';
import 'innovation_submission_workspace.dart';

/// @deprecated Use [showInnovationSubmissionWorkspace] from a Problem Card (problem-first flow).
@Deprecated('Launch showInnovationSubmissionWorkspace from Problem Card with a selected problem.')
Future<bool?> showSubmitIdeaFromProblem({
  required UserModel currentUser,
  required ProblemModel problem,
}) {
  return showInnovationSubmissionWorkspace(
    currentUser: currentUser,
    problem: problem,
  );
}
