import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/filters/hackz_filter_pane.dart';
import '../../imports/models/import_created_source.dart';
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
    required this.allDomains,
    required this.allTags,
    required this.departmentFilters,
    required this.domainFilters,
    required this.tagFilters,
    required this.statusFilter,
    required this.sourceFilter,
    required this.hasAttachments,
    required this.onDepartmentToggle,
    required this.onDomainToggle,
    required this.onTagToggle,
    required this.onStatusChange,
    required this.onSourceChange,
    required this.onAttachmentsChange,
    required this.onClearAll,
    required this.onApply,
  });

  final Set<ProblemFilterType> enabledFilters;
  final List<String> allDepartments;
  /// domainId → display label
  final Map<String, String> allDomains;
  final List<String> allTags;
  final Set<String> departmentFilters;
  final Set<String> domainFilters;
  final Set<String> tagFilters;
  final ProblemStatus? statusFilter;
  final ImportCreatedSource? sourceFilter;
  final bool? hasAttachments;
  final void Function(String department, bool selected) onDepartmentToggle;
  final void Function(String domainId, bool selected) onDomainToggle;
  final void Function(String tag, bool selected) onTagToggle;
  final void Function(ProblemStatus? next) onStatusChange;
  final void Function(ImportCreatedSource? next) onSourceChange;
  final void Function(bool? next) onAttachmentsChange;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return HackzFilterPane(
      onClearAll: onClearAll,
      onApply: onApply,
      sections: <Widget>[
        if (enabledFilters.contains(ProblemFilterType.department))
          HackzFilterSection.chips(
            icon: AppIcons.departments,
            label: 'Department',
            chips: allDepartments
                .map(
                  (String d) => HackzFilterChips.toggle(
                    icon: AppIcons.departments,
                    label: d,
                    selected: departmentFilters.contains(d),
                    onSelected: (bool selected) => onDepartmentToggle(d, selected),
                  ),
                )
                .toList(growable: false),
          ),
        if (enabledFilters.contains(ProblemFilterType.domain) && allDomains.isNotEmpty)
          HackzFilterSection.chips(
            icon: AppIcons.domains,
            label: 'Domain',
            chips: allDomains.entries
                .map(
                  (MapEntry<String, String> e) => HackzFilterChips.toggle(
                    icon: AppIcons.domains,
                    label: e.value,
                    selected: domainFilters.contains(e.key),
                    onSelected: (bool selected) => onDomainToggle(e.key, selected),
                  ),
                )
                .toList(growable: false),
          ),
        if (enabledFilters.contains(ProblemFilterType.status))
          HackzFilterSection.chips(
            icon: AppIcons.filter,
            label: 'Status',
            chips: <Widget>[
              HackzFilterChips.choice(
                label: 'All',
                selected: statusFilter == null,
                onSelected: () => onStatusChange(null),
              ),
              for (final ProblemStatus status in ProblemStatus.lifecycleOrder)
                HackzFilterChips.choice(
                  icon: ProblemStatusHelpers.icon(status),
                  label: ProblemStatusHelpers.label(status),
                  selected: statusFilter == status,
                  onSelected: () => onStatusChange(statusFilter == status ? null : status),
                ),
            ],
          ),
        if (enabledFilters.contains(ProblemFilterType.source))
          HackzFilterSection.chips(
            icon: AppIcons.submissions,
            label: 'Source',
            chips: <Widget>[
              HackzFilterChips.choice(
                label: 'All',
                selected: sourceFilter == null,
                onSelected: () => onSourceChange(null),
              ),
              HackzFilterChips.choice(
                icon: ProblemStatusHelpers.sourceIcon(ImportCreatedSource.manual.value),
                label: 'Manual',
                selected: sourceFilter == ImportCreatedSource.manual,
                onSelected: () => onSourceChange(
                  sourceFilter == ImportCreatedSource.manual ? null : ImportCreatedSource.manual,
                ),
              ),
              HackzFilterChips.choice(
                icon: ProblemStatusHelpers.sourceIcon(ImportCreatedSource.csvImport.value),
                label: 'Imported',
                selected: sourceFilter == ImportCreatedSource.csvImport,
                onSelected: () => onSourceChange(
                  sourceFilter == ImportCreatedSource.csvImport ? null : ImportCreatedSource.csvImport,
                ),
              ),
            ],
          ),
        if (enabledFilters.contains(ProblemFilterType.tags))
          HackzFilterSection.chips(
            icon: AppIcons.tags,
            label: 'Tags',
            chips: allTags
                .map(
                  (String tag) => HackzFilterChips.toggle(
                    icon: AppIcons.tags,
                    label: tag,
                    selected: tagFilters.contains(tag),
                    onSelected: (bool selected) => onTagToggle(tag, selected),
                  ),
                )
                .toList(growable: false),
          ),
        if (enabledFilters.contains(ProblemFilterType.attachments))
          HackzFilterSection.chips(
            icon: AppIcons.attachments,
            label: 'Attachments',
            chips: <Widget>[
              HackzFilterChips.choice(
                icon: AppIcons.attachments,
                label: 'With Attachments',
                selected: hasAttachments == true,
                onSelected: () => onAttachmentsChange(hasAttachments == true ? null : true),
              ),
              HackzFilterChips.choice(
                label: 'Without Attachments',
                selected: hasAttachments == false,
                onSelected: () => onAttachmentsChange(hasAttachments == false ? null : false),
              ),
            ],
          ),
      ],
    );
  }
}

/// Wrap of input-chip pills representing the currently applied filter values.
class ProblemActiveFiltersRow extends StatelessWidget {
  const ProblemActiveFiltersRow({
    super.key,
    required this.departmentFilters,
    required this.domainFilters,
    required this.domainLabels,
    required this.tagFilters,
    required this.statusFilter,
    required this.sourceFilter,
    required this.hasAttachments,
    required this.onRemoveDepartment,
    required this.onRemoveDomain,
    required this.onRemoveTag,
    required this.onClearStatus,
    required this.onClearSource,
    required this.onClearAttachments,
  });

  final Set<String> departmentFilters;
  final Set<String> domainFilters;
  final Map<String, String> domainLabels;
  final Set<String> tagFilters;
  final ProblemStatus? statusFilter;
  final ImportCreatedSource? sourceFilter;
  final bool? hasAttachments;
  final void Function(String department) onRemoveDepartment;
  final void Function(String domainId) onRemoveDomain;
  final void Function(String tag) onRemoveTag;
  final VoidCallback onClearStatus;
  final VoidCallback onClearSource;
  final VoidCallback onClearAttachments;

  bool get isEmpty =>
      departmentFilters.isEmpty &&
      domainFilters.isEmpty &&
      tagFilters.isEmpty &&
      statusFilter == null &&
      sourceFilter == null &&
      hasAttachments == null;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return HackzActiveFiltersRow(
      chips: <Widget>[
        ...departmentFilters.map(
          (String d) => HackzFilterChips.applied(
            icon: AppIcons.departments,
            label: d,
            onDeleted: () => onRemoveDepartment(d),
          ),
        ),
        ...domainFilters.map(
          (String id) => HackzFilterChips.applied(
            icon: AppIcons.domains,
            label: domainLabels[id] ?? id,
            onDeleted: () => onRemoveDomain(id),
          ),
        ),
        ...tagFilters.map(
          (String t) => HackzFilterChips.applied(
            icon: AppIcons.tags,
            label: t,
            onDeleted: () => onRemoveTag(t),
          ),
        ),
        if (statusFilter != null)
          HackzFilterChips.applied(
            icon: ProblemStatusHelpers.icon(statusFilter!),
            label: ProblemStatusHelpers.label(statusFilter!),
            onDeleted: onClearStatus,
          ),
        if (sourceFilter != null)
          HackzFilterChips.applied(
            icon: ProblemStatusHelpers.sourceIcon(sourceFilter!.value),
            label: ProblemStatusHelpers.sourceLabel(sourceFilter!.value),
            onDeleted: onClearSource,
          ),
        if (hasAttachments != null)
          HackzFilterChips.applied(
            icon: AppIcons.attachments,
            label: hasAttachments == true ? 'With Attachments' : 'Without Attachments',
            onDeleted: onClearAttachments,
          ),
      ],
    );
  }
}
