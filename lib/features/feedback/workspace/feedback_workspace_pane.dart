import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_controller.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/dashboard_session_scope.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import '../../user/models/user_model.dart';
import '../models/feedback_model.dart';
import '../screens/feedback_workspace_screen.dart';
import 'feedback_details_pane.dart';

/// Opens Feedback list in the dashboard chrome overlay (detail pane), not a full route.
void showFeedbackWorkspacePane(
  BuildContext context, {
  required UserModel user,
  required FeedbackWorkspaceMode mode,
  String backTooltip = 'Back',
}) {
  WorkspaceController.instance.close();
  final DashboardChromeController? chrome = DashboardChromeScope.maybeOf(context);
  if (chrome == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback requires an open dashboard session.')),
    );
    return;
  }
  chrome.showOverlay(
    FeedbackWorkspacePane(
      key: ValueKey<String>('feedback-${mode.name}-${user.userId}'),
      user: user,
      mode: mode,
      onBack: chrome.clearOverlay,
      backTooltip: backTooltip,
    ),
  );
}

/// Dashboard overlay hosting the Feedback list (and nested details).
class FeedbackWorkspacePane extends StatefulWidget {
  const FeedbackWorkspacePane({
    super.key,
    required this.user,
    required this.mode,
    required this.onBack,
    this.backTooltip = 'Back',
  });

  final UserModel user;
  final FeedbackWorkspaceMode mode;
  final VoidCallback onBack;
  final String backTooltip;

  @override
  State<FeedbackWorkspacePane> createState() => _FeedbackWorkspacePaneState();
}

class _FeedbackWorkspacePaneState extends State<FeedbackWorkspacePane> {
  FeedbackModel? _selected;
  int _listEpoch = 0;
  bool _listDirty = false;

  void _openDetails(FeedbackModel item) {
    setState(() => _selected = item);
  }

  void _closeDetails() {
    setState(() {
      _selected = null;
      if (_listDirty) {
        _listEpoch++;
        _listDirty = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final FeedbackModel? selected = _selected;
    if (selected != null) {
      return FeedbackDetailsPane(
        key: ValueKey<String>(selected.feedbackId),
        initial: selected,
        viewer: widget.user,
        onBack: _closeDetails,
        onChanged: () => _listDirty = true,
        backTooltip: 'Back to Feedback',
      );
    }

    final DashboardSessionScope session = DashboardSessionScope.of(context);
    final String title =
        widget.mode == FeedbackWorkspaceMode.all ? 'All Feedback' : 'My Feedback';

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DashboardPageHeader(
            title: title,
            titleIcon: AppIcons.feedback,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId, actor: session.user),
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: widget.backTooltip,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          Expanded(
            child: FeedbackWorkspaceScreen(
              key: ValueKey<int>(_listEpoch),
              user: widget.user,
              mode: widget.mode,
              embedded: true,
              onOpenDetails: _openDetails,
            ),
          ),
        ],
      ),
    );
  }
}
