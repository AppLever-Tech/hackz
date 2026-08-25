import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// Desktop save: native Save As, then write. Cancel returns false.
Future<bool> downloadImportFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final String extension = _extensionOf(fileName);
  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(
        label: extension.toUpperCase(),
        extensions: <String>[extension],
      ),
    ],
  );
  if (location == null) return false;

  String resolved = location.path.trim();
  if (resolved.isEmpty) return false;
  if (extension.isNotEmpty && !resolved.toLowerCase().endsWith('.$extension')) {
    resolved = '$resolved.$extension';
  }

  await File(resolved).writeAsBytes(bytes, flush: true);
  return true;
}

String _extensionOf(String fileName) {
  final int dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}
