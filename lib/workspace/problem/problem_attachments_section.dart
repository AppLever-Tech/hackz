import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';

class ProblemAttachmentsSection extends StatelessWidget {
  const ProblemAttachmentsSection({super.key, required this.attachments});

  final List<AttachmentModel> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Text(
        'No attachments uploaded for this problem.',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Attachments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...attachments.take(8).map(_tile),
      ],
    );
  }

  Widget _tile(AttachmentModel a) {
    final String name = a.fileName.trim().isEmpty ? a.attachmentId : a.fileName.trim();
    final Uri? uri = Uri.tryParse(a.downloadUrl.trim());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(_iconFor(a.attachmentType), size: 16, color: const Color(0xFF57629A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ),
          if (uri != null)
            Link(
              uri: uri,
              target: LinkTarget.blank,
              builder: (BuildContext context, Future<void> Function()? followLink) {
                return IconButton(
                  onPressed: followLink,
                  icon: const Icon(AppIcons.openInNew, size: 16),
                  tooltip: 'Open attachment',
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _iconFor(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => AppIcons.attachmentImage,
      AttachmentType.video => AppIcons.attachmentVideo,
      AttachmentType.pdf => AppIcons.attachmentPdf,
      AttachmentType.ppt => AppIcons.attachmentPpt,
      AttachmentType.document => AppIcons.attachmentDocument,
    };
  }
}
