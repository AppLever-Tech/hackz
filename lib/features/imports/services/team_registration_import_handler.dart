import 'package:cloud_firestore/cloud_firestore.dart';

import '../../organization/models/organization_model.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../team/models/team_model.dart';
import '../../team/services/faculty_teams_service.dart';
import '../../team/services/team_service.dart';
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
import '../models/import_summary.dart';
import '../models/import_type.dart';
import 'csv_parser_service.dart';
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_handler.dart';

/// Coordinator CSV import: one row per team member, grouped by team name.
class TeamRegistrationImportHandler extends ImportHandler {
  static const List<String> headers = <String>[
    ImportConstants.teamNameColumnKey,
    ImportConstants.phoneColumnKey,
    ImportConstants.firstNameColumnKey,
    ImportConstants.lastNameColumnKey,
    ImportConstants.emailColumnKey,
    ImportConstants.organisationColumnKey,
    ImportConstants.departmentColumnKey,
    ImportConstants.isTeamLeaderColumnKey,
  ];

  @override
  ImportType get type => ImportType.teamRegistration;

  @override
  String get title => 'Team Registration';

  @override
  String get templateFileName => 'hackz_team_registration_template.csv';

  @override
  String get templateCsv => '''
teamName,phone,firstName,lastName,email,organisation,department,isTeamLeader
Team Alpha,9876543210,Ravi,Kumar,ravi@example.com,SJBIT,CSE,true
Team Alpha,9876543211,Anita,Sharma,anita@example.com,SJBIT,CSE,false
Team Alpha,9876543212,Rahul,Das,rahul@example.com,ABC College,CSE,false
'''.trim();

  @override
  List<String> get requiredHeaders => headers;

  @override
  List<String> get reviewHeaders => headers;

  @override
  List<String> get expansionHeaders => const <String>[];

  @override
  bool get blockImportOnAnyError => true;

  @override
  String get columnGuidance =>
      'One row per team member. Group members with the same teamName. '
      'phone is the unique user identifier (10-digit Indian mobile). '
      'Required: teamName, phone, firstName, lastName, organisation, isTeamLeader. '
      'Optional: email, department. '
      'isTeamLeader: true/false — exactly one true per team. '
      'Existing Hackz users are reused by phone; new users are created as Team Members. '
      'External participants use their own organisation name — no new college is created.';

  @override
  ImportSummary summarize(List<ImportReviewRow> rows) {
    final Set<String> teams = <String>{};
    var leaders = 0;
    var existing = 0;
    var created = 0;
    for (final ImportReviewRow row in rows) {
      final String team = row.valueFor(ImportConstants.teamNameColumnKey);
      if (team.isNotEmpty) teams.add(team.toLowerCase());
      if (row.metadata['isTeamLeader'] == '1') leaders++;
      if (row.metadata['existingUserId']?.trim().isNotEmpty == true) {
        existing++;
      } else if (row.metadata['phoneE164']?.trim().isNotEmpty == true) {
        created++;
      }
    }
    return ImportSummary.fromRows(
      rows,
      previewCounts: <ImportPreviewCount>[
        ImportPreviewCount(label: 'Teams', value: teams.length),
        ImportPreviewCount(label: 'Members', value: rows.length),
        ImportPreviewCount(label: 'Team Leaders', value: leaders),
        ImportPreviewCount(label: 'Existing Users', value: existing),
        ImportPreviewCount(label: 'New Users', value: created),
        ImportPreviewCount(label: 'Warnings', value: rows.where((ImportReviewRow r) => r.severity == ImportRowSeverity.warning).length),
        ImportPreviewCount(label: 'Errors', value: rows.where((ImportReviewRow r) => r.severity == ImportRowSeverity.error).length),
      ],
    );
  }

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final TeamRegistrationImportHandlerContext teamContext = _requireContext(context);
    final _Lookup lookup = await _Lookup.load(teamContext);
    await lookup.ensureDepartmentsFor(
      rows.map((Map<String, String> r) => CsvParserService.cell(r, ImportConstants.organisationColumnKey)),
    );

    final List<_ParsedRow> parsed = <_ParsedRow>[];
    for (var i = 0; i < rows.length; i++) {
      parsed.add(_parseRow(rows[i], i + 2, lookup, teamContext));
    }

    final Set<String> phones = parsed.map((_ParsedRow r) => r.phoneE164).whereType<String>().toSet();
    lookup.usersByPhone.addAll(await _fetchUsersByPhones(phones));

    final Map<String, List<_ParsedRow>> byPhone = <String, List<_ParsedRow>>{};
    for (final _ParsedRow row in parsed) {
      if (row.phoneE164 == null) continue;
      byPhone.putIfAbsent(row.phoneE164!, () => <_ParsedRow>[]).add(row);
    }
    for (final List<_ParsedRow> group in byPhone.values) {
      if (group.length < 2) continue;
      final _ParsedRow first = group.first;
      for (final _ParsedRow row in group) {
        if (!_sameIntendedUser(first, row)) {
          row.addError(
            ImportConstants.phoneColumnKey,
            'Duplicate phone must represent the same person (name / email / organisation do not match).',
          );
        }
      }
      final Set<String> teamKeys = group.map((_ParsedRow r) => r.teamKey).where((String k) => k.isNotEmpty).toSet();
      if (teamKeys.length > 1) {
        for (final _ParsedRow row in group) {
          row.addError(ImportConstants.phoneColumnKey, 'This phone is listed on more than one team.');
        }
      } else if (teamKeys.length == 1) {
        for (final _ParsedRow row in group) {
          row.addError(ImportConstants.phoneColumnKey, 'Duplicate member in this team.');
        }
      }
    }

    for (final _ParsedRow row in parsed) {
      final String? phone = row.phoneE164;
      if (phone == null) continue;
      final UserModel? existing = lookup.usersByPhone[phone];
      if (existing == null) continue;
      row.existingUser = existing;
      if (UserRole.fromCode(existing.role) != UserRole.student &&
          !existing.hasRoleCode(UserRole.student.code)) {
        row.addError(ImportConstants.phoneColumnKey, 'Existing Hackz user is not a Team Member and cannot be added to a team.');
      } else if (existing.status != UserStatus.active) {
        row.addError(ImportConstants.phoneColumnKey, 'Existing Hackz user is not active.');
      } else if ((existing.teamId ?? '').trim().isNotEmpty) {
        row.addError(ImportConstants.phoneColumnKey, 'This user already belongs to a team.');
      } else {
        row.addWarning(ImportConstants.phoneColumnKey, 'Existing user will be reused.');
        if (row.firstName.isNotEmpty &&
            existing.firstName.trim().toLowerCase() != row.firstName.toLowerCase()) {
          row.addWarning(ImportConstants.firstNameColumnKey, 'CSV first name differs from the existing Hackz user.');
        }
        if (row.lastName.isNotEmpty &&
            existing.lastName.trim().toLowerCase() != row.lastName.toLowerCase()) {
          row.addWarning(ImportConstants.lastNameColumnKey, 'CSV last name differs from the existing Hackz user.');
        }
      }
    }

    final Map<String, List<_ParsedRow>> byTeam = <String, List<_ParsedRow>>{};
    for (final _ParsedRow row in parsed) {
      if (row.teamKey.isEmpty) continue;
      byTeam.putIfAbsent(row.teamKey, () => <_ParsedRow>[]).add(row);
    }

    for (final MapEntry<String, List<_ParsedRow>> entry in byTeam.entries) {
      _validateTeamGroup(entry.value, lookup);
    }

    final bool fileHasErrors = parsed.any((_ParsedRow r) => r.hasError);
    return parsed
        .map((_ParsedRow row) => row.toReviewRow(importable: !fileHasErrors && !row.hasError))
        .toList(growable: false);
  }

  static Future<Map<String, UserModel>> _fetchUsersByPhones(Set<String> phones) async {
    final Map<String, UserModel> byPhone = <String, UserModel>{};
    if (phones.isEmpty) return byPhone;
    final List<String> list = phones.toList(growable: false);
    for (var i = 0; i < list.length; i += 10) {
      final List<String> chunk = list.sublist(i, i + 10 > list.length ? list.length : i + 10);
      final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('phone', whereIn: chunk)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
        final String phone = normalizePhoneE164(user.phone);
        if (phone.isNotEmpty) byPhone[phone] = user;
      }
    }
    return byPhone;
  }

  @override
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context,
  ) async {
    final TeamRegistrationImportHandlerContext teamContext = _requireContext(context);
    if (UserRole.fromCode(teamContext.actor.role) != UserRole.coordinator) {
      return const ImportExecutionResult(
        imported: 0,
        skipped: 0,
        failed: 0,
        failures: <String>['Team Registration import is available to Coordinators only.'],
      );
    }
    if (rows.any((ImportReviewRow r) => r.severity == ImportRowSeverity.error)) {
      return ImportExecutionResult(
        imported: 0,
        skipped: rows.length,
        failed: 0,
        failures: const <String>['Fix validation errors before importing.'],
      );
    }

    final List<ImportReviewRow> importable =
        rows.where((ImportReviewRow r) => r.importable).toList(growable: false);
    if (importable.isEmpty) {
      return ImportExecutionResult(imported: 0, skipped: rows.length, failed: 0);
    }

    final Map<String, String> userIdByPhone = <String, String>{};
    var failed = 0;
    final List<String> failures = <String>[];

    for (final ImportReviewRow row in importable) {
      final String phone = row.metadata['phoneE164'] ?? '';
      if (phone.isEmpty || userIdByPhone.containsKey(phone)) continue;
      final String existingId = (row.metadata['existingUserId'] ?? '').trim();
      if (existingId.isNotEmpty) {
        userIdByPhone[phone] = existingId;
        continue;
      }
      try {
        final String createdId = await UserService.createUser(
          user: UserModel(
            userId: '',
            phone: phone,
            firstName: row.valueFor(ImportConstants.firstNameColumnKey),
            lastName: row.valueFor(ImportConstants.lastNameColumnKey),
            email: row.valueFor(ImportConstants.emailColumnKey),
            role: UserRole.student.code,
            roles: const <String>['STU'],
            orgType: teamContext.actor.orgType,
            orgId: row.metadata['orgId'] ?? teamContext.orgId,
            department: row.metadata['departmentName'] ?? row.valueFor(ImportConstants.departmentColumnKey),
            departmentCode: row.metadata['departmentCode'] ?? '',
            status: UserStatus.active,
            createdAt: DateTime.now(),
            approvedAt: DateTime.now(),
            approvedBy: teamContext.actorUserId,
            createdSource: ImportCreatedSource.csvImport.value,
            createdBy: teamContext.actorUserId,
          ),
        );
        userIdByPhone[phone] = createdId;
      } catch (e) {
        failed++;
        failures.add('Row ${row.rowNumber}: $e');
      }
    }

    if (failed > 0) {
      return ImportExecutionResult(
        imported: 0,
        skipped: 0,
        failed: failed,
        failures: failures,
      );
    }

    final Map<String, List<ImportReviewRow>> byTeam = <String, List<ImportReviewRow>>{};
    for (final ImportReviewRow row in importable) {
      final String key = row.valueFor(ImportConstants.teamNameColumnKey).trim().toLowerCase();
      if (key.isEmpty) continue;
      byTeam.putIfAbsent(key, () => <ImportReviewRow>[]).add(row);
    }

    var importedTeams = 0;
    for (final List<ImportReviewRow> members in byTeam.values) {
      try {
        final Set<String> memberIds = <String>{};
        String leaderId = '';
        for (final ImportReviewRow row in members) {
          final String phone = row.metadata['phoneE164'] ?? '';
          final String? userId = userIdByPhone[phone];
          if (userId == null || userId.isEmpty) {
            throw StateError('Could not resolve user for ${row.valueFor(ImportConstants.phoneColumnKey)}.');
          }
          memberIds.add(userId);
          if (row.metadata['isTeamLeader'] == '1') leaderId = userId;
        }
        await TeamService.createTeam(
          actor: teamContext.actor,
          teamName: members.first.valueFor(ImportConstants.teamNameColumnKey),
          studentIds: memberIds,
          teamLeaderId: leaderId,
        );
        importedTeams++;
      } catch (e) {
        failed++;
        failures.add('${members.first.valueFor(ImportConstants.teamNameColumnKey)}: $e');
      }
    }

    return ImportExecutionResult(
      imported: importedTeams,
      skipped: rows.length - importable.length,
      failed: failed,
      failures: failures,
    );
  }

  static TeamRegistrationImportHandlerContext _requireContext(ImportHandlerContext context) {
    if (context is TeamRegistrationImportHandlerContext) return context;
    throw ArgumentError('Team registration import requires TeamRegistrationImportHandlerContext.');
  }

  static _ParsedRow _parseRow(
    Map<String, String> raw,
    int rowNumber,
    _Lookup lookup,
    TeamRegistrationImportHandlerContext context,
  ) {
    final _ParsedRow row = _ParsedRow(
      rowNumber: rowNumber,
      teamName: CsvParserService.cell(raw, ImportConstants.teamNameColumnKey),
      phoneRaw: CsvParserService.cell(raw, ImportConstants.phoneColumnKey),
      firstName: CsvParserService.cell(raw, ImportConstants.firstNameColumnKey),
      lastName: CsvParserService.cell(raw, ImportConstants.lastNameColumnKey),
      email: CsvParserService.cell(raw, ImportConstants.emailColumnKey),
      organisation: CsvParserService.cell(raw, ImportConstants.organisationColumnKey),
      departmentRaw: CsvParserService.cell(raw, ImportConstants.departmentColumnKey),
      isTeamLeaderRaw: CsvParserService.cell(raw, ImportConstants.isTeamLeaderColumnKey),
    );

    if (row.teamName.isEmpty) {
      row.addError(ImportConstants.teamNameColumnKey, 'Team name is required.');
    }

    if (row.phoneRaw.isEmpty) {
      row.addError(ImportConstants.phoneColumnKey, 'Phone is required.');
    } else if (!isValidPhoneInput(row.phoneRaw)) {
      row.addError(ImportConstants.phoneColumnKey, 'Enter a valid 10-digit phone number.');
    } else {
      row.phoneE164 = normalizePhoneE164(row.phoneRaw);
    }

    if (row.firstName.isEmpty) {
      row.addError(ImportConstants.firstNameColumnKey, 'First name is required.');
    }
    if (row.lastName.isEmpty) {
      row.addError(ImportConstants.lastNameColumnKey, 'Last name is required.');
    }

    if (row.email.isNotEmpty && !isValidEmailInput(row.email)) {
      row.addError(ImportConstants.emailColumnKey, 'Enter a valid email address.');
    }

    if (row.organisation.isEmpty) {
      row.addError(ImportConstants.organisationColumnKey, 'Organisation is required.');
    } else {
      final OrganizationModel? matched = lookup.orgByNormalizedName[_normalizeOrg(row.organisation)];
      final bool matchesOwningName = _normalizeOrg(row.organisation) == _normalizeOrg(context.orgName);
      if (matched != null) {
        row.resolvedOrgId = matched.id;
        row.resolvedOrgName = matched.name;
        row.isHackzOrganisation = true;
        row.isOwningOrg = matched.id == context.orgId;
        if (!row.isOwningOrg) {
          row.addWarning(
            ImportConstants.organisationColumnKey,
            'External Hackz organisation — member will keep that affiliation.',
          );
        }
      } else if (matchesOwningName) {
        row.resolvedOrgId = context.orgId;
        row.resolvedOrgName = context.orgName.isEmpty ? row.organisation : context.orgName;
        row.isHackzOrganisation = true;
        row.isOwningOrg = true;
      } else {
        row.resolvedOrgId = context.orgId;
        row.resolvedOrgName = row.organisation;
        row.isHackzOrganisation = false;
        row.isOwningOrg = false;
        row.addWarning(
          ImportConstants.organisationColumnKey,
          'Organisation is not a registered Hackz college — stored as participant affiliation. No organisation will be created.',
        );
      }
    }

    final ImportDepartmentLookup deptLookup = row.resolvedOrgId != null && row.resolvedOrgId != context.orgId
        ? (lookup.departmentsByOrg[row.resolvedOrgId!] ?? lookup.owningDepartments)
        : lookup.owningDepartments;
    if (row.departmentRaw.isNotEmpty) {
      if (row.isHackzOrganisation) {
        final ImportDepartmentValidation dept = ImportDepartmentValidator.validate(
          rawInput: row.departmentRaw,
          lookup: deptLookup,
        );
        if (!dept.isValid) {
          row.addError(ImportConstants.departmentColumnKey, dept.errorMessage ?? 'Invalid department.');
        } else {
          row.departmentCode = dept.canonicalCode ?? '';
          row.departmentName = dept.departmentName ?? row.departmentRaw;
        }
      } else {
        final String code = row.departmentRaw.trim().toUpperCase();
        if (lookup.owningDepartments.codes.contains(code)) {
          row.departmentCode = code;
          row.departmentName = lookup.owningDepartments.codeToName[code] ?? row.departmentRaw;
        } else {
          row.departmentName = row.departmentRaw;
        }
      }
    } else if (row.isOwningOrg) {
      row.departmentCode = context.defaultDepartmentCode.trim().toUpperCase();
      row.departmentName = context.defaultDepartmentName.trim().isEmpty
          ? row.departmentCode
          : context.defaultDepartmentName.trim();
    } else if (row.departmentName.isEmpty) {
      row.departmentName = row.organisation;
    }

    final bool? leader = _parseFlag(row.isTeamLeaderRaw);
    if (leader == null) {
      row.addError(
        ImportConstants.isTeamLeaderColumnKey,
        'isTeamLeader must be true or false.',
      );
    } else {
      row.isTeamLeader = leader;
    }

    return row;
  }

  static void _validateTeamGroup(List<_ParsedRow> members, _Lookup lookup) {
    final String displayName = members.first.teamName.trim();
    if (displayName.isEmpty) return;

    if (lookup.existingTeamNames.contains(displayName.toLowerCase())) {
      for (final _ParsedRow row in members) {
        row.addError(ImportConstants.teamNameColumnKey, 'A team with this name already exists.');
      }
    }

    if (members.length < lookup.minMembers) {
      for (final _ParsedRow row in members) {
        row.addError(
          ImportConstants.teamNameColumnKey,
          'Team must have at least ${lookup.minMembers} members.',
        );
      }
    }
    if (members.length > lookup.maxMembers) {
      for (final _ParsedRow row in members) {
        row.addError(
          ImportConstants.teamNameColumnKey,
          'Team can have at most ${lookup.maxMembers} members.',
        );
      }
    }

    final List<_ParsedRow> leaders = members.where((_ParsedRow r) => r.isTeamLeader == true).toList(growable: false);
    if (leaders.isEmpty) {
      for (final _ParsedRow row in members) {
        row.addError(ImportConstants.isTeamLeaderColumnKey, 'Team must have exactly one Team Leader.');
      }
    } else if (leaders.length > 1) {
      for (final _ParsedRow row in leaders) {
        row.addError(ImportConstants.isTeamLeaderColumnKey, 'Team has more than one Team Leader.');
      }
    }

    final Set<String> owningOrgLabels = members
        .where((_ParsedRow r) => r.isOwningOrg)
        .map((_ParsedRow r) => _normalizeOrg(r.organisation))
        .toSet();
    if (owningOrgLabels.length > 1) {
      for (final _ParsedRow row in members.where((_ParsedRow r) => r.isOwningOrg)) {
        row.addError(
          ImportConstants.organisationColumnKey,
          'Internal members of this team have inconsistent organisation names.',
        );
      }
    }
  }

  static bool _sameIntendedUser(_ParsedRow a, _ParsedRow b) {
    return a.firstName.toLowerCase() == b.firstName.toLowerCase() &&
        a.lastName.toLowerCase() == b.lastName.toLowerCase() &&
        a.email.toLowerCase() == b.email.toLowerCase() &&
        _normalizeOrg(a.organisation) == _normalizeOrg(b.organisation);
  }

  static String _normalizeOrg(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool? _parseFlag(String raw) {
    final String value = raw.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == 'true' || value == 'yes' || value == 'y' || value == '1') return true;
    if (value == 'false' || value == 'no' || value == 'n' || value == '0') return false;
    return null;
  }
}

class TeamRegistrationImportHandlerContext extends ImportHandlerContext {
  TeamRegistrationImportHandlerContext({
    required this.actor,
    required this.orgName,
  }) : super(
          actorUserId: actor.userId,
          orgId: actor.orgId,
          defaultDepartmentName: actor.department,
          defaultDepartmentCode: actor.departmentCode,
        );

  final UserModel actor;
  final String orgName;
}

class _ParsedRow {
  _ParsedRow({
    required this.rowNumber,
    required this.teamName,
    required this.phoneRaw,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.organisation,
    required this.departmentRaw,
    required this.isTeamLeaderRaw,
  });

  final int rowNumber;
  final String teamName;
  final String phoneRaw;
  final String firstName;
  final String lastName;
  final String email;
  final String organisation;
  final String departmentRaw;
  final String isTeamLeaderRaw;

  String? phoneE164;
  String? resolvedOrgId;
  String resolvedOrgName = '';
  bool isHackzOrganisation = false;
  bool isOwningOrg = false;
  String departmentCode = '';
  String departmentName = '';
  bool? isTeamLeader;
  UserModel? existingUser;

  final List<String> _errors = <String>[];
  final List<String> _warnings = <String>[];

  String get teamKey => teamName.trim().toLowerCase();

  bool get hasError => _errors.isNotEmpty;

  void addError(String field, String message) {
    _errors.add('$field: $message');
  }

  void addWarning(String field, String message) {
    _warnings.add('$field: $message');
  }

  ImportReviewRow toReviewRow({required bool importable}) {
    final bool error = _errors.isNotEmpty;
    final bool warning = !error && _warnings.isNotEmpty;
    return ImportReviewRow(
      rowNumber: rowNumber,
      values: <String, String>{
        ImportConstants.teamNameColumnKey: teamName,
        ImportConstants.phoneColumnKey: phoneRaw,
        ImportConstants.firstNameColumnKey: firstName,
        ImportConstants.lastNameColumnKey: lastName,
        ImportConstants.emailColumnKey: email,
        ImportConstants.organisationColumnKey: organisation,
        ImportConstants.departmentColumnKey: departmentCode.isEmpty ? departmentRaw : departmentCode,
        ImportConstants.isTeamLeaderColumnKey: isTeamLeader == true ? 'true' : (isTeamLeader == false ? 'false' : isTeamLeaderRaw),
      },
      severity: error
          ? ImportRowSeverity.error
          : warning
              ? ImportRowSeverity.warning
              : ImportRowSeverity.valid,
      statusLabel: error
          ? 'Error'
          : warning
              ? 'Warning'
              : 'Valid',
      messages: error ? _errors : _warnings,
      importable: importable && !error,
      metadata: <String, String>{
        if (phoneE164 != null) 'phoneE164': phoneE164!,
        if (resolvedOrgId != null) 'orgId': resolvedOrgId!,
        'departmentCode': departmentCode,
        'departmentName': departmentName.isEmpty ? departmentRaw : departmentName,
        'isTeamLeader': isTeamLeader == true ? '1' : '0',
        if ((existingUser?.userId ?? '').trim().isNotEmpty) 'existingUserId': existingUser!.userId,
      },
    );
  }
}

class _Lookup {
  _Lookup({
    required this.owningDepartments,
    required this.departmentsByOrg,
    required this.orgByNormalizedName,
    required this.existingTeamNames,
    required this.usersByPhone,
    required this.minMembers,
    required this.maxMembers,
  });

  final ImportDepartmentLookup owningDepartments;
  final Map<String, ImportDepartmentLookup> departmentsByOrg;
  final Map<String, OrganizationModel> orgByNormalizedName;
  final Set<String> existingTeamNames;
  final Map<String, UserModel> usersByPhone;
  final int minMembers;
  final int maxMembers;

  static Future<_Lookup> load(TeamRegistrationImportHandlerContext context) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: context.orgId);
    final Map<String, dynamic> settings = OrgSettingsService.instance.valuesSnapshot;
    final int minMembers = (settings[OrgSettingKeys.minStudentsPerTeam] as num?)?.toInt() ??
        FacultyTeamsService.minStudentsPerTeam;
    final int maxMembers = (settings[OrgSettingKeys.maxStudentsPerTeam] as num?)?.toInt() ??
        FacultyTeamsService.maxStudentsPerTeam;

    final List<OrganizationModel> orgs = await FirestoreUtils.getOrganizations();
    final Map<String, OrganizationModel> orgByName = <String, OrganizationModel>{};
    for (final OrganizationModel org in orgs) {
      final String key = TeamRegistrationImportHandler._normalizeOrg(org.name);
      if (key.isNotEmpty) orgByName.putIfAbsent(key, () => org);
      final String idKey = org.id.trim().toLowerCase();
      if (idKey.isNotEmpty) orgByName.putIfAbsent(idKey, () => org);
    }

    final ImportDepartmentLookup owningDepartments = await ImportDepartmentLookup.load(context.orgId);
    final List<TeamModel> teams = await TeamService.getTeamsByOrg(context.orgId);
    final Set<String> teamNames = teams.map((TeamModel t) => t.teamName.trim().toLowerCase()).where((String n) => n.isNotEmpty).toSet();

    return _Lookup(
      owningDepartments: owningDepartments,
      departmentsByOrg: <String, ImportDepartmentLookup>{context.orgId: owningDepartments},
      orgByNormalizedName: orgByName,
      existingTeamNames: teamNames,
      usersByPhone: <String, UserModel>{},
      minMembers: minMembers,
      maxMembers: maxMembers < minMembers ? minMembers : maxMembers,
    );
  }

  Future<void> ensureDepartmentsFor(Iterable<String> organisationNames) async {
    final Set<String> neededOrgIds = <String>{};
    for (final String raw in organisationNames) {
      final OrganizationModel? matched = orgByNormalizedName[TeamRegistrationImportHandler._normalizeOrg(raw)];
      if (matched != null && !departmentsByOrg.containsKey(matched.id)) {
        neededOrgIds.add(matched.id);
      }
    }
    if (neededOrgIds.isEmpty) return;
    final List<MapEntry<String, ImportDepartmentLookup>> loaded = await Future.wait(
      neededOrgIds.map((String id) async {
        final ImportDepartmentLookup lookup = await ImportDepartmentLookup.load(id);
        return MapEntry<String, ImportDepartmentLookup>(id, lookup);
      }),
    );
    for (final MapEntry<String, ImportDepartmentLookup> entry in loaded) {
      departmentsByOrg[entry.key] = entry.value;
    }
  }
}
