import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/status_styles.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/score_model.dart';
import '../screens/common/dashboard_components.dart';
import '../utils/idea_query_service.dart';
import 'common/context_pill_theme.dart';
import 'common/entity_card_pills.dart';
import 'common/form_value_row.dart';

/// Compact contextual idea feed card (form-aligned labels + workspace pills).
class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.item,
    this.onOpenIdea,
    this.onOpenProblem,
    this.onOpenTeam,
    this.onOpenPayment,
    this.onOpenEvaluation,
    this.onOpenAttachments,
    this.onEvaluate,
    this.onUploadPayment,
    this.showEvaluate = false,
    this.showUploadPayment = false,
  });

  final IdeaListItem item;
  final VoidCallback? onOpenIdea;
  final VoidCallback? onOpenProblem;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onOpenPayment;
  final VoidCallback? onOpenEvaluation;
  final VoidCallback? onOpenAttachments;
  final VoidCallback? onEvaluate;
  final VoidCallback? onUploadPayment;
  final bool showEvaluate;
  final bool showUploadPayment;

  @override
  Widget build(BuildContext context) {
    final IdeaModel idea = item.idea;
    final PaymentModel? payment = item.payment;
    final ScoreModel? score = item.score;

    final String ideaTitle = idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : idea.ideaTitle.trim();
    final String problemTitle = idea.problemTitle.trim().isEmpty
        ? (idea.problemNumber.trim().isEmpty ? 'Problem' : idea.problemNumber.trim())
        : idea.problemTitle.trim();
    final String teamLabel = item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FormValueRow(
            labelWidth: EntityCardStyles.labelWidth,
            label: 'Idea',
            child: onOpenIdea != null
                ? EntityCardPills.workspace(ideaTitle, ContextPillSemantic.idea, onOpenIdea!, fullWidth: true)
                : EntityCardPills.plainValue(ideaTitle),
          ),
          const SizedBox(height: 8),
          FormValueRow(
            labelWidth: EntityCardStyles.labelWidth,
            label: 'Problem',
            child: onOpenProblem != null
                ? EntityCardPills.workspace(problemTitle, ContextPillSemantic.problem, onOpenProblem!, fullWidth: true)
                : EntityCardPills.plainValue(problemTitle),
          ),
          const SizedBox(height: 8),
          FormValueRow(
            labelWidth: EntityCardStyles.labelWidth,
            label: null,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (onOpenTeam != null)
                  EntityCardPills.workspace(teamLabel, ContextPillSemantic.team, onOpenTeam!)
                else
                  EntityCardPills.meta('Team: $teamLabel', icon: AppIcons.teams),
                if (onOpenPayment != null)
                  EntityCardPills.workspace(_paymentPillLabel(payment), ContextPillSemantic.payment, onOpenPayment!)
                else
                  EntityCardPills.meta(_paymentPillLabel(payment), icon: AppIcons.payments),
                if (onOpenEvaluation != null)
                  EntityCardPills.workspace(
                    _evaluationPillLabel(idea, score),
                    ContextPillSemantic.evaluation,
                    onOpenEvaluation!,
                  ),
                if (onOpenAttachments != null && item.attachmentCount > 0)
                  EntityCardPills.workspace(
                    '${item.attachmentCount} Attachment${item.attachmentCount == 1 ? '' : 's'}',
                    ContextPillSemantic.generic,
                    onOpenAttachments!,
                    icon: AppIcons.attachments,
                  )
                else if (item.attachmentCount == 0)
                  EntityCardPills.meta('No attachments', icon: AppIcons.attachments),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FormValueRow(
            labelWidth: EntityCardStyles.labelWidth,
            label: null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _footerMeta(idea, score),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                if (showUploadPayment && onUploadPayment != null)
                  IconButton(
                    tooltip: 'Upload payment',
                    onPressed: onUploadPayment,
                    icon: const Icon(AppIcons.payments, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (showEvaluate && onEvaluate != null)
                  IconButton(
                    tooltip: 'Evaluate',
                    onPressed: onEvaluate,
                    icon: const Icon(AppIcons.scoring, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _paymentPillLabel(PaymentModel? payment) {
    if (payment == null) return 'No payment';
    return switch (payment.status) {
      PaymentRecordStatus.pending => 'Payment pending',
      PaymentRecordStatus.verified => 'Payment verified',
      PaymentRecordStatus.rejected => 'Payment rejected',
    };
  }

  static String _evaluationPillLabel(IdeaModel idea, ScoreModel? score) {
    if (score != null) {
      return 'Score ${score.score.toStringAsFixed(0)}';
    }
    return switch (idea.status) {
      IdeaStatus.evaluated || IdeaStatus.approved => 'Evaluation complete',
      IdeaStatus.underReview => 'Under review',
      _ => 'Pending evaluation',
    };
  }

  static String _footerMeta(IdeaModel idea, ScoreModel? score) {
    final String status = StatusStyles.labelForIdeaStatus(idea.status);
    final String? scorePart = score != null ? 'Score ${score.score.toStringAsFixed(0)}' : null;
    final String age = _relativeAge(idea.createdAt);
    return <String>[status, if (scorePart != null) scorePart, age].join(' • ');
  }

  static String _relativeAge(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Today';
  }
}
