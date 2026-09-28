import 'package:cloud_firestore/cloud_firestore.dart';

/// Control Plane `hkzOrgAdmins` record — Hackz support user and organisation assignments.
class HkzOrgAdmin {
  const HkzOrgAdmin({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.assignedOrganisationIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isActive;
  final List<String> assignedOrganisationIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final String full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isEmpty ? phone : full;
  }

  bool isAssignedToOrganisation(String organisationId) {
    final String id = organisationId.trim();
    if (id.isEmpty) return false;
    return assignedOrganisationIds.any((String orgId) => orgId.trim() == id);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'isActive': isActive,
      'assignedOrganisationIds': assignedOrganisationIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(growable: false),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory HkzOrgAdmin.fromMap(String id, Map<String, dynamic> map) {
    final List<String> orgIds = <String>[];
    final Object? raw = map['assignedOrganisationIds'];
    if (raw is List) {
      for (final Object? entry in raw) {
        final String orgId = (entry as String? ?? '').trim();
        if (orgId.isNotEmpty && !orgIds.contains(orgId)) {
          orgIds.add(orgId);
        }
      }
    }
    return HkzOrgAdmin(
      id: id.trim(),
      firstName: (map['firstName'] as String? ?? '').trim(),
      lastName: (map['lastName'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      phone: (map['phone'] as String? ?? '').trim(),
      isActive: map['isActive'] != false,
      assignedOrganisationIds: orgIds,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  HkzOrgAdmin copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    bool? isActive,
    List<String>? assignedOrganisationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HkzOrgAdmin(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      assignedOrganisationIds: assignedOrganisationIds ?? this.assignedOrganisationIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Idempotent merge of organisation ids (preserves order, no duplicates).
  static List<String> mergeOrganisationAssignments(List<String> current, String organisationId) {
    final String id = organisationId.trim();
    if (id.isEmpty) return List<String>.from(current);
    final List<String> next = <String>[];
    for (final String orgId in current) {
      final String normalized = orgId.trim();
      if (normalized.isEmpty || next.contains(normalized)) continue;
      next.add(normalized);
    }
    if (!next.contains(id)) next.add(id);
    return next;
  }

  static List<String> removeOrganisationAssignment(List<String> current, String organisationId) {
    final String id = organisationId.trim();
    if (id.isEmpty) return List<String>.from(current);
    return current.map((String orgId) => orgId.trim()).where((String orgId) => orgId.isNotEmpty && orgId != id).toList(growable: false);
  }
}
