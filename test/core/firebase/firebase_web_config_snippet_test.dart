import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/firebase_web_config_snippet.dart';

void main() {
  const String jsSnippet = '''
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDummyKeyForTestsOnly00000000000",
  authDomain: "college-one.firebaseapp.com",
  projectId: "college-one",
  storageBucket: "college-one.firebasestorage.app",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456",
  measurementId: "G-TESTONLY01"
};
''';

  test('parses the Firebase console JS snippet', () {
    final FirebaseWebConfigSnippet config = parseFirebaseWebConfigSnippet(jsSnippet);
    expect(config.apiKey, 'AIzaSyDummyKeyForTestsOnly00000000000');
    expect(config.authDomain, 'college-one.firebaseapp.com');
    expect(config.projectId, 'college-one');
    expect(config.storageBucket, 'college-one.firebasestorage.app');
    expect(config.messagingSenderId, '123456789012');
    expect(config.appIdWeb, '1:123456789012:web:abcdef123456');
    expect(config.appIdAndroid, isEmpty);
  });

  test('parses a JSON object with quoted keys', () {
    final FirebaseWebConfigSnippet config = parseFirebaseWebConfigSnippet('''
{
  "apiKey": "key",
  "authDomain": "x.firebaseapp.com",
  "projectId": "x",
  "storageBucket": "x.appspot.com",
  "messagingSenderId": "1",
  "appId": "1:1:web:abc"
}
''');
    expect(config.projectId, 'x');
    expect(config.apiKey, 'key');
    expect(config.appIdWeb, '1:1:web:abc');
  });

  test('maps android appId onto the android field', () {
    final FirebaseWebConfigSnippet config = parseFirebaseWebConfigSnippet('''
{
  "apiKey": "key",
  "projectId": "x",
  "storageBucket": "x.appspot.com",
  "messagingSenderId": "1",
  "appId": "1:1:android:abc"
}
''');
    expect(config.appIdAndroid, '1:1:android:abc');
    expect(config.appIdWeb, isEmpty);
  });

  test('rejects empty or incomplete snippets', () {
    expect(
      () => parseFirebaseWebConfigSnippet(''),
      throwsA(isA<FirebaseWebConfigParseException>()),
    );
    expect(
      () => parseFirebaseWebConfigSnippet('{ "projectId": "x" }'),
      throwsA(isA<FirebaseWebConfigParseException>()),
    );
  });
}
