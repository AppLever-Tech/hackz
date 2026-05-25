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
    this.summary = '',
    this.background = '',
    this.impact = '',
    this.stakeholders = '',
    this.researchContext = '',
    this.expectedSolution = '',
    this.successCriteria = '',
    this.expectedDeliverables = '',
    this.suggestedTechnologies = const <String>[],
    this.constraints = '',
    this.difficultyLevel = '',
    this.timeline = '',
    this.complexityLevel = '',
    this.youtubeLink = '',
    this.datasetLink = '',
    this.referenceLinks = const <String>[],
    this.contactInformation = '',
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

  // Innovation context (Section 2).
  final String summary;
  final String background;
  final String impact;
  final String stakeholders;
  final String researchContext;

  // Expected outcomes (Section 3).
  final String expectedSolution;
  final String successCriteria;
  final String expectedDeliverables;
  final List<String> suggestedTechnologies;

  // Constraints & feasibility (Section 4).
  final String constraints;
  final String difficultyLevel;
  final String timeline;
  final String complexityLevel;

  // Resources & contact (Section 6).
  final String youtubeLink;
  final String datasetLink;
  final List<String> referenceLinks;
  final String contactInformation;

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
      'summary': summary,
      'background': background,
      'impact': impact,
      'stakeholders': stakeholders,
      'researchContext': researchContext,
      'expectedSolution': expectedSolution,
      'successCriteria': successCriteria,
      'expectedDeliverables': expectedDeliverables,
      'suggestedTechnologies': suggestedTechnologies,
      'constraints': constraints,
      'difficultyLevel': difficultyLevel,
      'timeline': timeline,
      'complexityLevel': complexityLevel,
      'youtubeLink': youtubeLink,
      'datasetLink': datasetLink,
      'referenceLinks': referenceLinks,
      'contactInformation': contactInformation,
    };
  }

  factory ProblemModel.fromMap(String problemId, Map<String, dynamic> map) {
    List<String> stringList(String key) {
      return (map[key] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }

    String str(String key) => (map[key] as String?) ?? '';

    return ProblemModel(
      problemId: (map['problemId'] as String?)?.trim().isNotEmpty == true
          ? (map['problemId'] as String).trim()
          : problemId,
      problemNumber: str('problemNumber'),
      title: str('title'),
      description: str('description'),
      orgId: str('orgId'),
      orgType: str('orgType'),
      departmentCode: str('departmentCode').trim().toUpperCase(),
      createdBy: str('createdBy'),
      category: str('category'),
      theme: str('theme'),
      tags: stringList('tags'),
      attachments: stringList('attachments'),
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      summary: str('summary'),
      background: str('background'),
      impact: str('impact'),
      stakeholders: str('stakeholders'),
      researchContext: str('researchContext'),
      expectedSolution: str('expectedSolution'),
      successCriteria: str('successCriteria'),
      expectedDeliverables: str('expectedDeliverables'),
      suggestedTechnologies: stringList('suggestedTechnologies'),
      constraints: str('constraints'),
      difficultyLevel: str('difficultyLevel'),
      timeline: str('timeline'),
      complexityLevel: str('complexityLevel'),
      youtubeLink: str('youtubeLink'),
      datasetLink: str('datasetLink'),
      referenceLinks: stringList('referenceLinks'),
      contactInformation: str('contactInformation'),
    );
  }

  String get departmentDisplayName => DepartmentModel.byCode(departmentCode)?.name ?? departmentCode;
}
