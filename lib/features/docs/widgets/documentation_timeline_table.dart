import 'package:flutter/material.dart';

import '../models/doc_models.dart';

/// Responsive documentation table with sticky header feel and mobile scroll.
class DocumentationTable extends StatelessWidget {
  const DocumentationTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width < 720
                ? MediaQuery.sizeOf(context).width - 48
                : 640,
          ),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll<Color>(
              cs.surfaceContainerHighest.withValues(alpha: 0.65),
            ),
            columns: headers
                .map(
                  (String h) => DataColumn(
                    label: Text(
                      h,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            rows: rows
                .map(
                  (List<String> row) => DataRow(
                    cells: row
                        .map(
                          (String cell) => DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                cell,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

/// Vertical / horizontal lifecycle timeline.
class DocumentationTimeline extends StatelessWidget {
  const DocumentationTimeline({
    super.key,
    required this.items,
    this.axis = DocTimelineAxis.vertical,
  });

  final List<({String title, String body, Widget? pill})> items;
  final DocTimelineAxis axis;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    final DocTimelineAxis effective =
        compact ? DocTimelineAxis.vertical : axis;

    if (effective == DocTimelineAxis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              SizedBox(
                width: 220,
                child: _TimelineNode(
                  index: i + 1,
                  title: items[i].title,
                  body: items[i].body,
                  pill: items[i].pill,
                  vertical: false,
                ),
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          _TimelineNode(
            index: i + 1,
            title: items[i].title,
            body: items[i].body,
            pill: items[i].pill,
            vertical: true,
            showConnector: i < items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.index,
    required this.title,
    required this.body,
    required this.vertical,
    this.pill,
    this.showConnector = false,
  });

  final int index;
  final String title;
  final String body;
  final Widget? pill;
  final bool vertical;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget badge = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[cs.primary, cs.secondary],
        ),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: cs.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (pill != null) pill!,
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(fontSize: 13.5, height: 1.45, color: cs.onSurfaceVariant),
        ),
      ],
    );

    if (!vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          badge,
          const SizedBox(height: 10),
          content,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              badge,
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 18 : 0),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
