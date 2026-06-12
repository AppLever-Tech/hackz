import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/dashboard_session_scope.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../services/idea_details_loader.dart';
import 'idea_details_body.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Opens the tabbed idea details overlay in the dashboard main panel.
void showIdeaDetailsPane(
  BuildContext context, {
  required String ideaId,
  String backTooltip = 'Back to Ideas',
}) {
  WorkspaceController.instance.close();
  final chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    IdeaDetailsPane(
      key: ValueKey<String>(ideaId),
      ideaId: ideaId,
      onBack: chrome.clearOverlay,
      backTooltip: backTooltip,
    ),
  );
}

/// Fills the dashboard main content area with idea details (replaces the ideas table).
class IdeaDetailsPane extends StatefulWidget {
  const IdeaDetailsPane({
    super.key,
    required this.ideaId,
    required this.onBack,
    this.backTooltip = 'Back to Ideas',
  });

  final String ideaId;
  final VoidCallback onBack;
  final String backTooltip;

  @override
  State<IdeaDetailsPane> createState() => _IdeaDetailsPaneState();
}

class _IdeaDetailsPaneState extends State<IdeaDetailsPane> {
  late Future<IdeaDetailsViewModel> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = IdeaDetailsLoader.load(widget.ideaId);
  }

  void _reload() {
    setState(() {
      _loadFuture = IdeaDetailsLoader.load(widget.ideaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<IdeaDetailsViewModel>(
        future: _loadFuture,
        builder: (BuildContext context, AsyncSnapshot<IdeaDetailsViewModel> snapshot) {
          final String title = snapshot.data?.ideaVm.idea.ideaTitle.trim() ?? '';
          final Widget header = DashboardPageHeader(
            title: title.isEmpty ? 'Innovation Details' : title,
            titleIcon: AppIcons.ideas,
            user: session.user,
            onLogout: session.onLogout,
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId),
            onRefresh: _reload,
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: widget.backTooltip,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                const Expanded(child: Center(child: HkzProgressIndicator(size: 36))),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(AppIcons.ideas, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.hasError
                              ? 'Unable to load: ${snapshot.error}'
                              : 'Innovation not found',
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 8),
              Expanded(child: IdeaDetailsBody(vm: snapshot.data!)),
            ],
          );
        },
      ),
    );
  }
}
