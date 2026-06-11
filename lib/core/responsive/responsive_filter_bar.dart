import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import 'responsive_helper.dart';

/// Search field + filter toggle; stacks on narrow widths.
class ResponsiveSearchFilterBar extends StatelessWidget {
  const ResponsiveSearchFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    this.filtersExpanded = false,
    this.onToggleFilters,
    this.leading = const <Widget>[],
    this.trailing = const <Widget>[],
    this.filterLabel,
    this.onSearchSubmitted,
    this.showFilterButton = true,
    this.iconOnlyFilterOnMobile = false,
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool filtersExpanded;
  final VoidCallback? onToggleFilters;
  final List<Widget> leading;
  final List<Widget> trailing;
  final String? filterLabel;
  final VoidCallback? onSearchSubmitted;
  final bool showFilterButton;
  final bool iconOnlyFilterOnMobile;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool useIconOnlyFilter = mobile && iconOnlyFilterOnMobile;

    final Widget? filterButton = showFilterButton && onToggleFilters != null
        ? useIconOnlyFilter
            ? IconButton(
                onPressed: onToggleFilters,
                tooltip: filterLabel ?? (filtersExpanded ? 'Hide filters' : 'Filters'),
                icon: Icon(Icons.tune, color: filtersExpanded ? const Color(0xFF6A38FF) : const Color(0xFF475569)),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: filtersExpanded ? const Color(0xFFE8ECFF) : const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: filtersExpanded ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0)),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onToggleFilters,
                icon: const Icon(Icons.tune),
                label: Text(filterLabel ?? (filtersExpanded ? 'Hide Filters' : 'Filters')),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, mobile ? 40 : 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
        : null;

    final searchField = TextField(
      controller: searchController,
      onSubmitted: onSearchSubmitted == null ? null : (_) => onSearchSubmitted!(),
      decoration: InputDecoration(
        hintText: searchHint,
        prefixIcon: const Icon(AppIcons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: ResponsiveHelper.isMobile(context) ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    if (mobile && useIconOnlyFilter) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leading.isNotEmpty) ...leading.expand((Widget w) => <Widget>[w, const SizedBox(width: 8)]),
          Expanded(child: searchField),
          if (trailing.isNotEmpty) ...trailing.map((Widget w) => Padding(padding: const EdgeInsets.only(left: 8), child: w)),
          if (filterButton != null) ...<Widget>[const SizedBox(width: 8), filterButton],
        ],
      );
    }

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (leading.isNotEmpty) ...<Widget>[
            Wrap(spacing: 8, runSpacing: 8, children: leading),
            const SizedBox(height: 8),
          ],
          searchField,
          if (trailing.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: trailing),
          ],
          if (filterButton != null) ...<Widget>[
            const SizedBox(height: 8),
            filterButton,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...leading.expand(
          (Widget w) => <Widget>[w, const SizedBox(width: 8)],
        ),
        Expanded(child: searchField),
        if (trailing.isNotEmpty) ...<Widget>[
          const SizedBox(width: 8),
          ...trailing.map(
            (w) => Padding(padding: const EdgeInsets.only(left: 8), child: w),
          ),
        ],
        if (filterButton != null) ...<Widget>[
          const SizedBox(width: 8),
          filterButton,
        ],
      ],
    );
  }
}

/// Horizontal chip row that wraps on mobile; optional horizontal scroll on desktop-only rows.
class ResponsiveFilterChipRow extends StatelessWidget {
  const ResponsiveFilterChipRow({
    super.key,
    required this.children,
    this.allowHorizontalScroll = false,
  });

  final List<Widget> children;
  final bool allowHorizontalScroll;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (allowHorizontalScroll && ResponsiveHelper.isDesktopOrWider(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _spaced(children, 8)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

List<Widget> _spaced(List<Widget> items, double gap) {
  final out = <Widget>[];
  for (int i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(width: gap));
    out.add(items[i]);
  }
  return out;
}

/// Toolbar that wraps on mobile (title, actions, sort controls).
class ResponsiveWrapToolbar extends StatelessWidget {
  const ResponsiveWrapToolbar({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
