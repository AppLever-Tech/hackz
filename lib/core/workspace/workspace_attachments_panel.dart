import 'package:flutter/material.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/utils/attachment_preview_utils.dart';
import 'package:hackz/features/attachment/workspace/attachment_workspace.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'workspace_attachment_counts.dart';

/// Read-only attachment list with workspace navigation per file.
class WorkspaceAttachmentsPanel extends StatelessWidget {
  const WorkspaceAttachmentsPanel({
    super.key,
    required this.attachments,
    this.title = 'Attachments',
    this.emptyMessage = 'No attachments.',
    this.showTypeSummary = true,
  });

  final List<AttachmentModel> attachments;
  final String title;
  final String emptyMessage;
  final bool showTypeSummary;

  @override
  Widget build(BuildContext context) {
    final WorkspaceAttachmentCounts counts = WorkspaceAttachmentCounts.fromModels(attachments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title.trim().isNotEmpty) ...<Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
        ],
        if (attachments.isEmpty)
          Text(
            emptyMessage,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          )
        else ...<Widget>[
          if (showTypeSummary && counts.totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${counts.totalCount} file${counts.totalCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
          ...attachments.map((AttachmentModel a) => _fileRow(context, a)),
        ],
      ],
    );
  }

  Widget _fileRow(BuildContext context, AttachmentModel attachment) {
    final String label = attachment.fileName.trim().isEmpty ? 'Untitled file' : attachment.fileName.trim();
    final String meta =
        '${AttachmentPreviewUtils.typeLabel(attachment.attachmentType)} · ${AttachmentPreviewUtils.formatSize(attachment.sizeInBytes)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            AttachmentPreviewUtils.typeIcon(attachment.attachmentType),
            size: 18,
            color: const Color(0xFF57629A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: label,
                    icon: AttachmentPreviewUtils.typeIcon(attachment.attachmentType),
                    onTap: () => AttachmentWorkspace.push(context, attachment.attachmentId),
                    compact: true,
                    fitContent: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
