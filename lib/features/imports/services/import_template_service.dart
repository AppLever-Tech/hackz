import 'package:flutter/services.dart';

import 'import_template_download_stub.dart'
    if (dart.library.html) 'import_template_download_web.dart'
    if (dart.library.io) 'import_template_download_io.dart';

enum ImportTemplateDownloadResult { saved, cancelled, copied }

/// Downloads CSV templates. Success is reported only after the user confirms Save.
abstract final class ImportTemplateService {
  static Future<ImportTemplateDownloadResult> downloadTemplate({
    required String fileName,
    required String csvContent,
  }) async {
    try {
      final bool saved = await downloadCsvFile(
        fileName: fileName,
        csvContent: csvContent,
      );
      return saved ? ImportTemplateDownloadResult.saved : ImportTemplateDownloadResult.cancelled;
    } on UnsupportedError {
      await Clipboard.setData(ClipboardData(text: csvContent));
      return ImportTemplateDownloadResult.copied;
    }
  }
}
