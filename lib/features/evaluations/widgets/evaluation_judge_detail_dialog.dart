import 'package:flutter/material.dart';

import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../workspace/evaluation_workspace_loader.dart';
import '../models/evaluation_details_view_model.dart';
import 'evaluation_criterion_readonly_view.dart';
import 'judge_type_pill.dart';

/// Read-only full template criteria for one judge evaluation.
Future<void> showEvaluationJudgeDetailDialog(
  BuildContext context,
  EvaluationJudgeDetail detail, {
  required String departmentCode,
}) {
  return showAppDialog<void>(
    context: context,
    width: DialogWidthPreset.wide,
    child: _EvaluationJudgeDetailDialogContent(
      detail: detail,
      departmentCode: departmentCode,
    ),
  );
}

class _EvaluationJudgeDetailDialogContent extends StatefulWidget {
  const _EvaluationJudgeDetailDialogContent({
    required this.detail,
    required this.departmentCode,
  });

  final EvaluationJudgeDetail detail;
  final String departmentCode;

  @override
  State<_EvaluationJudgeDetailDialogContent> createState() =>
      _EvaluationJudgeDetailDialogContentState();
}

class _EvaluationJudgeDetailDialogContentState extends State<_EvaluationJudgeDetailDialogContent> {
  late Future<EvaluationJudgeCriteriaDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = EvaluationWorkspaceLoader.loadJudgeCriteriaDetail(
      widget.detail.scoreId,
      departmentCode: widget.departmentCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EvaluationJudgeDetail detail = widget.detail;
    final double maxDialogHeight = MediaQuery.sizeOf(context).height * 0.65;

    return FutureBuilder<EvaluationJudgeCriteriaDetail>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<EvaluationJudgeCriteriaDetail> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: HkzProgressIndicator(size: 32)),
          );
        }

        if (snapshot.hasError) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Unable to load evaluation',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '${snapshot.error}',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          );
        }

        final EvaluationJudgeCriteriaDetail loaded = snapshot.data!;
        final double overall = loaded.entry.overallScore;
        final int scale = loaded.template.scoringScale;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              loaded.entry.judgeName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                JudgeTypePill(judgeType: detail.judgeType, compact: false),
                Text(
                  formatDateTime(loaded.entry.evaluatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Overall ${overall.toStringAsFixed(1)} / $scale',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6A38FF),
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              child: SingleChildScrollView(
                child: EvaluationCriterionReadonlyView(
                  score: loaded.score,
                  template: loaded.template,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }
}
