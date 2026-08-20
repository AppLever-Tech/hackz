import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadCsvFile({
  required String fileName,
  required String csvContent,
}) async {
  final String? path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save CSV template',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: <String>['csv'],
  );
  if (path == null || path.trim().isEmpty) return false;

  String resolved = path.trim();
  if (!resolved.toLowerCase().endsWith('.csv')) {
    resolved = '$resolved.csv';
  }
  await File(resolved).writeAsBytes(utf8.encode(csvContent), flush: true);
  return true;
}
