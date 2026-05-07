import 'package:cloud_firestore/cloud_firestore.dart';

import 'department_model.dart';

class ProblemModel {
  const ProblemModel({
    required this.problemId,
    required this.problemNumber,
    required this.title,
    required this.description,
    required this.orgId,
    required this.orgType,
    required this.departmentCode,
    required this.createdBy,
    required this.category,
    required this.theme,
    required this.tags,
    required this.attachments,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  final String problemId;
  final String problemNumber;
  final String title;
  final String description;
  final String orgId;
  final String orgType;
  final String departmentCode;
  final String createdBy;
  final String category;
  final String theme;
  final List<String> tags;
  final List<String> attachments;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'problemId': problemId,
      'problemNumber': problemNumber,
      'title': title,
      'description': description,
      'orgId': orgId,
      'orgType': orgType,
      'departmentCode': departmentCode,
      'createdBy': createdBy,
      'category': category,
      'theme': theme,
      'tags': tags,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ProblemModel.fromMap(String problemId, Map<String, dynamic> map) {
    return ProblemModel(
      problemId: (map['problemId'] as String?)?.trim().isNotEmpty == true
          ? (map['problemId'] as String).trim()
          : problemId,
      problemNumber: (map['problemNumber'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      orgId: (map['orgId'] as String?) ?? '',
      orgType: (map['orgType'] as String?) ?? '',
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      createdBy: (map['createdBy'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      theme: (map['theme'] as String?) ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false),
      attachments: (map['attachments'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false),
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  String get departmentDisplayName => DepartmentModel.byCode(departmentCode)?.name ?? departmentCode;
}
