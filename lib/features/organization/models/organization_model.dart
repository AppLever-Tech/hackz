import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/organization_access_status.dart';
import 'enums/organization_commercial_plan.dart';
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
    this.photoUrl,
    this.thumbnailUrl,
    this.status = OrganizationAccessStatus.active,
    this.commercialPlan = OrganizationCommercialPlan.perIdea,
    this.validFrom,
    this.validUntil,
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String address;
  final String website;
  final String contact;
  final DateTime createdAt;
  final String? photoUrl;
  final String? thumbnailUrl;

  /// Organisation access status on Control Plane `hkzOrganizations`.
  final OrganizationAccessStatus status;

  /// Commercial plan on Control Plane `hkzOrganizations`.
  final OrganizationCommercialPlan commercialPlan;
  final DateTime? validFrom;
  final DateTime? validUntil;

  String get avatarUrl {
    final String thumb = (thumbnailUrl ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    return (photoUrl ?? '').trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.value,
      'address': address,
      'website': website,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': (photoUrl ?? '').trim(),
      'thumbnailUrl': (thumbnailUrl ?? '').trim(),
      'status': status.wireValue,
      'commercialPlan': commercialPlan.wireValue,
      'validFrom': validFrom == null ? null : Timestamp.fromDate(validFrom!),
      'validUntil': validUntil == null ? null : Timestamp.fromDate(validUntil!),
    };
  }

  /// Catalog fields mirrored to tenant Firebase. Commercial fields stay on Control Plane.
  Map<String, dynamic> toCatalogMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.value,
      'address': address,
      'website': website,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': (photoUrl ?? '').trim(),
      'thumbnailUrl': (thumbnailUrl ?? '').trim(),
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
      photoUrl: _optionalUrl(map['photoUrl']),
      thumbnailUrl: _optionalUrl(map['thumbnailUrl']),
      status: OrganizationAccessStatus.fromWire(map['status']),
      commercialPlan: OrganizationCommercialPlan.fromWire(
        map['commercialPlan'] ?? map['accessMode'],
      ),
      validFrom: _optionalDate(map['validFrom']),
      validUntil: _optionalDate(map['validUntil']),
    );
  }

  static String? _optionalUrl(Object? value) {
    final String trimmed = (value as String? ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    OrganizationType? type,
    String? address,
    String? website,
    String? contact,
    DateTime? createdAt,
    String? photoUrl,
    String? thumbnailUrl,
    bool clearPhoto = false,
    OrganizationAccessStatus? status,
    OrganizationCommercialPlan? commercialPlan,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearValidFrom = false,
    bool clearValidUntil = false,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      website: website ?? this.website,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      thumbnailUrl: clearPhoto ? null : (thumbnailUrl ?? this.thumbnailUrl),
      status: status ?? this.status,
      commercialPlan: commercialPlan ?? this.commercialPlan,
      validFrom: clearValidFrom ? null : (validFrom ?? this.validFrom),
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
    );
  }
}
