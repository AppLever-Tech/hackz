import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/icon_only_filter_button.dart';
import 'import_summary_metrics.dart';

enum ImportReviewStatusFilter { all, valid, needsReview, invalid, updates }

class ImportReviewFilterBar extends StatelessWidget {
  const ImportReviewFilterBar({
    super.key,
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ImportReviewStatusFilter filter;
  final ValueChanged<ImportReviewStatusFilter> onFilterChanged;
  final VoidCallback? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return ResponsiveSearchFilterBar(
      searchController: searchController,
      searchHint: 'Search problems',
      showFilterButton: false,
      iconOnlyFilterOnMobile: true,
      onSearchSubmitted: onSearchChanged,
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search problems',
        prefixIcon: const Icon(AppIcons.search, size: 18),
        contentPaddingOverride: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      trailing: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(ImportReviewStatusFilter.all, 'All', ImportSummaryMetrics.lookFor('Extracted').$2),
            _icon(ImportReviewStatusFilter.valid, 'Valid', ImportSummaryMetrics.lookFor('Valid').$2),
            _icon(ImportReviewStatusFilter.needsReview, 'Needs Review', ImportSummaryMetrics.lookFor('Needs review').$2),
            _icon(ImportReviewStatusFilter.invalid, 'Invalid', ImportSummaryMetrics.lookFor('Invalid').$2),
            _icon(ImportReviewStatusFilter.updates, 'Updates', ImportSummaryMetrics.lookFor('Updates').$2),
          ],
        ),
      ],
    );
  }

  Widget _icon(ImportReviewStatusFilter value, String tooltip, IconData icon) {
    final Color color = ImportSummaryMetrics.lookFor(switch (value) {
      ImportReviewStatusFilter.all => 'Extracted',
      ImportReviewStatusFilter.valid => 'Valid',
      ImportReviewStatusFilter.needsReview => 'Needs review',
      ImportReviewStatusFilter.invalid => 'Invalid',
      ImportReviewStatusFilter.updates => 'Updates',
    }).$1;
    return IconOnlyFilterButton(
      icon: icon,
      tooltip: tooltip,
      selected: filter == value,
      color: color,
      onTap: () => onFilterChanged(value),
    );
  }
}
