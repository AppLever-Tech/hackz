import 'dart:convert';

/// Parsed Firebase console web SDK config. Not a tenant catalog record.
class FirebaseWebConfigSnippet {
  const FirebaseWebConfigSnippet({
    required this.apiKey,
    required this.authDomain,
    required this.projectId,
    required this.storageBucket,
    required this.messagingSenderId,
    required this.appId,
  });

  final String apiKey;
  final String authDomain;
  final String projectId;
  final String storageBucket;
  final String messagingSenderId;
  final String appId;

  String get appIdWeb => appId.contains(':android:') ? '' : appId;
  String get appIdAndroid => appId.contains(':android:') ? appId : '';
}

class FirebaseWebConfigParseException implements Exception {
  const FirebaseWebConfigParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Accepts the Firebase console JS snippet or a JSON object and returns fields.
FirebaseWebConfigSnippet parseFirebaseWebConfigSnippet(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    throw const FirebaseWebConfigParseException('Paste the firebaseConfig output from the Firebase console.');
  }

  final Map<String, dynamic> map = _decodeConfigObject(text);
  final String apiKey = _string(map, 'apiKey');
  final String projectId = _string(map, 'projectId');
  final String messagingSenderId = _string(map, 'messagingSenderId');
  final String storageBucket = _string(map, 'storageBucket');
  if (apiKey.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty || storageBucket.isEmpty) {
    throw const FirebaseWebConfigParseException(
      'That snippet is missing apiKey, projectId, messagingSenderId, or storageBucket.',
    );
  }

  return FirebaseWebConfigSnippet(
    apiKey: apiKey,
    authDomain: _string(map, 'authDomain'),
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: _string(map, 'appId'),
  );
}

String _string(Map<String, dynamic> map, String key) => '${map[key] ?? ''}'.trim();

Map<String, dynamic> _decodeConfigObject(String raw) {
  String text = raw.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  text = text.replaceAll(RegExp(r'//[^\n]*'), '');
  final int start = text.indexOf('{');
  final int end = text.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FirebaseWebConfigParseException('Paste the firebaseConfig object from the Firebase console.');
  }
  final String body = text.substring(start, end + 1);
  final Object? decoded = _tryJson(body) ?? _tryJson(_jsObjectToJson(body));
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  throw const FirebaseWebConfigParseException('Could not parse that Firebase config. Paste the firebaseConfig object.');
}

Object? _tryJson(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

String _jsObjectToJson(String body) {
  String js = body.replaceAllMapped(RegExp(r"'([^'\\]*)'"), (Match m) => '"${m[1]}"');
  js = js.replaceAllMapped(
    RegExp(r'([{\[,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:'),
    (Match m) => '${m[1]}"${m[2]}":',
  );
  return js.replaceAllMapped(RegExp(r',(\s*[}\]])'), (Match m) => m[1]!);
}
