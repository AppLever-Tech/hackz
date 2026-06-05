import 'package:flutter/material.dart';

import '../../imports/models/import_created_source.dart';
import '../../../screens/common/dashboard_components.dart';
import '../models/problem_list_config.dart';
import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';

/// Stateless filter panel shared by the problem list and Problem Statements
/// table screens.
///
/// State lives in the parent screen; the panel just renders the per-section
/// chip groups (department, status, source, tag, attachments) gated by
/// [ProblemListConfig.enabledFilters] and notifies the parent through
/// [onDepartmentToggle] / [onTagToggle] / [onStatusChange] / [onSourceChange] /
/// [onAttachmentsChange].
/// `Apply` and `Clear All` are also routed through callbacks so each screen
/// owns its own load / reset flow.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration.copyWith(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (enabledFilters.contains(ProblemFilterType.department)) ...<Widget>[
            const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allDepartments
                  .map(
                    (d) => FilterChip(
                      label: Text(d),
                      selected: departmentFilters.contains(d),
                      onSelected: (selected) => onDepartmentToggle(d, selected),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          if (enabledFilters.contains(ProblemFilterType.status)) ...<Widget>[
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('All'),
                  selected: statusFilter == null,
                  onSelected: (_) => onStatusChange(null),
                ),
                for (final ProblemStatus status in ProblemStatus.lifecycleOrder)
                  ChoiceChip(
                    label: Text(ProblemStatusHelpers.label(status)),
                    selected: statusFilter == status,
                    onSelected: (_) => onStatusChange(statusFilter == status ? null : status),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (enabledFilters.contains(ProblemFilterType.source)) ...<Widget>[
            const Text('Source', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('All'),
                  selected: sourceFilter == null,
                  onSelected: (_) => onSourceChange(null),
                ),
                ChoiceChip(
                  label: const Text('Manual'),
                  selected: sourceFilter == ImportCreatedSource.manual,
                  onSelected: (_) => onSourceChange(
                    sourceFilter == ImportCreatedSource.manual ? null : ImportCreatedSource.manual,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Imported'),
                  selected: sourceFilter == ImportCreatedSource.csvImport,
                  onSelected: (_) => onSourceChange(
                    sourceFilter == ImportCreatedSource.csvImport ? null : ImportCreatedSource.csvImport,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (enabledFilters.contains(ProblemFilterType.tags)) ...<Widget>[
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags
                  .map(
                    (tag) => FilterChip(
                      label: Text(tag),
                      selected: tagFilters.contains(tag),
                      onSelected: (selected) => onTagToggle(tag, selected),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          if (enabledFilters.contains(ProblemFilterType.attachments)) ...<Widget>[
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('With Attachments'),
                  selected: hasAttachments == true,
                  onSelected: (_) => onAttachmentsChange(
                    hasAttachments == true ? null : true,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Without Attachments'),
                  selected: hasAttachments == false,
                  onSelected: (_) => onAttachmentsChange(
                    hasAttachments == false ? null : false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: onClearAll, child: const Text('Clear All')),
              const SizedBox(width: 6),
              FilledButton(onPressed: onApply, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wrap of input-chip pills representing the currently applied filter values.
///
/// Designed to sit directly below the [ProblemFiltersPanel] toggle so users
/// can remove individual selections without re-opening the panel. Returns an
/// empty [SizedBox] when nothing is active so callers can place it
/// unconditionally.
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
