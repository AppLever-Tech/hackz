import 'package:cloud_firestore/cloud_firestore.dart';

import '../../organization/models/enums/organization_type.dart';
import 'enums/user_status.dart';
import 'profiles/user_profile.dart';

class UserModel {
  const UserModel({
    required this.userId,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.orgType,
    required this.orgId,
    required this.department,
    required this.departmentCode,
    required this.status,
    required this.createdAt,
    this.roles = const <String>[],
    this.photoUrl,
    this.thumbnailUrl,
    this.profile,
    this.teamId,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  final String userId;
  final String phone;
  final String firstName;
  final String lastName;
  final String email;

  /// Primary role code used for routing and legacy queries.
  final String role;

  /// All role codes assigned to this user (includes [role] when set from Firestore).
  final List<String> roles;
  final OrganizationType? orgType;
  final String orgId;
  final String department;
  final String departmentCode;
  final UserStatus status;
  final DateTime createdAt;
  final String? photoUrl;
  final String? thumbnailUrl;
  final UserProfile? profile;
  final String? teamId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  String get displayName {
    final String full = '$firstName $lastName'.trim();
    return full.isEmpty ? userId : full;
  }

  String get avatarUrl {
    final String thumb = (thumbnailUrl ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    return (photoUrl ?? '').trim();
  }

  List<String> get effectiveRoles {
    if (roles.isNotEmpty) return List<String>.unmodifiable(roles);
    final String primary = role.trim();
    if (primary.isEmpty) return const <String>[];
    return <String>[primary];
  }

  bool hasRoleCode(String code) => effectiveRoles.contains(code.trim());

  Map<String, dynamic> toMap() {
    final List<String> normalizedRoles = effectiveRoles;
    return <String, dynamic>{
      'userId': userId,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': normalizedRoles.isNotEmpty ? normalizedRoles.first : role,
      'roles': normalizedRoles,
      'orgType': orgType?.value,
      'orgId': orgId,
      'department': department,
      'departmentCode': departmentCode,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if ((photoUrl ?? '').trim().isNotEmpty) 'photoUrl': photoUrl!.trim(),
      if ((thumbnailUrl ?? '').trim().isNotEmpty) 'thumbnailUrl': thumbnailUrl!.trim(),
      if (profile != null && !profile!.isEmpty) 'profile': profile!.toMap(),
      'teamId': teamId,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectionReason': rejectionReason,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final List<String> parsedRoles = _parseRoles(map);
    final String primaryRole = parsedRoles.isNotEmpty
        ? parsedRoles.first
        : ((map['role'] as String?) ?? 'STU').trim();
    UserProfile? parsedProfile;
    final dynamic profileRaw = map['profile'];
    if (profileRaw is Map<String, dynamic>) {
      parsedProfile = UserProfile.fromMap(profileRaw);
      if (parsedProfile.isEmpty) parsedProfile = null;
    }
    return UserModel(
      userId: (map['userId'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      firstName: (map['firstName'] as String?) ?? '',
      lastName: (map['lastName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: primaryRole,
      roles: parsedRoles.isEmpty ? <String>[primaryRole] : parsedRoles,
      orgType: OrganizationType.fromFirestoreValue(map['orgType']),
      orgId: (map['orgId'] as String?) ?? '',
      department: (map['department'] as String?) ?? '',
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      status: UserStatus.fromRaw((map['status'] as String?) ?? ''),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: (map['photoUrl'] as String?)?.trim(),
      thumbnailUrl: (map['thumbnailUrl'] as String?)?.trim(),
      profile: parsedProfile,
      teamId: (map['teamId'] as String?)?.trim().isEmpty == true ? null : (map['teamId'] as String?)?.trim(),
      approvedBy: (map['approvedBy'] as String?)?.trim(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: (map['rejectionReason'] as String?)?.trim(),
    );
  }

  static List<String> _parseRoles(Map<String, dynamic> map) {
    final dynamic raw = map['roles'];
    if (raw is List) {
      final List<String> parsed = raw
          .map((dynamic e) => e.toString().trim())
          .where((String e) => e.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    final String single = ((map['role'] as String?) ?? '').trim();
    return single.isEmpty ? <String>[] : <String>[single];
  }

  UserModel copyWith({
    String? userId,
    String? phone,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    List<String>? roles,
    OrganizationType? orgType,
    String? orgId,
    String? department,
    String? departmentCode,
    UserStatus? status,
    DateTime? createdAt,
    String? photoUrl,
    String? thumbnailUrl,
    UserProfile? profile,
    String? teamId,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    final List<String> nextRoles = roles ?? this.roles;
    final String nextRole = role ?? (nextRoles.isNotEmpty ? nextRoles.first : this.role);
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: nextRole,
      roles: nextRoles.isEmpty ? <String>[nextRole] : nextRoles,
      orgType: orgType ?? this.orgType,
      orgId: orgId ?? this.orgId,
      department: department ?? this.department,
      departmentCode: departmentCode ?? this.departmentCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      profile: profile ?? this.profile,
      teamId: teamId ?? this.teamId,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
