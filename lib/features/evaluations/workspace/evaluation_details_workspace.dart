import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_controller.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/dashboard_session_scope.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../models/evaluation_details_view_model.dart';
import '../services/evaluation_details_loader.dart';
import '../../../core/workspace/workspace_controller.dart';
import '../../../core/workspace/workspace_navigator.dart';
import 'evaluation_workspace_body.dart';

/// Opens evaluation-centric details in the dashboard overlay (not Idea Details).
void showEvaluationDetailsPane(
  BuildContext context, {
  required String ideaId,
  String ideathonId = '',
  String backTooltip = 'Back to Evaluation Results',
}) {
  WorkspaceController.instance.close();
  final DashboardChromeController chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    EvaluationDetailsPane(
      key: ValueKey<String>('$ideaId|${ideathonId.trim()}'),
      ideaId: ideaId,
      ideathonId: ideathonId,
      onBack: chrome.clearOverlay,
      backTooltip: backTooltip,
    ),
  );
}

/// Dashboard overlay hosting the Evaluation Details workspace.
class EvaluationDetailsPane extends StatefulWidget {
  const EvaluationDetailsPane({
    super.key,
    required this.ideaId,
    required this.onBack,
    this.ideathonId = '',
    this.backTooltip = 'Back',
  });

  final String ideaId;
  final String ideathonId;
  final VoidCallback onBack;
  final String backTooltip;

  @override
  State<EvaluationDetailsPane> createState() => _EvaluationDetailsPaneState();
}

class _EvaluationDetailsPaneState extends State<EvaluationDetailsPane> {
  late Future<EvaluationDetailsViewModel> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = EvaluationDetailsLoader.load(
        ideaId: widget.ideaId,
        ideathonId: widget.ideathonId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<EvaluationDetailsViewModel>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<EvaluationDetailsViewModel> snapshot) {
          final String title = snapshot.data?.ideaTitle.trim() ?? '';
          final Widget header = DashboardPageHeader(
            title: title.isEmpty ? 'Evaluation Details' : title,
            titleIcon: AppIcons.results,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId, actor: session.user),
            onRefresh: _load,
            helpPageId: 'evaluation-lifecycle',
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(AppIcons.back),
              tooltip: widget.backTooltip,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          );

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const Expanded(child: Center(child: HkzProgressIndicator(size: 36))),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(child: Center(child: Text('Unable to load evaluation: ${snapshot.error}'))),
              ],
            );
          }

          final EvaluationDetailsViewModel vm = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 8),
              Expanded(
                child: EvaluationWorkspaceBody(vm: vm, actor: session.user),
              ),
            ],
          );
        },
      ),
    );
  }
}
