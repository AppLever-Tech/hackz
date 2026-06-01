import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/idea_model.dart';
import '../../../models/payment_model.dart';
import '../../../models/score_model.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';
import '../services/idea_query_service.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../widgets/common/form_value_row.dart';

/// Compact contextual idea feed card (workspace pills).
class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.item,
    this.onOpenIdea,
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
    final String teamLabel = item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();

    final bool showActions = (showUploadPayment && onUploadPayment != null) || (showEvaluate && onEvaluate != null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildIdeaTitle(ideaTitle),
                    const SizedBox(height: 8),
                    _buildContextPills(
                      context,
                      idea: idea,
                      score: score,
                      payment: payment,
                      teamLabel: teamLabel,
                    ),
                  ],
                ),
              ),
              if (showActions) ...<Widget>[
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaTitle(String ideaTitle) {
    if (onOpenIdea != null) {
      return EntityCardPills.workspace(
        ideaTitle,
        ContextPillSemantic.idea,
        onOpenIdea!,
        fullWidth: true,
        icon: AppIcons.ideas,
      );
    }
    return Text(
      ideaTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: EntityCardStyles.plainValue,
    );
  }

  Widget _buildContextPills(
    BuildContext context, {
    required IdeaModel idea,
    required ScoreModel? score,
    required PaymentModel? payment,
    required String teamLabel,
  }) {
    final List<Widget> pills = <Widget>[];

    if (onOpenTeam != null) {
      pills.add(
        EntityCardPills.workspace(teamLabel, ContextPillSemantic.team, onOpenTeam!, icon: AppIcons.teams),
      );
    } else {
      pills.add(EntityCardPills.meta(teamLabel, icon: AppIcons.teams));
    }

    if (onOpenPayment != null) {
      pills.add(
        EntityCardPills.workspace(
          _paymentPillLabel(payment),
          ContextPillSemantic.payment,
          onOpenPayment!,
          icon: AppIcons.payments,
        ),
      );
    } else {
      pills.add(EntityCardPills.meta(_paymentPillLabel(payment), icon: AppIcons.payments));
    }

    if (onOpenEvaluation != null) {
      pills.add(
        EntityCardPills.workspace(
          _evaluationPillLabel(idea, score),
          ContextPillSemantic.evaluation,
          onOpenEvaluation!,
          icon: AppIcons.scoring,
        ),
      );
    }

    if (onOpenAttachments != null && item.attachmentCount > 0) {
      pills.add(
        EntityCardPills.workspace(
          '${item.attachmentCount} Attachment${item.attachmentCount == 1 ? '' : 's'}',
          ContextPillSemantic.generic,
          onOpenAttachments!,
          icon: AppIcons.attachments,
        ),
      );
    } else if (item.attachmentCount == 0) {
      pills.add(EntityCardPills.meta('No attachments', icon: AppIcons.attachments));
    }

    if (ResponsiveHelper.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _stackedPills(pills),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _spacedPills(pills),
      ),
    );
  }

  static List<Widget> _spacedPills(List<Widget> pills) {
    if (pills.isEmpty) return pills;
    final List<Widget> spaced = <Widget>[pills.first];
    for (var i = 1; i < pills.length; i++) {
      spaced.add(const SizedBox(width: 6));
      spaced.add(pills[i]);
    }
    return spaced;
  }

  static List<Widget> _stackedPills(List<Widget> pills) {
    if (pills.isEmpty) return pills;
    final List<Widget> stacked = <Widget>[pills.first];
    for (var i = 1; i < pills.length; i++) {
      stacked.add(const SizedBox(height: 6));
      stacked.add(pills[i]);
    }
    return stacked;
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
}
