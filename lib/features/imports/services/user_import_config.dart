import '../../organization/models/enums/organization_type.dart';
import '../../user/models/user_model.dart';

/// Launch configuration for the shared user import workflow.
class UserImportConfig {
  const UserImportConfig({
    required this.actor,
    required this.organizationType,
    required this.departmentName,
    required this.departmentCode,
    this.allowedCsvRoles = const <String>{'STUDENT', 'FACULTY', 'JUDGE'},
  });

  final UserModel actor;
  final OrganizationType organizationType;
  final String departmentName;
  final String departmentCode;

  /// CSV role labels allowed for this entry point (e.g. Judges panel: JUDGE only).
  final Set<String> allowedCsvRoles;

  String get orgId => actor.orgId;
}
