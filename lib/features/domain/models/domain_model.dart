/// Domain — lightweight classification under a Department (Department → Domain → Problem).
class DomainModel {
  const DomainModel({
    required this.domainId,
    required this.departmentId,
    required this.code,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.orgId = '',
  });

  final String domainId;
  /// Firestore department document id.
  final String departmentId;
  final String code;
  final String name;
  final String description;
  final bool isActive;
  /// Org scope (stored for queries; set on create).
  final String orgId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'domainId': domainId,
      'departmentId': departmentId,
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'description': description.trim(),
      'isActive': isActive,
      'orgId': orgId.trim(),
    };
  }

  factory DomainModel.fromMap(String domainId, Map<String, dynamic> map) {
    String str(String key) => ((map[key] as String?) ?? '').trim();
    return DomainModel(
      domainId: str('domainId').isNotEmpty ? str('domainId') : domainId,
      departmentId: str('departmentId'),
      code: str('code').toUpperCase(),
      name: str('name'),
      description: str('description'),
      isActive: map['isActive'] as bool? ?? true,
      orgId: str('orgId'),
    );
  }

  DomainModel copyWith({
    String? name,
    String? description,
    bool? isActive,
    String? code,
  }) {
    return DomainModel(
      domainId: domainId,
      departmentId: departmentId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      orgId: orgId,
    );
  }

  String get displayLabel {
    final String n = name.trim();
    final String c = code.trim();
    if (n.isEmpty) return c;
    if (c.isEmpty) return n;
    return '$n ($c)';
  }
}
