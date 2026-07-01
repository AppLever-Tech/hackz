import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_controller.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/dashboard_session_scope.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../core/responsive/responsive_columns.dart';
import '../../user/models/user_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../models/evaluation_details_view_model.dart';
import '../services/evaluation_details_loader.dart';
import '../widgets/evaluation_judge_breakdown_panel.dart';
import '../widgets/evaluation_overview_card.dart';
import '../widgets/evaluation_score_distribution.dart';
import '../widgets/evaluation_shortlisting_section.dart';
import '../widgets/evaluation_summary_cards.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Opens evaluation-centric details in the dashboard overlay (not Idea Details).
void showEvaluationDetailsPane(
  BuildContext context, {
  required String ideaId,
  required UserModel viewer,
  String backTooltip = 'Back to Evaluation Results',
}) {
  WorkspaceController.instance.close();
  final DashboardChromeController chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    EvaluationDetailsPane(
      key: ValueKey<String>(ideaId),
      ideaId: ideaId,
      viewer: viewer,
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
    required this.viewer,
    required this.onBack,
    this.backTooltip = 'Back',
  });

  final String ideaId;
  final UserModel viewer;
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
      _future = EvaluationDetailsLoader.load(ideaId: widget.ideaId, viewer: widget.viewer);
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
            onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId),
            onRefresh: _load,
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
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
                child: EvaluationDetailsBody(
                  vm: vm,
                  shortlistedByUserId: widget.viewer.userId,
                  onUpdated: _load,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Layout variant for [EvaluationDetailsBody].
enum EvaluationDetailsLayout {
  /// Full evaluation results overlay (metrics, full judge rows).
  pane,

  /// Side workspace opened from a context pill (compact judge rows, no metric cards).
  workspace,
}

/// Evaluation-centric scrollable body (shared by pane + side workspace).
class EvaluationDetailsBody extends StatelessWidget {
  const EvaluationDetailsBody({
    super.key,
    required this.vm,
    required this.shortlistedByUserId,
    required this.onUpdated,
    this.layout = EvaluationDetailsLayout.pane,
  });

  final EvaluationDetailsViewModel vm;
  final String shortlistedByUserId;
  final VoidCallback onUpdated;
  final EvaluationDetailsLayout layout;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool workspace = layout == EvaluationDetailsLayout.workspace;
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      mobile ? 12 : 16,
      4,
      mobile ? 12 : 16,
      24,
    );

    final Widget overviewDistributionRow = ResponsivePair(
      spacing: 12,
      firstFlex: 1,
      secondFlex: 1,
      first: EvaluationOverviewCard(vm: vm),
      second: EvaluationScoreDistribution(
        judgeDetails: vm.judgeDetails,
        scoringScale: vm.scoringScale,
      ),
    );

    final bool showShortlisting = workspace ||
        vm.canShortlist ||
        IdeaStatusHelpers.isPostEvaluationReview(vm.status);

    return ListView(
      padding: pad,
      children: <Widget>[
        if (!workspace) EvaluationSummaryCards(idea: vm.idea),
        if (showShortlisting) ...<Widget>[
          if (!workspace) const SizedBox(height: 14),
          EvaluationShortlistingSection(
            vm: vm,
            shortlistedByUserId: shortlistedByUserId,
            onUpdated: onUpdated,
            alwaysShowRankStatus: workspace,
          ),
        ],
        const SizedBox(height: 14),
        overviewDistributionRow,
        const SizedBox(height: 14),
        EvaluationJudgeBreakdownPanel(
          judgeDetails: vm.judgeDetails,
          departmentCode: vm.idea.problemDepartmentCode,
          compactRows: workspace,
        ),
      ],
    );
  }
}
