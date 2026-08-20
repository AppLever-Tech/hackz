// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Web save: File System Access Save As. Cancel/abort returns false.
Future<bool> downloadCsvFile({
  required String fileName,
  required String csvContent,
}) async {
  final Object? picker = js_util.getProperty(html.window, 'showSaveFilePicker');
  if (picker == null) {
    throw UnsupportedError('Saving a CSV template is not supported in this browser.');
  }

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
                'description': 'CSV',
                'accept': <String, Object>{
                  'text/csv': <String>['.csv'],
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
    final html.Blob blob = html.Blob(<Object>[csvContent], 'text/csv;charset=utf-8');
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

bool _isSaveCancelled(Object error) {
  final String text = error.toString().toLowerCase();
  return text.contains('aborterror') || text.contains('the user aborted');
}
