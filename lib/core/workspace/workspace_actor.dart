import '../../features/user/models/user_model.dart';

/// Viewer of the workspace (who is looking), not the profile being opened.
abstract final class WorkspaceActor {
  WorkspaceActor._();

  /// Explicit [actor], else the actor already on the workspace stack, else session.
  static UserModel? resolve({
    UserModel? actor,
    UserModel? stacked,
    UserModel? session,
  }) =>
      actor ?? stacked ?? session;
}
