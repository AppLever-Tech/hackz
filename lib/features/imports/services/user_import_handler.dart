import 'package:cloud_firestore/cloud_firestore.dart';

import '../../user/constants/csv_import_role_constants.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_service.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../models/import_created_source.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_type.dart';
import 'csv_parser_service.dart';
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_handler.dart';
import 'import_role_validator.dart';
import 'user_import_config.dart';

class UserImportHandler extends ImportHandler {
  static const List<String> headers = <String>[
    ImportConstants.firstNameColumnKey,
    ImportConstants.lastNameColumnKey,
    ImportConstants.phoneColumnKey,
    ImportConstants.emailColumnKey,
    ImportConstants.roleColumnKey,
    ImportConstants.departmentColumnKey,
  ];

  @override
  ImportType get type => ImportType.users;

  @override
  String get title => 'Import Users';

  @override
  String get templateFileName => 'hackz_users_import_template.csv';

  @override
  String get templateCsv => '''
firstname,lastname,phone,email,role,department
Ravi,Kumar,9876543210,ravi@test.com,${CsvImportRoleConstants.teamMember},CSE
Anita,Sharma,9876543211,anita@test.com,${CsvImportRoleConstants.coordinator},
Rahul,Das,9876543212,,,
'''.trim();

  @override
  List<String> get requiredHeaders => const <String>[
        ImportConstants.firstNameColumnKey,
        ImportConstants.lastNameColumnKey,
        ImportConstants.phoneColumnKey,
      ];

  @override
  List<String> get reviewHeaders => const <String>[
        ImportConstants.firstNameColumnKey,
        ImportConstants.lastNameColumnKey,
        ImportConstants.phoneColumnKey,
        ImportConstants.roleColumnKey,
      ];

  @override
  List<String> get expansionHeaders => const <String>[
        ImportConstants.emailColumnKey,
        ImportConstants.departmentColumnKey,
      ];

  @override
  List<String> get optionalHeaders => const <String>[
        ImportConstants.emailColumnKey,
        ImportConstants.roleColumnKey,
        ImportConstants.departmentColumnKey,
      ];

  @override
  List<String> templateGuidancePoints(ImportHandlerContext context) {
    final UserImportConfig? config = context is UserImportHandlerContext ? context.config : null;
    final Set<String> allowedRoles = config?.allowedCsvRoles ?? CsvImportRoleConstants.allSet;
    final bool allowTeamMemberDefault = allowedRoles.contains(CsvImportRoleConstants.teamMember);
    return <String>[
      if (allowTeamMemberDefault)
        'Blank role defaults to ${CsvImportRoleConstants.teamMember}.'
      else
        'Role is required. Use ${allowedRoles.join(', ')}.',
      'Blank department defaults to your department.',
      'Role values are case-sensitive.',
    ];
  }

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final UserImportConfig? config = context is UserImportHandlerContext ? context.config : null;
    final Set<String> allowedRoles = config?.allowedCsvRoles ?? CsvImportRoleConstants.allSet;
    final bool allowTeamMemberDefault = allowedRoles.contains(CsvImportRoleConstants.teamMember);

    final _UserImportLookup lookup = await _UserImportLookup.load(context.orgId);
    final Set<String> phonesInFile = <String>{};
    final Set<String> emailsInFile = <String>{};
    final List<ImportReviewRow> review = <ImportReviewRow>[];

    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int rowNumber = i + 1;
      final String firstName = CsvParserService.cell(row, ImportConstants.firstNameColumnKey);
      final String lastName = CsvParserService.cell(row, ImportConstants.lastNameColumnKey);
      final String email = CsvParserService.cell(row, ImportConstants.emailColumnKey);
      final String phoneRaw = CsvParserService.cell(row, ImportConstants.phoneColumnKey);
      final String roleRaw = CsvParserService.cell(row, ImportConstants.roleColumnKey);
      final String departmentRaw = CsvParserService.cell(row, ImportConstants.departmentColumnKey);

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';
      String? roleCode;
      String displayRole = roleRaw;
      String? departmentCode;
      String? departmentName;

      void markError(String message, String label) {
        issues.add(message);
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = label;
      }

      void markWarning(String message, String label) {
        issues.add(message);
        if (severity != ImportRowSeverity.error) {
          severity = ImportRowSeverity.warning;
          importable = false;
          statusLabel = label;
        }
      }

      if (firstName.isEmpty) {
        markError('Missing first name', 'Missing First Name');
      }
      if (lastName.isEmpty) {
        markError('Missing last name', 'Missing Last Name');
      }
      if (phoneRaw.isEmpty) {
        markError('Missing phone', 'Missing Phone');
      } else if (!isValidPhoneInput(phoneRaw)) {
        markError('Invalid phone', 'Invalid Phone');
      }

      if (email.isNotEmpty && !isValidEmailInput(email)) {
        markError('Invalid email', 'Invalid Email');
      }

      final ImportRoleValidation roleResult = ImportRoleValidator.validate(
        rawInput: roleRaw,
        allowedCsvRoles: allowedRoles,
        defaultCsvRole: allowTeamMemberDefault ? CsvImportRoleConstants.teamMember : null,
      );
      if (!roleResult.isValid) {
        markError(roleResult.errorMessage ?? 'Invalid role', roleResult.statusLabel ?? 'Invalid Role');
      } else {
        roleCode = roleResult.roleCode;
        displayRole = roleRaw.isEmpty ? CsvImportRoleConstants.teamMember : roleRaw;
      }

      final ImportDepartmentValidation deptResult = ImportDepartmentValidator.validate(
        rawInput: departmentRaw,
        lookup: lookup.departments,
        defaultCode: context.defaultDepartmentCode,
        defaultName: context.defaultDepartmentName,
      );
      if (!deptResult.isValid) {
        markError(deptResult.errorMessage ?? 'Invalid department code', deptResult.statusLabel ?? 'Invalid Department');
      } else {
        departmentCode = deptResult.canonicalCode;
        departmentName = deptResult.departmentName;
      }

      if (phoneRaw.isNotEmpty && isValidPhoneInput(phoneRaw)) {
        final String phone = normalizePhoneE164(phoneRaw);
        if (phonesInFile.contains(phone)) {
          markWarning('Duplicate phone in file', 'Duplicate Phone');
        } else {
          phonesInFile.add(phone);
          if (lookup.existingPhones.contains(phone)) {
            markWarning('Phone already exists', 'Duplicate Phone');
          }
        }
      }

      if (email.isNotEmpty && isValidEmailInput(email)) {
        final String normalizedEmail = email.toLowerCase();
        if (emailsInFile.contains(normalizedEmail)) {
          markWarning('Duplicate email in file', 'Duplicate Email');
        } else {
          emailsInFile.add(normalizedEmail);
          if (lookup.existingEmails.contains(normalizedEmail)) {
            markWarning('Email already exists', 'Duplicate Email');
          }
        }
      }

      if (issues.isEmpty) {
        severity = ImportRowSeverity.valid;
        importable = true;
        statusLabel = 'Valid';
      }

      final String departmentDisplay = departmentCode ?? departmentRaw;

      review.add(
        ImportReviewRow(
          rowNumber: rowNumber,
          values: <String, String>{
            ImportConstants.firstNameColumnKey: firstName,
            ImportConstants.lastNameColumnKey: lastName,
            ImportConstants.phoneColumnKey: phoneRaw,
            ImportConstants.emailColumnKey: email,
            ImportConstants.roleColumnKey: displayRole,
            ImportConstants.departmentColumnKey: departmentDisplay,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            if (roleCode != null) 'roleCode': roleCode,
            if (departmentCode != null) 'departmentCode': departmentCode,
            if (departmentName != null && departmentName.isNotEmpty) 'departmentName': departmentName,
            if (email.isNotEmpty || departmentDisplay.isNotEmpty) 'expandable': '1',
          },
        ),
      );
    }
    return review;
  }

  @override
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context,
  ) async {
    final UserImportHandlerContext userContext = context as UserImportHandlerContext;
    final List<ImportReviewRow> importable =
        rows.where((ImportReviewRow r) => r.importable).toList(growable: false);

    var imported = 0;
    var skipped = rows.length - importable.length;
    var failed = 0;
    final List<String> failures = <String>[];

    for (final ImportReviewRow row in importable) {
      try {
        final String departmentCode =
            row.metadata['departmentCode'] ?? row.valueFor(ImportConstants.departmentColumnKey);
        final String departmentName = row.metadata['departmentName'] ?? departmentCode;
        final String roleCode = row.metadata['roleCode'] ?? UserRole.teamMember.code;
        final String phone = normalizePhoneE164(row.valueFor(ImportConstants.phoneColumnKey));

        final UserModel draft = UserModel(
          userId: '',
          phone: phone,
          firstName: row.valueFor(ImportConstants.firstNameColumnKey),
          lastName: row.valueFor(ImportConstants.lastNameColumnKey),
          email: row.valueFor(ImportConstants.emailColumnKey),
          role: roleCode,
          roles: <String>[roleCode],
          orgType: userContext.config.organizationType,
          orgId: context.orgId,
          department: departmentName,
          departmentCode: departmentCode,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: context.actorUserId,
          createdSource: ImportCreatedSource.csvImport.value,
          createdBy: context.actorUserId,
        );

        final String createdId = await UserService.createUser(user: draft);
        await FirestoreUtils.updateUser(createdId, <String, dynamic>{
          'orgId': context.orgId,
          'department': departmentName,
          'departmentCode': departmentCode,
          'createdSource': ImportCreatedSource.csvImport.value,
          'createdBy': context.actorUserId,
        });
        imported++;
      } catch (e) {
        failed++;
        failures.add('Row ${row.rowNumber}: $e');
      }
    }

    return ImportExecutionResult(
      imported: imported,
      skipped: skipped,
      failed: failed,
      failures: failures,
    );
  }
}

class UserImportHandlerContext extends ImportHandlerContext {
  UserImportHandlerContext({
    required super.actorUserId,
    required super.orgId,
    required super.defaultDepartmentName,
    required super.defaultDepartmentCode,
    required this.config,
  });

  final UserImportConfig config;

  @override
  Set<String>? get supportedCsvRoles => config.allowedCsvRoles;

  factory UserImportHandlerContext.fromConfig(UserImportConfig config) {
    return UserImportHandlerContext(
      actorUserId: config.actor.userId,
      orgId: config.orgId,
      defaultDepartmentName: config.departmentName,
      defaultDepartmentCode: config.departmentCode,
      config: config,
    );
  }
}

class _UserImportLookup {
  const _UserImportLookup({
    required this.existingPhones,
    required this.existingEmails,
    required this.departments,
  });

  final Set<String> existingPhones;
  final Set<String> existingEmails;
  final ImportDepartmentLookup departments;

  static Future<_UserImportLookup> load(String orgId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseFirestore.instance
        .collection(FirestoreUtils.hkzUsers)
        .where('orgId', isEqualTo: orgId)
        .get();

    final Set<String> phones = <String>{};
    final Set<String> emails = <String>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final UserModel user = UserModel.fromMap(doc.data());
      if (user.phone.trim().isNotEmpty) phones.add(normalizePhoneE164(user.phone));
      if (user.email.trim().isNotEmpty) emails.add(user.email.trim().toLowerCase());
    }

    final ImportDepartmentLookup departments = await ImportDepartmentLookup.load(orgId);

    return _UserImportLookup(
      existingPhones: phones,
      existingEmails: emails,
      departments: departments,
    );
  }
}
