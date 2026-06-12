import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';

/// Shared attachment type labels, icons, and size formatting for workspace UIs.
abstract final class AttachmentPreviewUtils {
  AttachmentPreviewUtils._();

  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    var idx = 0;
    while (size >= 1024 && idx < units.length - 1) {
      size /= 1024;
      idx++;
    }
    return '${size.toStringAsFixed(size >= 10 || idx == 0 ? 0 : 1)} ${units[idx]}';
  }

  static String typeLabel(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => 'Image',
      AttachmentType.video => 'Video',
      AttachmentType.pdf => 'PDF',
      AttachmentType.ppt => 'Presentation',
      AttachmentType.document => 'Document',
    };
  }

  static IconData typeIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => AppIcons.attachmentImage,
      AttachmentType.video => AppIcons.attachmentVideo,
      AttachmentType.pdf => AppIcons.attachmentPdf,
      AttachmentType.ppt => AppIcons.attachmentPpt,
      AttachmentType.document => AppIcons.attachmentDocument,
    };
  }
}
