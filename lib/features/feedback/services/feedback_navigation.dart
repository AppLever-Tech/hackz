import 'package:flutter/material.dart';

import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../dashboard/chrome/dashboard_session_scope.dart';
import '../dialogs/feedback_submit_dialog.dart';
import '../screens/feedback_workspace_screen.dart';
import '../services/hackz_feedback_service.dart';
import '../workspace/feedback_workspace_pane.dart';

/// Overflow + contextual entry points for Feedback.
abstract final class FeedbackNavigation {
  FeedbackNavigation._();

  static const String overflowAction = 'feedback';

  static Future<void> open(
    BuildContext context, {
    UserModel? user,
    String screenName = 'App',
  }) async {
    final UserModel? resolved =
        user ?? DashboardSessionScope.maybeOf(context)?.user;
    if (resolved == null) return;

    final bool enabled = await HackzFeedbackService.isFeedbackEnabledFor(resolved);
    if (!enabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback is disabled for your organization.')),
        );
      }
      return;
    }

    final bool isAdmin = UserRole.fromCode(resolved.role) == UserRole.sysAdmin;
    if (!context.mounted) return;
    showFeedbackWorkspacePane(
      context,
      user: resolved,
      mode: isAdmin ? FeedbackWorkspaceMode.all : FeedbackWorkspaceMode.mine,
      backTooltip: 'Back',
    );
  }

  static Future<void> openSubmit(
    BuildContext context, {
    required UserModel user,
    String screenName = 'App',
  }) {
    return showFeedbackSubmitDialog(
      context: context,
      user: user,
      screenName: screenName,
    );
  }
}
