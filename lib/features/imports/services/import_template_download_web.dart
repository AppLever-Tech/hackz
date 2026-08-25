// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// Web save: File System Access Save As. Cancel/abort returns false.
Future<bool> downloadImportFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final Object? picker = js_util.getProperty(html.window, 'showSaveFilePicker');
  if (picker == null) {
    throw UnsupportedError('Saving a template is not supported in this browser.');
  }

  final String extension = _extensionOf(fileName);
  final String dotted = extension.isEmpty ? '' : '.$extension';

  try {
    final Object handle = await js_util.promiseToFuture<Object>(
      js_util.callMethod(
        html.window,
        'showSaveFilePicker',
        <Object>[
          js_util.jsify(<String, Object>{
            'suggestedName': fileName,
            'types': <Object>[
              <String, Object>{
                'description': extension.toUpperCase(),
                'accept': <String, Object>{
                  mimeType: <String>[dotted],
                },
              },
            ],
          }),
        ],
      ),
    );
    final Object writable = await js_util.promiseToFuture<Object>(
      js_util.callMethod(handle, 'createWritable', const <Object>[]),
    );
    final html.Blob blob = html.Blob(<Object>[Uint8List.fromList(bytes)], mimeType);
    await js_util.promiseToFuture<Object?>(
      js_util.callMethod(writable, 'write', <Object>[blob]),
    );
    await js_util.promiseToFuture<Object?>(
      js_util.callMethod(writable, 'close', const <Object>[]),
    );
    return true;
  } catch (error) {
    if (_isSaveCancelled(error)) return false;
    rethrow;
  }
}

String _extensionOf(String fileName) {
  final int dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

bool _isSaveCancelled(Object error) {
  final String text = error.toString().toLowerCase();
  return text.contains('aborterror') || text.contains('the user aborted');
}
