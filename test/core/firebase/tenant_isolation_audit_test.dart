import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _defaultInstance = RegExp(
  r'Firebase(?:Auth|Firestore|Storage)\.instance(?!For)',
);

bool _isCommentOrStringOnly(String line) {
  final String trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('///');
}

void main() {
  test('lib does not use default Firebase Auth/Firestore/Storage instances', () {
    final Directory lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'flutter test must run from the package root');

    final List<String> leaks = <String>[];
    for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        if (_isCommentOrStringOnly(line)) continue;
        if (!_defaultInstance.hasMatch(line)) continue;
        leaks.add('${entity.path}:${i + 1}: $line');
      }
    }

    expect(leaks, isEmpty, reason: leaks.join('\n'));
  });
}
