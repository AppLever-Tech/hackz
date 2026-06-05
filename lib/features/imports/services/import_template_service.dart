import 'package:flutter/services.dart';

import 'import_template_download_stub.dart'
    if (dart.library.html) 'import_template_download_web.dart'
    if (dart.library.io) 'import_template_download_io.dart';

/// Downloads or copies CSV templates for import workflows.
abstract final class ImportTemplateService {
  static Future<bool> downloadTemplate({
    required String fileName,
    required String csvContent,
  }) async {
    try {
      final bool saved = await downloadCsvFile(
        fileName: fileName,
        csvContent: csvContent,
      );
      if (saved) return true;
    } catch (_) {
      // Fall through to clipboard on unsupported platforms.
    }

    await Clipboard.setData(ClipboardData(text: csvContent));
    return false;
  }
}
