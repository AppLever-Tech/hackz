import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/organization_type.dart';
import 'enums/user_status.dart';

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
  final String role;
  final OrganizationType? orgType;
  final String orgId;
  final String department; // display name
  final String departmentCode; // normalized code
  final UserStatus status;
  final DateTime createdAt;
  final String? teamId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'orgType': orgType?.value,
      'orgId': orgId,
      'department': department,
      'departmentCode': departmentCode,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'teamId': teamId,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectionReason': rejectionReason,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: (map['userId'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      firstName: (map['firstName'] as String?) ?? '',
      lastName: (map['lastName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'STU',
      orgType: OrganizationType.fromFirestoreValue(map['orgType']),
      orgId: (map['orgId'] as String?) ?? '',
      department: (map['department'] as String?) ?? '',
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      status: UserStatus.fromRaw((map['status'] as String?) ?? ''),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      teamId: (map['teamId'] as String?)?.trim().isEmpty == true ? null : (map['teamId'] as String?)?.trim(),
      approvedBy: (map['approvedBy'] as String?)?.trim(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: (map['rejectionReason'] as String?)?.trim(),
    );
  }

  UserModel copyWith({
    String? userId,
    String? phone,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    OrganizationType? orgType,
    String? orgId,
    String? department,
    String? departmentCode,
    UserStatus? status,
    DateTime? createdAt,
    String? teamId,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      orgType: orgType ?? this.orgType,
      orgId: orgId ?? this.orgId,
      department: department ?? this.department,
      departmentCode: departmentCode ?? this.departmentCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      teamId: teamId ?? this.teamId,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
