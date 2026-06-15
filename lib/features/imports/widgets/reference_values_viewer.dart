import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';

/// A single row in the reference values viewer.
class ReferenceValueItem {
  const ReferenceValueItem({
    required this.primary,
    this.secondary,
    this.searchTerms = const <String>[],
  });

  final String primary;
  final String? secondary;
  final List<String> searchTerms;

  bool matchesQuery(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (primary.toLowerCase().contains(q)) return true;
    final String? sub = secondary;
    if (sub != null && sub.toLowerCase().contains(q)) return true;
    for (final String term in searchTerms) {
      if (term.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// Configuration for [showReferenceValuesViewer].
class ReferenceValuesViewerConfig {
  const ReferenceValuesViewerConfig({
    required this.title,
    required this.items,
    this.subtitle,
    this.enableSearch = false,
    this.searchThreshold = 10,
    this.emptyMessage = 'No values available.',
  });

  final String title;
  final String? subtitle;
  final List<ReferenceValueItem> items;
  final bool enableSearch;
  final int searchThreshold;
  final String emptyMessage;

  bool get showSearch => enableSearch && items.length > searchThreshold;
}

/// Opens reference data in a fixed-height dialog (desktop/web) or bottom sheet (mobile).
Future<void> showReferenceValuesViewer({
  required BuildContext context,
  required ReferenceValuesViewerConfig config,
}) {
  final bool isMobile = ResponsiveHelper.isMobile(context);
  final Widget body = ReferenceValuesViewerBody(config: config);

  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        final double height = MediaQuery.sizeOf(sheetContext).height * 0.7;
        return SizedBox(height: height, child: body);
      },
    );
  }

  return showAppDialog<void>(
    context: context,
    barrierDismissible: true,
    width: DialogWidthPreset.standard,
    maxWidth: 480,
    child: SizedBox(height: 420, child: body),
  );
}

/// Scrollable reference list with optional search — used inside dialog or bottom sheet.
class ReferenceValuesViewerBody extends StatefulWidget {
  const ReferenceValuesViewerBody({super.key, required this.config});

  final ReferenceValuesViewerConfig config;

  @override
  State<ReferenceValuesViewerBody> createState() => _ReferenceValuesViewerBodyState();
}

class _ReferenceValuesViewerBodyState extends State<ReferenceValuesViewerBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReferenceValueItem> get _filteredItems {
    if (_query.trim().isEmpty) return widget.config.items;
    return widget.config.items
        .where((ReferenceValueItem item) => item.matchesQuery(_query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ReferenceValuesViewerConfig config = widget.config;
    final List<ReferenceValueItem> items = _filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      config.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    if (config.subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        config.subtitle!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        if (config.showSearch) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search…',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _query.trim().isEmpty ? config.emptyMessage : 'No matches for "$_query".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (BuildContext context, int index) {
                    final ReferenceValueItem item = items[index];
                    return _ReferenceValueRow(item: item);
                  },
                ),
        ),
      ],
    );
  }
}

class _ReferenceValueRow extends StatelessWidget {
  const _ReferenceValueRow({required this.item});

  final ReferenceValueItem item;

  @override
  Widget build(BuildContext context) {
    final String? secondary = item.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: secondary == null || secondary.isEmpty
                ? Text(
                    item.primary,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.primary,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          _ReferenceValueCopyButton(value: item.primary),
        ],
      ),
    );
  }
}

class _ReferenceValueCopyButton extends StatefulWidget {
  const _ReferenceValueCopyButton({required this.value});

  final String value;

  @override
  State<_ReferenceValueCopyButton> createState() => _ReferenceValueCopyButtonState();
}

class _ReferenceValueCopyButtonState extends State<_ReferenceValueCopyButton> {
  static const Duration _copiedDuration = Duration(seconds: 2);

  bool _copied = false;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    _revertTimer?.cancel();
    setState(() => _copied = true);
    _revertTimer = Timer(_copiedDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: HoverIconActionButton(
        key: ValueKey<bool>(_copied),
        icon: _copied ? AppIcons.copied : AppIcons.copy,
        tooltip: _copied ? 'Copied' : 'Copy ${widget.value}',
        iconColor: _copied ? const Color(0xFF047857) : null,
        onTap: _copy,
      ),
    );
  }
}
