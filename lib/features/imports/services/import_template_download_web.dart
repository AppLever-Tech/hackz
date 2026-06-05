import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadCsvFile({
  required String fileName,
  required String csvContent,
}) async {
  final List<int> bytes = utf8.encode(csvContent);
  final html.Blob blob = html.Blob(<Object>[bytes], 'text/csv;charset=utf-8');
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
