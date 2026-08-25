import 'dart:convert';

import 'package:flutter/services.dart';

import 'import_template_download_stub.dart'
    if (dart.library.html) 'import_template_download_web.dart'
    if (dart.library.io) 'import_template_download_io.dart';

enum ImportTemplateDownloadResult { saved, cancelled, copied }

/// Downloads import templates. Success is reported only after the user confirms Save.
abstract final class ImportTemplateService {
  static const String csvMimeType = 'text/csv;charset=utf-8';
  static const String xlsxMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static Future<ImportTemplateDownloadResult> downloadTemplate({
    required String fileName,
    required String csvContent,
  }) {
    return downloadBytes(
      fileName: fileName,
      bytes: utf8.encode(csvContent),
      mimeType: csvMimeType,
      copyTextOnUnsupported: csvContent,
    );
  }

  static Future<ImportTemplateDownloadResult> downloadBytes({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    String? copyTextOnUnsupported,
  }) async {
    try {
      final bool saved = await downloadImportFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      if (!saved) return ImportTemplateDownloadResult.cancelled;
      return ImportTemplateDownloadResult.saved;
    } on UnsupportedError {
      final String? text = copyTextOnUnsupported;
      if (text == null || text.isEmpty) rethrow;
      await Clipboard.setData(ClipboardData(text: text));
      return ImportTemplateDownloadResult.copied;
    }
  }
}
