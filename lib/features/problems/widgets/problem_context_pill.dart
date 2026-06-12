import 'package:flutter/material.dart';

import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../models/problem_model.dart';
import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';

/// Workspace launch pill for a problem identifier — status icon + PS number/id.
///
/// Use this anywhere a [ContextPillSemantic.problem] pill shows a problem
/// number or id (not a title). Keeps icon + label formatting consistent.
class ProblemContextPill extends StatelessWidget {
  const ProblemContextPill({
    super.key,
    required this.label,
    required this.onTap,
    this.status,
    this.compact = true,
    this.fitContent,
    this.expandWidth = false,
    this.enabled = true,
    this.maxWidth,
    this.allowHoverScale,
    this.padding,
  });

  factory ProblemContextPill.fromIdentifiers({
    Key? key,
    required String problemNumber,
    String? problemId,
    ProblemStatus? status,
    required VoidCallback onTap,
    bool compact = true,
    bool? fitContent,
    bool expandWidth = false,
    bool enabled = true,
    double? maxWidth,
    bool? allowHoverScale,
    EdgeInsetsGeometry? padding,
  }) {
    return ProblemContextPill(
      key: key,
      label: resolveLabel(problemNumber: problemNumber, problemId: problemId),
      status: status,
      onTap: onTap,
      compact: compact,
      fitContent: fitContent,
      expandWidth: expandWidth,
      enabled: enabled,
      maxWidth: maxWidth,
      allowHoverScale: allowHoverScale,
      padding: padding,
    );
  }

  factory ProblemContextPill.fromProblem({
    Key? key,
    required ProblemModel problem,
    required VoidCallback onTap,
    bool compact = true,
    bool? fitContent,
    bool expandWidth = false,
    bool enabled = true,
    double? maxWidth,
    bool? allowHoverScale,
    EdgeInsetsGeometry? padding,
  }) {
    return ProblemContextPill.fromIdentifiers(
      key: key,
      problemNumber: problem.problemNumber,
      problemId: problem.problemId,
      status: problem.status,
      onTap: onTap,
      compact: compact,
      fitContent: fitContent,
      expandWidth: expandWidth,
      enabled: enabled,
      maxWidth: maxWidth,
      allowHoverScale: allowHoverScale,
      padding: padding,
    );
  }

  /// Standard inset when the pill sits inside a clipped table cell.
  static const EdgeInsets tableCellPadding = EdgeInsets.fromLTRB(3, 0, 6, 0);

  static String resolveLabel({
    required String problemNumber,
    String? problemId,
  }) {
    final String number = problemNumber.trim();
    if (number.isNotEmpty) return number;
    final String id = (problemId ?? '').trim();
    if (id.isNotEmpty) return id;
    return '—';
  }

  final String label;
  final ProblemStatus? status;
  final VoidCallback onTap;
  final bool compact;
  final bool? fitContent;
  final bool expandWidth;
  final bool enabled;
  final double? maxWidth;
  final bool? allowHoverScale;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Widget pill = ContextPill(
      label: label,
      semantic: ContextPillSemantic.problem,
      icon: status != null
          ? ProblemStatusHelpers.icon(status!)
          : ContextPillTheme.iconFor(ContextPillSemantic.problem),
      onTap: onTap,
      compact: compact,
      fitContent: fitContent,
      expandWidth: expandWidth,
      enabled: enabled,
      maxWidth: maxWidth,
      allowHoverScale: allowHoverScale,
    );

    if (padding == null) return pill;
    return Padding(padding: padding!, child: pill);
  }
}
