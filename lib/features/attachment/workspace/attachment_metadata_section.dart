import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/utils/attachment_preview_utils.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'attachment_workspace_loader.dart';

class AttachmentMetadataSection extends StatelessWidget {
  const AttachmentMetadataSection({super.key, required this.vm});

  final AttachmentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final a = vm.attachment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'File details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: <Widget>[
              _row(AppIcons.attachmentDocument, 'File name', a.fileName.trim().isEmpty ? '—' : a.fileName.trim()),
              _row(AppIcons.faculty, 'Uploaded by', vm.uploaderName),
              _row(AppIcons.clock, 'Uploaded', formatDateTime(a.createdAt)),
              _row(
                AttachmentPreviewUtils.typeIcon(a.attachmentType),
                'Type',
                vm.typeLabel,
              ),
              _row(AppIcons.info, 'Format', vm.mimeLabel),
              _row(AppIcons.download, 'Size', vm.sizeLabel),
              _row(
                AppIcons.attachments,
                'Linked entity',
                _entityTypeLabel(a.entityType),
                value2: a.entityId.trim().isEmpty ? null : a.entityId.trim(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _entityTypeLabel(AttachmentEntityType type) {
    return switch (type) {
      AttachmentEntityType.idea => 'Idea',
      AttachmentEntityType.problem => 'Problem',
      AttachmentEntityType.payment => 'Payment',
      AttachmentEntityType.organization => 'Organization',
    };
  }

  Widget _row(IconData icon, String label, String value, {String? value2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                if (value2 != null)
                  Text(
                    value2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
