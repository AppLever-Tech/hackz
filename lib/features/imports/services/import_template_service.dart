import 'dart:convert';

import '../../../core/download/hackz_file_download.dart';

enum ImportTemplateDownloadResult { saved, cancelled, copied }

/// Downloads import templates. Success is reported only after the user confirms Save.
abstract final class ImportTemplateService {
  static const String csvMimeType = HackzFileDownload.csvMimeType;
  static const String xlsxMimeType = HackzFileDownload.xlsxMimeType;

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
    final HackzFileDownloadResult result = await HackzFileDownload.save(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      copyTextOnUnsupported: copyTextOnUnsupported,
    );
    return switch (result) {
      HackzFileDownloadResult.saved => ImportTemplateDownloadResult.saved,
      HackzFileDownloadResult.cancelled => ImportTemplateDownloadResult.cancelled,
      HackzFileDownloadResult.copied => ImportTemplateDownloadResult.copied,
    };
  }
}
