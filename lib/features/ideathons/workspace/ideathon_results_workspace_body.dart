import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../evaluations/services/evaluation_ranking_service.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../evaluations/widgets/evaluation_results_table_columns.dart';
import '../../events/models/event_kind.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../widgets/ideathon_event_workspace_header.dart';
import 'ideathon_results_workspace_loader.dart';

class IdeathonResultsWorkspaceBody extends StatelessWidget {
  const IdeathonResultsWorkspaceBody({super.key, required this.vm});

  final IdeathonResultsWorkspaceViewModel vm;

  static const EventKind _kind = EventKind.ideathon;
  static const double _metricLabelWidth = 140;
  static const TextStyle _metricValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    height: 1.1,
    color: Color(0xFF0F172A),
  );

  @override
  Widget build(BuildContext context) {
    final EvaluationResultsMetrics metrics = vm.metrics;
    final List<EvaluationResultsRow> rows = vm.rows;
    final EvaluationResultsTableActions actions = EvaluationResultsTableActions(
      onOpenIdea: (EvaluationResultsRow row) {
        WorkspaceNavigator.openEvaluation(
          context,
          row.idea.ideaId,
          ideathonId: vm.event.ideathonId,
        );
      },
    );

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        ideathonEventWorkspaceHeader(
          event: vm.event,
          organisationName: vm.organisationName,
        ),
        const SizedBox(height: 14),
        WorkspaceCollapsibleSection(
          title: 'Evaluation',
          icon: AppIcons.results,
          collapsible: false,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _metric(
                icon: AppIcons.statusEvaluated,
                label: 'Total Evaluated',
                value: '${metrics.totalEvaluated}',
              ),
              _metric(
                icon: AppIcons.clock,
                label: 'Pending Review',
                value: '${metrics.pendingReview}',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: _kind.entriesLabel,
          icon: _kind.entriesIcon,
          count: rows.length,
          child: rows.isEmpty
              ? Text(
                  'No ${_kind.entriesLabel.toLowerCase()} to show.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                )
              : Column(
                  children: rows
                      .map(
                        (EvaluationResultsRow row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EvaluationResultsRowCard(
                            row: row,
                            actions: actions,
                            ideathonScoped: true,
                            showProblemTitle: false,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return EventLabeledField(
      icon: icon,
      label: label,
      value: value,
      labelWidth: _metricLabelWidth,
      valueStyle: _metricValueStyle,
      valueTextAlign: TextAlign.end,
      isLast: isLast,
    );
  }
}
