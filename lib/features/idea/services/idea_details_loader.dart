import '../workspace/idea_workspace_loader.dart';

/// Combined view model for the idea details dashboard pane.
class IdeaDetailsViewModel {
  const IdeaDetailsViewModel({required this.ideaVm});

  final IdeaWorkspaceViewModel ideaVm;
}

abstract final class IdeaDetailsLoader {
  static Future<IdeaDetailsViewModel> load(String ideaId) async {
    final IdeaWorkspaceViewModel ideaVm = await IdeaWorkspaceLoader.load(ideaId);
    return IdeaDetailsViewModel(ideaVm: ideaVm);
  }
}
