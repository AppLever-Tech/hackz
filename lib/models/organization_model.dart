import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/organization_type.dart';

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final OrganizationType type;
  final String address;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
      'type': type.value,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrganizationModel.fromMap(String id, Map<String, dynamic> map) {
    return OrganizationModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      type: OrganizationType.fromFirestoreValue(map['type']) ?? OrganizationType.college,
      address: (map['address'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? code,
    OrganizationType? type,
    String? address,
    DateTime? createdAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
