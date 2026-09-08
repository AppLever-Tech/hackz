import 'package:flutter/services.dart';

import 'hackz_file_download_stub.dart'
    if (dart.library.html) 'hackz_file_download_web.dart'
    if (dart.library.io) 'hackz_file_download_io.dart';

enum HackzFileDownloadResult { saved, cancelled, copied }

/// Client-side Save As used by import templates and data exports.
abstract final class HackzFileDownload {
  static const String csvMimeType = 'text/csv;charset=utf-8';
  static const String xlsxMimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String pdfMimeType = 'application/pdf';

  static Future<HackzFileDownloadResult> save({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    String? copyTextOnUnsupported,
  }) async {
    try {
      final bool saved = await saveHackzFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      if (!saved) return HackzFileDownloadResult.cancelled;
      return HackzFileDownloadResult.saved;
    } on UnsupportedError {
      final String? text = copyTextOnUnsupported;
      if (text == null || text.isEmpty) rethrow;
      await Clipboard.setData(ClipboardData(text: text));
      return HackzFileDownloadResult.copied;
    }
  }
}
