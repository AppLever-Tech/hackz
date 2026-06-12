import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../utils/common_helpers.dart';
import '../../user/models/user_model.dart';
import '../models/evaluation_details_view_model.dart';
import 'evaluation_judge_detail_dialog.dart';
import 'judge_type_pill.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Compact judge row — full criteria open in read-only dialog.
class EvaluationResultCard extends StatelessWidget {
  const EvaluationResultCard({
    super.key,
    required this.detail,
    required this.departmentCode,
    this.compact = false,
  });

  final EvaluationJudgeDetail detail;
  final String departmentCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final double overall = detail.entry.overallScore;
    final int scale = detail.scoringScale;
    final String judgeName = detail.entry.judgeName.trim().isEmpty ? '—' : detail.entry.judgeName.trim();
    final String judgeId = detail.entry.judgeId.trim();
    final String evaluatedLabel = formatDateTime(detail.entry.evaluatedAt);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 12, vertical: mobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: compact
          ? _buildCompact(
              context,
              judgeName: judgeName,
              judgeId: judgeId,
              overall: overall,
              scale: scale,
            )
          : mobile
              ? _buildMobile(
                  context,
                  judgeName: judgeName,
                  judgeId: judgeId,
                  evaluatedLabel: evaluatedLabel,
                  overall: overall,
                  scale: scale,
                )
              : _buildDesktop(
                  context,
                  judgeName: judgeName,
                  judgeId: judgeId,
                  evaluatedLabel: evaluatedLabel,
                  overall: overall,
                  scale: scale,
                ),
    );
  }

  Widget _buildCompact(
    BuildContext context, {
    required String judgeName,
    required String judgeId,
    required double overall,
    required int scale,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _judgeAvatar(context, judgeId),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            judgeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ),
        const SizedBox(width: 8),
        _scoreText(overall, scale),
      ],
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required String judgeName,
    required String judgeId,
    required String evaluatedLabel,
    required double overall,
    required int scale,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              _judgeIcon(),
              const SizedBox(width: 8),
              _judgeAvatar(context, judgeId),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  judgeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 10),
              JudgeTypePill(judgeType: detail.judgeType),
              const SizedBox(width: 10),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  evaluatedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
        _viewButton(context),
        const SizedBox(width: 4),
        _scoreText(overall, scale),
      ],
    );
  }

  Widget _buildMobile(
    BuildContext context, {
    required String judgeName,
    required String judgeId,
    required String evaluatedLabel,
    required double overall,
    required int scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _judgeIcon(),
            const SizedBox(width: 8),
            _judgeAvatar(context, judgeId),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                judgeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            _viewButton(context),
            const SizedBox(width: 4),
            _scoreText(overall, scale),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              JudgeTypePill(judgeType: detail.judgeType),
              Text(
                evaluatedLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _judgeIcon() {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(AppIcons.judges, size: 16, color: Color(0xFF4338CA)),
    );
  }

  Widget _judgeAvatar(BuildContext context, String judgeId) {
    final UserModel? user = detail.judgeUser;
    if (user != null && judgeId.isNotEmpty) {
      return UserWorkspaceAvatar(
        user: user,
        radius: 12,
        ringPadding: 2,
        onTap: () => WorkspaceNavigator.openUser(context, judgeId),
      );
    }
    final String initial = detail.entry.judgeName.trim().isEmpty
        ? '?'
        : detail.entry.judgeName.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFEEF2FF),
      child: Text(
        initial,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
      ),
    );
  }

  Widget _viewButton(BuildContext context) {
    return IconButton(
      onPressed: () => showEvaluationJudgeDetailDialog(
        context,
        detail,
        departmentCode: departmentCode,
      ),
      icon: const Icon(AppIcons.preview, size: 20),
      tooltip: 'View evaluation details',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: const Color(0xFF64748B),
    );
  }

  Widget _scoreText(double overall, int scale) {
    return Text(
      '${overall.toStringAsFixed(1)}/$scale',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF6A38FF)),
    );
  }
}
