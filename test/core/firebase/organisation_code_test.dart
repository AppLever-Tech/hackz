import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/organisation_code.dart';

void main() {
  group('OrganisationCode', () {
    test('generate uses HKZ-XXXXXX with unambiguous characters', () {
      final Random rng = Random(42);
      for (int i = 0; i < 200; i++) {
        final String code = OrganisationCode.generate(random: rng);
        expect(OrganisationCode.isValid(code), isTrue, reason: code);
        expect(code, startsWith('HKZ-'));
        expect(code.length, 10);
        final String body = code.substring(4);
        expect(body.contains(RegExp(r'[01OI]')), isFalse, reason: code);
      }
    });

    test('generate is not derived from an organisation name', () {
      final String a = OrganisationCode.generate(random: Random(1));
      final String b = OrganisationCode.generate(random: Random(2));
      expect(a, isNot(equals(b)));
      expect(a.contains('COLLEGE'), isFalse);
    });

    test('normalize trims, uppercases, and drops internal spaces', () {
      expect(OrganisationCode.normalize('  hkz-s7k4pm  '), 'HKZ-S7K4PM');
      expect(OrganisationCode.normalize('hkz- s7k4pm'), 'HKZ-S7K4PM');
      expect(OrganisationCode.tryParse('hkz-s7k4pm'), 'HKZ-S7K4PM');
      expect(OrganisationCode.tryParse(' HKZ-S7K4PM '), 'HKZ-S7K4PM');
    });

    test('accepts the canonical example HKZ-S7K4PM', () {
      expect(OrganisationCode.tryParse('hkz-s7k4pm'), 'HKZ-S7K4PM');
    });

    test('rejects invalid or ambiguous codes', () {
      expect(OrganisationCode.tryParse(''), isNull);
      expect(OrganisationCode.tryParse('S7K4PM'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7K4P'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7K4PMM'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7K0PM'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7KOPM'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7K1PM'), isNull);
      expect(OrganisationCode.tryParse('HKZ-S7KIPM'), isNull);
      expect(OrganisationCode.tryParse('NOT-A-CODE'), isNull);
    });
  });
}
