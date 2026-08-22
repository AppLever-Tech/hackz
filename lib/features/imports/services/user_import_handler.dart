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
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_handler.dart';
import 'import_role_validator.dart';
import 'user_import_config.dart';

class UserImportHandler extends ImportHandler {
  static const List<String> headers = <String>[
    'name',
    'email',
    'phone',
    'role',
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
name,email,phone,role,${ImportConstants.departmentColumnKey}
John Doe,john@test.com,9876543210,${CsvImportRoleConstants.teamMember},CSE
Jane Smith,jane@test.com,9876543211,${CsvImportRoleConstants.judge},CSE
'''.trim();

  @override
  List<String> get requiredHeaders => headers;

  @override
  List<String> get reviewHeaders => headers;

  @override
  List<String> get expansionHeaders => const <String>[];

  @override
  String get columnGuidance =>
      'Use department codes (e.g. CSE), not display names. Role values are case-sensitive.';

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final UserImportConfig? config = context is UserImportHandlerContext ? context.config : null;
    final Set<String> allowedRoles = config?.allowedCsvRoles ?? CsvImportRoleConstants.allSet;

    final _UserImportLookup lookup = await _UserImportLookup.load(context.orgId);
    final Set<String> phonesInFile = <String>{};
    final Set<String> emailsInFile = <String>{};
    final List<ImportReviewRow> review = <ImportReviewRow>[];

    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int rowNumber = i + 2;
      final String name = _cell(row, 'name');
      final String email = _cell(row, 'email');
      final String phoneRaw = _cell(row, 'phone');
      final String roleRaw = _cell(row, 'role');
      final String departmentRaw = _cell(row, ImportConstants.departmentColumnKey);

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';
      String? roleCode;
      String? departmentCode;
      String? departmentName;

      if (name.isEmpty) {
        issues.add('Missing name');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Name';
      }
      if (email.isEmpty) {
        issues.add('Missing email');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Email';
      } else if (!isValidEmailInput(email)) {
        issues.add('Invalid email');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Invalid Email';
      }
      if (phoneRaw.isEmpty) {
        issues.add('Missing phone');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Phone';
      } else if (!isValidPhoneInput(phoneRaw)) {
        issues.add('Invalid phone');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Invalid Phone';
      }

      final ImportRoleValidation roleResult = ImportRoleValidator.validate(
        rawInput: roleRaw,
        allowedCsvRoles: allowedRoles,
      );
      if (!roleResult.isValid) {
        issues.add(roleResult.errorMessage ?? 'Invalid role');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = roleResult.statusLabel ?? 'Invalid Role';
      } else {
        roleCode = roleResult.roleCode;
      }

      final ImportDepartmentValidation deptResult = ImportDepartmentValidator.validate(
        rawInput: departmentRaw,
        lookup: lookup.departments,
      );
      if (!deptResult.isValid) {
        issues.add(deptResult.errorMessage ?? 'Invalid department code');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = deptResult.statusLabel ?? 'Invalid Department';
      } else {
        departmentCode = deptResult.canonicalCode;
        departmentName = deptResult.departmentName;
      }

      if (phoneRaw.isNotEmpty && isValidPhoneInput(phoneRaw)) {
        final String phone = normalizePhoneE164(phoneRaw);
        if (phonesInFile.contains(phone)) {
          issues.add('Duplicate phone in file');
          severity = ImportRowSeverity.warning;
          importable = false;
          statusLabel = 'Duplicate Phone';
        } else {
          phonesInFile.add(phone);
          if (lookup.existingPhones.contains(phone)) {
            issues.add('Phone already exists');
            severity = ImportRowSeverity.warning;
            importable = false;
            statusLabel = 'Duplicate Phone';
          }
        }
      }

      if (email.isNotEmpty && isValidEmailInput(email)) {
        final String normalizedEmail = email.toLowerCase();
        if (emailsInFile.contains(normalizedEmail)) {
          issues.add('Duplicate email in file');
          if (severity == ImportRowSeverity.valid) {
            severity = ImportRowSeverity.warning;
            importable = false;
            statusLabel = 'Duplicate Email';
          }
        } else {
          emailsInFile.add(normalizedEmail);
          if (lookup.existingEmails.contains(normalizedEmail)) {
            issues.add('Email already exists');
            if (severity == ImportRowSeverity.valid) {
              severity = ImportRowSeverity.warning;
              importable = false;
              statusLabel = 'Duplicate Email';
            }
          }
        }
      }

      if (severity == ImportRowSeverity.valid && importable) {
        statusLabel = 'Valid';
      }

      review.add(
        ImportReviewRow(
          rowNumber: rowNumber,
          values: <String, String>{
            'name': name,
            'email': email,
            'phone': phoneRaw,
            'role': roleRaw,
            ImportConstants.departmentColumnKey: departmentCode ?? departmentRaw,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            if (roleCode != null) 'roleCode': roleCode,
            if (departmentCode != null) 'departmentCode': departmentCode,
            if (departmentName != null && departmentName.isNotEmpty) 'departmentName': departmentName,
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
        final String departmentCode = row.metadata['departmentCode'] ?? row.valueFor(ImportConstants.departmentColumnKey);
        final String departmentName = row.metadata['departmentName'] ?? departmentCode;

        final (String firstName, String lastName) = _splitName(row.valueFor('name'));
        final String roleCode = row.metadata['roleCode'] ?? UserRole.teamMember.code;
        final String phone = normalizePhoneE164(row.valueFor('phone'));

        final UserModel draft = UserModel(
          userId: '',
          phone: phone,
          firstName: firstName,
          lastName: lastName,
          email: row.valueFor('email'),
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

  static String _cell(Map<String, String> row, String key) => (row[key] ?? '').trim();

  static (String, String) _splitName(String fullName) {
    final List<String> parts = fullName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return ('User', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
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
