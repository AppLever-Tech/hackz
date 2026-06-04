import 'package:flutter/material.dart';

import 'package:hackz/features/attachment/utils/attachment_preview_utils.dart';
import 'package:hackz/responsive/responsive_helper.dart';
import 'attachment_preview_pane.dart';
import 'attachment_workspace_loader.dart';

/// Premium media preview surface for a single attachment.
class AttachmentPreviewSection extends StatelessWidget {
  const AttachmentPreviewSection({super.key, required this.vm});

  final AttachmentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final double height = ResponsiveHelper.isMobile(context) ? 280 : 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              AttachmentPreviewUtils.typeIcon(vm.attachment.attachmentType),
              size: 18,
              color: const Color(0xFF4A67FF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vm.attachment.fileName.trim().isEmpty ? 'Attachment' : vm.attachment.fileName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x0A000000), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AttachmentPreviewPane(
              attachment: vm.attachment,
              resolvedUrl: vm.resolvedUrl,
            ),
          ),
        ),
      ],
    );
  }
}
