import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// Desktop save: native Save As, then write. Cancel returns false.
Future<bool> downloadCsvFile({
  required String fileName,
  required String csvContent,
}) async {
  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const <XTypeGroup>[
      XTypeGroup(
        label: 'CSV',
        extensions: <String>['csv'],
      ),
    ],
  );
  if (location == null) return false;

  String resolved = location.path.trim();
  if (resolved.isEmpty) return false;
  if (!resolved.toLowerCase().endsWith('.csv')) {
    resolved = '$resolved.csv';
  }

  await File(resolved).writeAsBytes(utf8.encode(csvContent), flush: true);
  return true;
}
