import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/organization_type.dart';

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.website,
    required this.contact,
    required this.createdAt,
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String address;
  final String website;
  final String contact;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.value,
      'address': address,
      'website': website,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrganizationModel.fromMap(String id, Map<String, dynamic> map) {
    return OrganizationModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      type: OrganizationType.fromFirestoreValue(map['type']) ?? OrganizationType.college,
      address: (map['address'] as String?) ?? '',
      website: (map['website'] as String?) ?? '',
      contact: (map['contact'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    OrganizationType? type,
    String? address,
    String? website,
    String? contact,
    DateTime? createdAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      website: website ?? this.website,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
