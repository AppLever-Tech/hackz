import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/imports/services/import_department_lookup.dart';
import 'package:hackz/features/imports/services/import_department_validator.dart';
import 'package:hackz/features/organization/models/department_model.dart';
import 'package:hackz/features/user/models/enums/user_role.dart';
import 'package:hackz/features/imports/services/import_department_resolution_policy.dart';

void main() {
  group('DepartmentModel.normalizeKey', () {
    test('trims, lowercases, and collapses whitespace', () {
      expect(DepartmentModel.normalizeKey('  Artificial   Intelligence & Data Science  '),
          'artificial intelligence & data science');
    });
  });

  group('DepartmentModel aliases', () {
    test('parseAliases ignores blanks and duplicates', () {
      expect(
        DepartmentModel.parseAliases(<Object?>[' AIDS ', 'aids', '', 'AI & DS']),
        <String>['AIDS', 'AI & DS'],
      );
    });

    test('aliasMatchesDepartment treats name and code as identity', () {
      expect(
        DepartmentModel.aliasMatchesDepartment(alias: 'cse', name: 'Computer Science', code: 'CSE'),
        isTrue,
      );
      expect(
        DepartmentModel.aliasMatchesDepartment(alias: 'CS', name: 'Computer Science', code: 'CSE'),
        isFalse,
      );
    });
  });

  group('DepartmentModel.suggestCode', () {
    test('uses master list when the name matches', () {
      expect(DepartmentModel.suggestCode('Computer Science and Engineering'), 'CSE');
    });

    test('builds initials for unknown names', () {
      expect(DepartmentModel.suggestCode('Artificial Intelligence & Data Science'), 'AIDS');
    });

    test('uniqueSuggestedCode appends a suffix when taken', () {
      expect(DepartmentModel.uniqueSuggestedCode('Computer Science and Engineering', <String>{'CSE'}), isNot('CSE'));
    });
  });

  group('ImportDepartmentLookup.resolve', () {
    final ImportDepartmentLookup lookup = ImportDepartmentLookup(
      departments: const <ImportDepartmentInfo>[
        ImportDepartmentInfo(
          id: '1',
          code: 'CSE',
          name: 'Computer Science and Engineering',
          aliases: <String>['CS', 'Comp Sci'],
        ),
        ImportDepartmentInfo(
          id: '2',
          code: 'AIML',
          name: 'Artificial Intelligence and Machine Learning',
        ),
      ],
    );

    test('matches exact code ignoring case and spaces', () {
      expect(lookup.resolve(' cse ')?.code, 'CSE');
    });

    test('matches department name with collapsed whitespace', () {
      expect(lookup.resolve('Computer  Science and Engineering')?.code, 'CSE');
    });

    test('matches aliases', () {
      expect(lookup.resolve('comp sci')?.code, 'CSE');
      expect(lookup.resolve('CS')?.code, 'CSE');
    });

    test('does not fall back when unknown', () {
      expect(lookup.resolve('Artificial Intelligence & Data Science'), isNull);
    });
  });

  group('ImportDepartmentValidator', () {
    final ImportDepartmentLookup lookup = ImportDepartmentLookup(
      departments: const <ImportDepartmentInfo>[
        ImportDepartmentInfo(id: '1', code: 'CSE', name: 'Computer Science and Engineering'),
      ],
    );

    test('blank input uses current-department fallback', () {
      final ImportDepartmentValidation result = ImportDepartmentValidator.validate(
        rawInput: '  ',
        lookup: lookup,
        defaultCode: 'CSE',
        defaultName: 'Computer Science and Engineering',
      );
      expect(result.isValid, isTrue);
      expect(result.needsResolution, isFalse);
      expect(result.canonicalCode, 'CSE');
    });

    test('unknown non-empty input requires explicit resolution', () {
      final ImportDepartmentValidation result = ImportDepartmentValidator.validate(
        rawInput: 'Artificial Intelligence & Data Science',
        lookup: lookup,
        defaultCode: 'CSE',
        defaultName: 'Computer Science and Engineering',
      );
      expect(result.isValid, isFalse);
      expect(result.needsResolution, isTrue);
      expect(result.canonicalCode, isNull);
    });

    test('session mapping resolves without changing lookup', () {
      final ImportDepartmentValidation result = ImportDepartmentValidator.validate(
        rawInput: 'AIDS',
        lookup: lookup,
        resolutions: const <String, ImportDepartmentMapping>{
          'aids': ImportDepartmentMapping(code: 'CSE', name: 'Computer Science and Engineering', id: '1'),
        },
      );
      expect(result.isValid, isTrue);
      expect(result.canonicalCode, 'CSE');
    });
  });

  group('ImportDepartmentResolutionPolicy', () {
    test('hides create and admin assignment from Department Admin and Coordinator', () {
      expect(ImportDepartmentResolutionPolicy.canMap(UserRole.coordinator), isTrue);
      expect(ImportDepartmentResolutionPolicy.canCreateDepartment(UserRole.coordinator), isFalse);
      expect(ImportDepartmentResolutionPolicy.canAssignAdministrator(UserRole.coordinator), isFalse);
      expect(ImportDepartmentResolutionPolicy.canCreateDepartmentAdmin(UserRole.departmentAdmin), isFalse);
      expect(ImportDepartmentResolutionPolicy.canCreateDepartment(UserRole.collegeAdmin), isTrue);
      expect(ImportDepartmentResolutionPolicy.canCreateDepartmentAdmin(UserRole.collegeAdmin), isTrue);
    });

    test('only CADM and DADM may save aliases', () {
      expect(ImportDepartmentResolutionPolicy.canSaveAlias(UserRole.coordinator), isFalse);
      expect(ImportDepartmentResolutionPolicy.canSaveAlias(UserRole.departmentAdmin), isTrue);
    });
  });

  group('UserRole department administrator eligibility', () {
    test('never includes team members, coordinators, or judges', () {
      expect(UserRole.isEligibleDepartmentAdministrator(UserRole.teamMember.code), isFalse);
      expect(UserRole.isEligibleDepartmentAdministrator(UserRole.coordinator.code), isFalse);
      expect(UserRole.isEligibleDepartmentAdministrator(UserRole.judge.code), isFalse);
      expect(UserRole.isEligibleDepartmentAdministrator(UserRole.departmentAdmin.code), isTrue);
      expect(UserRole.isEligibleDepartmentAdministrator(UserRole.collegeAdmin.code), isTrue);
    });
  });
}
