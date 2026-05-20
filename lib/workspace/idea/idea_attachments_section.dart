import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';

class IdeaAttachmentsSection extends StatelessWidget {
  const IdeaAttachmentsSection({super.key, required this.attachmentsByType});

  final Map<AttachmentType, List<AttachmentModel>> attachmentsByType;

  @override
  Widget build(BuildContext context) {
    if (attachmentsByType.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _heading(),
          const SizedBox(height: 8),
          const Text(
            'No attachments uploaded for this proposal yet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _heading(),
        const SizedBox(height: 10),
        if (_listFor(AttachmentType.ppt).isNotEmpty) ...<Widget>[
          _groupTitle('Presentations', AppIcons.attachmentPpt),
          ..._listFor(AttachmentType.ppt).map(_tile),
          const SizedBox(height: 8),
        ],
        if (_listFor(AttachmentType.document).isNotEmpty || _listFor(AttachmentType.pdf).isNotEmpty) ...<Widget>[
          _groupTitle('Documents', AppIcons.attachmentDocument),
          ..._listFor(AttachmentType.document).map(_tile),
          ..._listFor(AttachmentType.pdf).map(_tile),
          const SizedBox(height: 8),
        ],
        if (_listFor(AttachmentType.video).isNotEmpty) ...<Widget>[
          _groupTitle('Videos', AppIcons.attachmentVideo),
          ..._listFor(AttachmentType.video).map(_tile),
          const SizedBox(height: 8),
        ],
        if (_listFor(AttachmentType.image).isNotEmpty) ...<Widget>[
          _groupTitle('Screenshots', AppIcons.attachmentImage),
          ..._listFor(AttachmentType.image).map(_tile),
        ],
      ],
    );
  }

  List<AttachmentModel> _listFor(AttachmentType type) =>
      attachmentsByType[type] ?? const <AttachmentModel>[];

  Widget _heading() {
    return const Text(
      'Attachments',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
    );
  }

  Widget _groupTitle(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _tile(AttachmentModel a) {
    final String name = a.fileName.trim().isEmpty ? a.attachmentId : a.fileName.trim();
    final Uri? uri = Uri.tryParse(a.downloadUrl.trim());
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
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
