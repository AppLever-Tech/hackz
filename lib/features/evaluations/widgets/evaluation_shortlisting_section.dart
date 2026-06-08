import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../shared/feedback/feedback.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../models/evaluation_details_view_model.dart';
import '../services/idea_shortlisting_service.dart';

/// Department-admin shortlist / reject actions for an evaluated idea.
class EvaluationShortlistingSection extends StatefulWidget {
  const EvaluationShortlistingSection({
    super.key,
    required this.vm,
    required this.onUpdated,
  });

  final EvaluationDetailsViewModel vm;
  final VoidCallback onUpdated;

  @override
  State<EvaluationShortlistingSection> createState() => _EvaluationShortlistingSectionState();
}

class _EvaluationShortlistingSectionState extends State<EvaluationShortlistingSection> {
  bool _saving = false;

  Future<void> _shortlist() async {
    if (_saving) return;
    setState(() => _saving = true);
    await IdeaShortlistingService.shortlistIdea(widget.vm.ideaId);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onUpdated();
    FeedbackService.showSuccess(context, title: 'Shortlisted', message: 'Idea moved to shortlisted.');
  }

  Future<void> _reject() async {
    if (_saving) return;
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Reject idea?',
      message: 'This idea will be marked as rejected.',
      confirmLabel: 'Reject',
      dangerConfirm: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    await IdeaShortlistingService.rejectIdea(widget.vm.ideaId);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onUpdated();
    FeedbackService.showSuccess(context, title: 'Rejected', message: 'Idea marked as rejected.');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.vm.canShortlist) return const SizedBox.shrink();

    final IdeaStatus status = widget.vm.status;
    final Color statusColor = IdeaStatusHelpers.color(status);
    final bool canAct = status == IdeaStatus.evaluated;
    final String? rankLabel = widget.vm.evaluationRank != null && widget.vm.evaluationRank! > 0
        ? '#${widget.vm.evaluationRank}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Shortlisting',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (rankLabel != null)
                _infoChip('Rank', rankLabel, const Color(0xFFD97706)),
              _infoChip('Status', widget.vm.statusLabel, statusColor),
            ],
          ),
          if (canAct) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ProblemWorkflowActionPill(
                  label: 'Shortlist',
                  icon: AppIcons.statusShortlisted,
                  semantic: ProblemWorkflowPillSemantic.primary,
                  enabled: !_saving,
                  onTap: _saving ? null : _shortlist,
                ),
                ProblemWorkflowActionPill(
                  label: 'Reject',
                  icon: AppIcons.statusRejected,
                  semantic: ProblemWorkflowPillSemantic.pending,
                  enabled: !_saving,
                  onTap: _saving ? null : _reject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$label ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
