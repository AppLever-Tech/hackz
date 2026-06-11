import 'package:flutter/material.dart';

import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../imports/models/import_created_source.dart';
import '../../../screens/common/dashboard_components.dart';
import '../models/problem_list_config.dart';
import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';

/// Stateless filter panel shared by the problem list and Problem Statements
/// table screens.
class ProblemFiltersPanel extends StatelessWidget {
  const ProblemFiltersPanel({
    super.key,
    required this.enabledFilters,
    required this.allDepartments,
    required this.allTags,
    required this.departmentFilters,
    required this.tagFilters,
    required this.statusFilter,
    required this.sourceFilter,
    required this.hasAttachments,
    required this.onDepartmentToggle,
    required this.onTagToggle,
    required this.onStatusChange,
    required this.onSourceChange,
    required this.onAttachmentsChange,
    required this.onClearAll,
    required this.onApply,
    this.compact = false,
  });

  final Set<ProblemFilterType> enabledFilters;
  final List<String> allDepartments;
  final List<String> allTags;
  final Set<String> departmentFilters;
  final Set<String> tagFilters;
  final ProblemStatus? statusFilter;
  final ImportCreatedSource? sourceFilter;
  final bool? hasAttachments;
  final void Function(String department, bool selected) onDepartmentToggle;
  final void Function(String tag, bool selected) onTagToggle;
  final void Function(ProblemStatus? next) onStatusChange;
  final void Function(ImportCreatedSource? next) onSourceChange;
  final void Function(bool? next) onAttachmentsChange;
  final VoidCallback onClearAll;
  final VoidCallback onApply;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool useCompact = MobileFilterPaneStyles.useCompact(context, compact: compact);
    final double sectionGap = MobileFilterPaneStyles.sectionGap(compact: useCompact);
    final double chipGap = MobileFilterPaneStyles.chipGap(compact: useCompact);
    final TextStyle sectionLabel = MobileFilterPaneStyles.sectionLabel(compact: useCompact);

    return MobileFilterPaneStyles.panelShell(
      compact: useCompact,
      decoration: kDashboardCardDecoration.copyWith(
        color: MobileFilterPaneStyles.panelColor,
        borderRadius: MobileFilterPaneStyles.panelBorderRadius(compact: useCompact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (enabledFilters.contains(ProblemFilterType.department)) ...<Widget>[
            Text('Department', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: allDepartments
                  .map(
                    (d) => MobileFilterPaneStyles.filterChip(
                      compact: useCompact,
                      label: d,
                      selected: departmentFilters.contains(d),
                      onSelected: (selected) => onDepartmentToggle(d, selected),
                    ),
                  )
                  .toList(growable: false),
            ),
            SizedBox(height: sectionGap),
          ],
          if (enabledFilters.contains(ProblemFilterType.status)) ...<Widget>[
            Text('Status', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: <Widget>[
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'All',
                  selected: statusFilter == null,
                  onSelected: () => onStatusChange(null),
                ),
                for (final ProblemStatus status in ProblemStatus.lifecycleOrder)
                  MobileFilterPaneStyles.choiceChip(
                    compact: useCompact,
                    label: ProblemStatusHelpers.label(status),
                    selected: statusFilter == status,
                    onSelected: () => onStatusChange(statusFilter == status ? null : status),
                  ),
              ],
            ),
            SizedBox(height: sectionGap),
          ],
          if (enabledFilters.contains(ProblemFilterType.source)) ...<Widget>[
            Text('Source', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: <Widget>[
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'All',
                  selected: sourceFilter == null,
                  onSelected: () => onSourceChange(null),
                ),
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'Manual',
                  selected: sourceFilter == ImportCreatedSource.manual,
                  onSelected: () => onSourceChange(
                    sourceFilter == ImportCreatedSource.manual ? null : ImportCreatedSource.manual,
                  ),
                ),
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'Imported',
                  selected: sourceFilter == ImportCreatedSource.csvImport,
                  onSelected: () => onSourceChange(
                    sourceFilter == ImportCreatedSource.csvImport ? null : ImportCreatedSource.csvImport,
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionGap),
          ],
          if (enabledFilters.contains(ProblemFilterType.tags)) ...<Widget>[
            Text('Tags', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: allTags
                  .map(
                    (tag) => MobileFilterPaneStyles.filterChip(
                      compact: useCompact,
                      label: tag,
                      selected: tagFilters.contains(tag),
                      onSelected: (selected) => onTagToggle(tag, selected),
                    ),
                  )
                  .toList(growable: false),
            ),
            SizedBox(height: sectionGap),
          ],
          if (enabledFilters.contains(ProblemFilterType.attachments)) ...<Widget>[
            Text('Attachments', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: <Widget>[
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'With Attachments',
                  selected: hasAttachments == true,
                  onSelected: () => onAttachmentsChange(
                    hasAttachments == true ? null : true,
                  ),
                ),
                MobileFilterPaneStyles.choiceChip(
                  compact: useCompact,
                  label: 'Without Attachments',
                  selected: hasAttachments == false,
                  onSelected: () => onAttachmentsChange(
                    hasAttachments == false ? null : false,
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionGap),
          ],
          MobileFilterPaneStyles.footer(
            compact: useCompact,
            onClearAll: onClearAll,
            onApply: onApply,
          ),
        ],
      ),
    );
  }
}

/// Wrap of input-chip pills representing the currently applied filter values.
class ProblemActiveFiltersRow extends StatelessWidget {
  const ProblemActiveFiltersRow({
    super.key,
    required this.departmentFilters,
    required this.tagFilters,
    required this.statusFilter,
    required this.sourceFilter,
    required this.hasAttachments,
    required this.onRemoveDepartment,
    required this.onRemoveTag,
    required this.onClearStatus,
    required this.onClearSource,
    required this.onClearAttachments,
  });

  final Set<String> departmentFilters;
  final Set<String> tagFilters;
  final ProblemStatus? statusFilter;
  final ImportCreatedSource? sourceFilter;
  final bool? hasAttachments;
  final void Function(String department) onRemoveDepartment;
  final void Function(String tag) onRemoveTag;
  final VoidCallback onClearStatus;
  final VoidCallback onClearSource;
  final VoidCallback onClearAttachments;

  bool get isEmpty =>
      departmentFilters.isEmpty &&
      tagFilters.isEmpty &&
      statusFilter == null &&
      sourceFilter == null &&
      hasAttachments == null;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ...departmentFilters.map(
          (d) => InputChip(
            label: Text(d),
            onDeleted: () => onRemoveDepartment(d),
          ),
        ),
        ...tagFilters.map(
          (t) => InputChip(
            label: Text(t),
            onDeleted: () => onRemoveTag(t),
          ),
        ),
        if (statusFilter != null)
          InputChip(
            label: Text(ProblemStatusHelpers.label(statusFilter!)),
            onDeleted: onClearStatus,
          ),
        if (sourceFilter != null)
          InputChip(
            label: Text(ProblemStatusHelpers.sourceLabel(sourceFilter!.value)),
            onDeleted: onClearSource,
          ),
        if (hasAttachments != null)
          InputChip(
            label: Text(
              hasAttachments == true ? 'With Attachments' : 'Without Attachments',
            ),
            onDeleted: onClearAttachments,
          ),
      ],
    );
  }
}
