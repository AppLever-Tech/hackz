import 'package:flutter/material.dart';

import '../../core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/attachment/workspace/attachment_workspace.dart';
import 'package:hackz/features/idea/workspace/idea_workspace.dart';
import '../../features/evaluations/workspace/evaluation_template_workspace.dart';
import '../../features/evaluations/workspace/evaluation_workspace.dart';
import '../../features/ideathons/workspace/ideathon_evaluation_workspace.dart';
import '../../features/ideathons/workspace/ideathon_judge_assignment_workspace.dart';
import '../../features/ideathons/workspace/ideathon_payment_workspace.dart';
import '../../features/ideathons/workspace/ideathon_results_workspace.dart';
import '../../features/ideathons/workspace/ideathon_workspace.dart';
import 'package:hackz/features/payment/workspace/payment_workspace.dart';
import '../../features/problems/workspace/problem_workspace.dart';
import '../../features/team/workspace/team_workspace.dart';
import '../../features/user/models/user_model.dart';
import '../../features/user/workspace/user_workspace.dart';
import 'workspace_controller.dart';
import 'workspace_header.dart';
import 'workspace_route.dart';
import 'workspace_transition.dart';

/// Renders the active workspace route with header + lazy-loaded body.
class WorkspaceNavigator extends StatelessWidget {
  const WorkspaceNavigator({
    super.key,
    required this.controller,
  });

  final WorkspaceController controller;

  /// Opens the read-only user workspace for [userId] (replaces the current workspace stack).
  static void openUser(BuildContext context, String userId) {
    UserWorkspace.open(context, userId);
  }

  /// Opens the read-only problem workspace for [problemId].
  static void openProblem(BuildContext context, String problemId) {
    ProblemWorkspace.open(context, problemId);
  }

  /// Opens the read-only team workspace for [teamId] (replaces the current workspace stack).
  static void openTeam(BuildContext context, String teamId) {
    TeamWorkspace.open(context, teamId);
  }

  /// Opens the read-only idea workspace for [ideaId] (replaces the current workspace stack).
  static void openIdea(BuildContext context, String ideaId) {
    IdeaWorkspace.open(context, ideaId);
  }

  /// Opens the read-only payment workspace for [paymentId].
  static void openPayment(BuildContext context, String paymentId) {
    PaymentWorkspace.open(context, paymentId);
  }

  /// Opens the read-only evaluation workspace for [evaluationId] (score id or idea id).
  static void openEvaluation(
    BuildContext context,
    String evaluationId, {
    String ideathonId = '',
  }) {
    EvaluationWorkspace.open(context, evaluationId, ideathonId: ideathonId);
  }

  /// Opens the read-only evaluation template workspace for [templateId].
  static void openEvaluationTemplate(
    BuildContext context,
    String templateId, {
    String? departmentCode,
  }) {
    EvaluationTemplateWorkspace.open(
      context,
      templateId,
      departmentCode: departmentCode,
    );
  }

  /// Opens Ideathon Evaluation Results using the existing Results UX for [ideathonId].
  static void openIdeathonResults(
    BuildContext context,
    String ideathonId, {
    required UserModel actor,
  }) {
    IdeathonResultsWorkspace.open(context, ideathonId, actor: actor);
  }

  /// Opens Ideathon Evaluation using the existing Judge Scoring UX for [ideathonId].
  static void openIdeathonEvaluation(
    BuildContext context,
    String ideathonId, {
    required UserModel actor,
  }) {
    IdeathonEvaluationWorkspace.open(context, ideathonId, actor: actor);
  }

  /// Opens the Ideathon judge assignment workspace for [ideathonId].
  static void openIdeathonJudgeAssignment(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    IdeathonJudgeAssignmentWorkspace.open(context, ideathonId, actor: actor);
  }

  /// Opens the Ideathon participation payment workspace for [ideathonId].
  static void openIdeathonPayments(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    IdeathonPaymentWorkspace.open(context, ideathonId, actor: actor);
  }

  /// Opens the Ideathon overview workspace for [ideathonId].
  static void openIdeathon(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    IdeathonWorkspace.open(context, ideathonId, actor: actor);
  }

  /// Opens the read-only attachment workspace for [attachmentId].
  static void openAttachment(BuildContext context, String attachmentId) {
    AttachmentWorkspace.push(context, attachmentId);
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceRoute? route = controller.current;
    if (route == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WorkspaceHeader(
          title: route.title,
          subtitle: route.subtitle,
          showBack: true,
          onBack: controller.pop,
          onClose: controller.close,
          helpPageId: route.helpPageId,
        ),
        Expanded(
          child: WorkspaceTransition(
            routeKey: route.id,
            child: _WorkspaceRouteBody(
              key: ValueKey<String>(route.id),
              route: route,
              controller: controller,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceRouteBody extends StatefulWidget {
  const _WorkspaceRouteBody({
    super.key,
    required this.route,
    required this.controller,
  });

  final WorkspaceRoute route;
  final WorkspaceController controller;

  @override
  State<_WorkspaceRouteBody> createState() => _WorkspaceRouteBodyState();
}

class _WorkspaceRouteBodyState extends State<_WorkspaceRouteBody> {
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant _WorkspaceRouteBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id ||
        oldWidget.route.prepare != widget.route.prepare) {
      _ready = false;
      _error = null;
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final Future<void> Function()? prep = widget.route.prepare;
    if (prep == null) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    widget.controller.updateTop(subtitle: WorkspaceRoute.loadingSubtitle);
    try {
      await prep();
      if (mounted) {
        widget.controller.updateTop(subtitle: '');
        setState(() => _ready = true);
      }
    } catch (e) {
      if (mounted) {
        widget.controller.updateTop(subtitle: '');
        setState(() {
          _error = e;
          _ready = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: HkzProgressIndicator(size: 36));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Failed to load: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB93838), fontSize: 13),
          ),
        ),
      );
    }
    return widget.route.builder(context);
  }
}
