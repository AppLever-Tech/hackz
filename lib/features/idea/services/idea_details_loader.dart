import '../workspace/idea_workspace_loader.dart';
import '../../problems/workspace/problem_workspace_loader.dart';

/// Combined view model for the idea details dashboard pane.
class IdeaDetailsViewModel {
  const IdeaDetailsViewModel({
    required this.ideaVm,
    required this.problemVm,
  });

  final IdeaWorkspaceViewModel ideaVm;
  final ProblemWorkspaceViewModel problemVm;
}

abstract final class IdeaDetailsLoader {
  static Future<IdeaDetailsViewModel> load(String ideaId) async {
    final IdeaWorkspaceViewModel ideaVm = await IdeaWorkspaceLoader.load(ideaId);
    final String problemId = ideaVm.idea.problemId.trim();
    if (problemId.isEmpty) {
      throw StateError('Idea has no linked problem');
    }
    final ProblemWorkspaceViewModel problemVm = await ProblemWorkspaceLoader.load(problemId);
    return IdeaDetailsViewModel(ideaVm: ideaVm, problemVm: problemVm);
  }
}
