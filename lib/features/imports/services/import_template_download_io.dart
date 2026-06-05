import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadCsvFile({
  required String fileName,
  required String csvContent,
}) async {
  final String? path = await FilePicker.platform.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(utf8.encode(csvContent)),
    type: FileType.custom,
    allowedExtensions: <String>['csv'],
  );
  return path != null && path.trim().isNotEmpty;
}
