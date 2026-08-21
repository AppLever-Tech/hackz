import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_prototype_service.dart';
import '../widgets/ideathon_status_pill.dart';
import '../widgets/ideathon_type_pill.dart';
import 'ideathon_workspace_loader.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

class IdeathonWorkspaceBody extends StatelessWidget {
  const IdeathonWorkspaceBody({
    super.key,
    required this.vm,
    this.onRefresh,
    this.actor,
    this.onOpenPayments,
    this.onOpenJudgeAssignment,
    this.onOpenEvaluation,
    this.onOpenResults,
  });

  final IdeathonWorkspaceViewModel vm;
  final VoidCallback? onRefresh;
  final UserModel? actor;
  final VoidCallback? onOpenPayments;
  final VoidCallback? onOpenJudgeAssignment;
  final VoidCallback? onOpenEvaluation;
  final VoidCallback? onOpenResults;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final ideathon = vm.ideathon;

    return ListView(
      padding: EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 24),
      children: <Widget>[
        ResponsiveMetricGrid(
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Total Ideas',
              value: '${ideathon.ideaCount}',
              color: const Color(0xFF4A67FF),
              icon: AppIcons.ideas,
            ),
            DashboardMetricChipData.single(
              label: 'Assigned Judges',
              value: '${ideathon.judgeCount}',
              color: const Color(0xFF7C3AED),
              icon: AppIcons.judges,
            ),
            DashboardMetricChipData.single(
              label: 'Coordinators',
              value: '${ideathon.coordinatorCount}',
              color: const Color(0xFF059669),
              icon: AppIcons.coordinator,
            ),
            DashboardMetricChipData.single(
              label: 'Evaluation Progress',
              value: '${(vm.evaluationProgressPct * 100).round()}%',
              color: const Color(0xFFEA580C),
              icon: AppIcons.scoring,
              subtitle: vm.evaluationProgressLabel,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Event Overview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ideathon.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  IdeathonTypePill(type: ideathon.ideathonType, compact: false),
                  IdeathonStatusPill(status: ideathon.status, compact: false),
                ],
              ),
              const SizedBox(height: 10),
              _detailRow('Department', ideathon.departmentId.isEmpty ? '—' : ideathon.departmentId),
              _detailRow('Starts', formatDateTime(ideathon.startDateTime.toLocal())),
              _detailRow('Ends', formatDateTime(ideathon.endDateTime.toLocal())),
              if (ideathon.description.trim().isNotEmpty)
                _detailRow('Description', ideathon.description.trim()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Judge Assignment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Assign judges to ideas registered for this Ideathon. Uses the Ideathon evaluation template (read-only).',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ProblemWorkflowActionPill(
                  label: 'Open Judge Assignment',
                  icon: AppIcons.judges,
                  semantic: ProblemWorkflowPillSemantic.filledBrand,
                  onTap: onOpenJudgeAssignment,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Evaluation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Judges score only ideas assigned to them for this Ideathon, using the Ideathon evaluation template.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ProblemWorkflowActionPill(
                  label: 'Open Ideathon Evaluation',
                  icon: AppIcons.scoring,
                  semantic: ProblemWorkflowPillSemantic.filledBrand,
                  onTap: onOpenEvaluation,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Evaluation Results',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Review Ideathon-scoped scores, completion status, and judge feedback for registered ideas. Results from other events are never included.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ProblemWorkflowActionPill(
                  label: 'Open Ideathon Evaluation Results',
                  icon: AppIcons.results,
                  semantic: ProblemWorkflowPillSemantic.filledBrand,
                  onTap: onOpenResults,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Payments',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Review idea payment status for ideas in this Ideathon. Payments are completed and verified before ideas can be added at create time.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ProblemWorkflowActionPill(
                  label: 'Open Ideathon Payments',
                  icon: AppIcons.payments,
                  semantic: ProblemWorkflowPillSemantic.filledBrand,
                  onTap: onOpenPayments,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Ideas',
          child: Column(
            children: ideathon.ideas
                .map(
                  (snapshot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ideaRow(context, snapshot.ideaId, snapshot.ideaTitle, snapshot.problemTitle, snapshot.teamName),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Judges',
          child: _peopleList(context, vm.judges),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Coordinators',
          child: _peopleList(context, vm.coordinators),
        ),
      ],
    );
  }

  Widget _ideaRow(
    BuildContext context,
    String ideaId,
    String title,
    String problem,
    String team,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: ideaId.isEmpty ? null : () => WorkspaceNavigator.openIdea(context, ideaId),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text('$problem · $team', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            children: <Widget>[
              ProblemWorkflowActionPill(
                label: 'Prototype',
                semantic: ProblemWorkflowPillSemantic.filledBrand,
                onTap: ideaId.isEmpty
                    ? null
                    : () async {
                        await IdeathonPrototypeService.selectPrototype(ideaId: ideaId);
                        onRefresh?.call();
                      },
              ),
              ProblemWorkflowActionPill(
                label: 'Remove',
                semantic: ProblemWorkflowPillSemantic.closed,
                onTap: ideaId.isEmpty
                    ? null
                    : () async {
                        await IdeathonPrototypeService.removePrototype(ideaId: ideaId);
                        onRefresh?.call();
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _peopleList(BuildContext context, List<UserModel> users) {
    if (users.isEmpty) return const Text('—', style: TextStyle(color: Color(0xFF64748B)));
    return Column(
      children: users
          .map(
            (UserModel user) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  UserWorkspaceAvatar(
                    user: user,
                    radius: 14,
                    onTap: () => WorkspaceNavigator.openUser(context, user.userId),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(userDisplayName(user), style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
