import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'workspace_attachment_counts.dart';

/// Read-only attachment breakdown (count per type). No preview or download actions.
class WorkspaceAttachmentsSummary extends StatelessWidget {
  const WorkspaceAttachmentsSummary({
    super.key,
    required this.counts,
    this.title = 'Attachments',
    this.emptyMessage = 'No attachments.',
    this.footerLines = const <String>[],
  });

  final WorkspaceAttachmentCounts counts;
  final String title;
  final String emptyMessage;
  final List<String> footerLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        if (counts.isEmpty && footerLines.isEmpty)
          Text(
            emptyMessage,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          )
        else ...<Widget>[
          if (counts.totalCount > 0)
            Text(
              '${counts.totalCount} file${counts.totalCount == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ..._orderedTypes(counts.countByType).map(_typeRow),
          ...footerLines.map(_footerLine),
        ],
      ],
    );
  }

  static List<AttachmentType> _orderedTypes(Map<AttachmentType, int> byType) {
    const List<AttachmentType> order = <AttachmentType>[
      AttachmentType.ppt,
      AttachmentType.document,
      AttachmentType.pdf,
      AttachmentType.image,
      AttachmentType.video,
    ];
    return order.where((AttachmentType t) => (byType[t] ?? 0) > 0).toList(growable: false);
  }

  Widget _typeRow(AttachmentType type) {
    final int count = counts.countByType[type] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: <Widget>[
          Icon(_iconFor(type), size: 16, color: const Color(0xFF57629A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_labelFor(type)} · $count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(AppIcons.info, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(AttachmentType type) {
    return switch (type) {
      AttachmentType.ppt => 'Presentations',
      AttachmentType.document => 'Documents',
      AttachmentType.pdf => 'PDF',
      AttachmentType.image => 'Images',
      AttachmentType.video => 'Videos',
    };
  }

  static IconData _iconFor(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => AppIcons.attachmentImage,
      AttachmentType.video => AppIcons.attachmentVideo,
      AttachmentType.pdf => AppIcons.attachmentPdf,
      AttachmentType.ppt => AppIcons.attachmentPpt,
      AttachmentType.document => AppIcons.attachmentDocument,
    };
  }
}
