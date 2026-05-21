import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/status_styles.dart';
import '../core/theme/app_semantic_colors.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/score_model.dart';
import '../screens/common/dashboard_components.dart';
import '../utils/idea_query_service.dart';
import 'common/context_pill.dart';
import 'common/context_pill_metrics.dart';
import 'common/context_pill_theme.dart';

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

  static const double _labelWidth = 55;

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

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.2,
    height: 1.2,
  );

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
          _FormValueRow(
            labelWidth: _labelWidth,
            label: 'Idea:',
            child: onOpenIdea != null
                ? _workspacePill(ideaTitle, ContextPillSemantic.idea, onOpenIdea!, fullWidth: true)
                : _plainValue(ideaTitle),
          ),
          const SizedBox(height: 8),
          _FormValueRow(
            labelWidth: _labelWidth,
            label: 'Problem:',
            child: onOpenProblem != null
                ? _workspacePill(problemTitle, ContextPillSemantic.problem, onOpenProblem!, fullWidth: true)
                : _plainValue(problemTitle),
          ),
          const SizedBox(height: 8),
          _FormValueRow(
            labelWidth: _labelWidth,
            label: null,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (onOpenTeam != null)
                  _workspacePill(teamLabel, ContextPillSemantic.team, onOpenTeam!)
                else
                  _statusMeta('Team: $teamLabel'),
                if (onOpenPayment != null)
                  _workspacePill(_paymentPillLabel(payment), ContextPillSemantic.payment, onOpenPayment!)
                else
                  _statusMeta(_paymentPillLabel(payment)),
                if (onOpenEvaluation != null)
                  _workspacePill(_evaluationPillLabel(idea, score), ContextPillSemantic.evaluation, onOpenEvaluation!),
                if (onOpenAttachments != null && item.attachmentCount > 0)
                  _workspacePill(
                    '${item.attachmentCount} Attachment${item.attachmentCount == 1 ? '' : 's'}',
                    ContextPillSemantic.generic,
                    onOpenAttachments!,
                    icon: AppIcons.attachments,
                  )
                else if (item.attachmentCount == 0)
                  _statusMeta('No attachments'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FormValueRow(
            labelWidth: _labelWidth,
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

  static IconData _iconForSemantic(ContextPillSemantic semantic, {IconData? override}) {
    if (override != null) return override;
    return ContextPillTheme.iconFor(semantic);
  }

  static Widget _workspacePill(
    String label,
    ContextPillSemantic semantic,
    VoidCallback onTap, {
    bool fullWidth = false,
    IconData? icon,
  }) {
    final Widget pill = ContextPill(
      label: label,
      semantic: semantic,
      icon: _iconForSemantic(semantic, override: icon),
      onTap: onTap,
      compact: true,
      height: ContextPillMetrics.height,
      fitContent: !fullWidth,
      expandWidth: fullWidth,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: ContextPillMetrics.height, child: pill);
    }
    return pill;
  }

  static Widget _plainValue(String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  static Widget _statusMeta(String label) {
    return SizedBox(
      height: ContextPillMetrics.height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppSemanticColors.statusSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppSemanticColors.statusBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppSemanticColors.statusText),
          ),
        ),
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

/// Label column + value column (values share the same left edge).
class _FormValueRow extends StatelessWidget {
  const _FormValueRow({
    required this.labelWidth,
    required this.child,
    this.label,
  });

  final double labelWidth;
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: label == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label!, style: IdeaCard._labelStyle),
                ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}
