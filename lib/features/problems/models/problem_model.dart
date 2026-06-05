import 'package:cloud_firestore/cloud_firestore.dart';

import '../../imports/models/import_created_source.dart';
import '../../organization/models/department_model.dart';
import 'problem_status.dart';

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
    required this.status,
    required this.createdAt,
    this.createdSource,
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
    this.maxIdeasAllowed,
    this.ideaSubmissionDeadline,
    this.minTeamSize,
    this.maxTeamSize,
    this.preferredTechStack = const <String>[],
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
  final ProblemStatus status;
  final DateTime createdAt;
  final String? createdSource;
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

  /// Submission controls — when `null`, the org-level default applies.
  /// `maxIdeasAllowed` caps the total number of ideas submitted against this
  /// problem; `ideaSubmissionDeadline` cuts off submissions after the given
  /// instant.
  final int? maxIdeasAllowed;
  final DateTime? ideaSubmissionDeadline;

  /// Team rules — when `null`, the org-level team-size bounds apply.
  final int? minTeamSize;
  final int? maxTeamSize;

  /// Free-text chip list — tech stacks the problem author would like to see
  /// in submitted ideas (e.g. "Flutter", "AI/ML", "IoT").
  final List<String> preferredTechStack;

  bool get isSubmissionOpen => status == ProblemStatus.active;

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
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      if ((createdSource ?? '').trim().isNotEmpty) 'createdSource': createdSource!.trim(),
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
      'maxIdeasAllowed': maxIdeasAllowed,
      'ideaSubmissionDeadline':
          ideaSubmissionDeadline == null ? null : Timestamp.fromDate(ideaSubmissionDeadline!),
      'minTeamSize': minTeamSize,
      'maxTeamSize': maxTeamSize,
      'preferredTechStack': preferredTechStack,
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
      status: ProblemStatus.fromRaw(str('status')),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdSource: (map['createdSource'] as String?)?.trim(),
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
      maxIdeasAllowed: (map['maxIdeasAllowed'] as num?)?.toInt(),
      ideaSubmissionDeadline: (map['ideaSubmissionDeadline'] as Timestamp?)?.toDate(),
      minTeamSize: (map['minTeamSize'] as num?)?.toInt(),
      maxTeamSize: (map['maxTeamSize'] as num?)?.toInt(),
      preferredTechStack: stringList('preferredTechStack'),
    );
  }

  ProblemModel copyWith({
    ProblemStatus? status,
    String? createdSource,
    DateTime? updatedAt,
  }) {
    return ProblemModel(
      problemId: problemId,
      problemNumber: problemNumber,
      title: title,
      description: description,
      orgId: orgId,
      orgType: orgType,
      departmentCode: departmentCode,
      createdBy: createdBy,
      category: category,
      theme: theme,
      tags: tags,
      attachments: attachments,
      status: status ?? this.status,
      createdAt: createdAt,
      createdSource: createdSource ?? this.createdSource,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary,
      background: background,
      impact: impact,
      stakeholders: stakeholders,
      researchContext: researchContext,
      expectedSolution: expectedSolution,
      successCriteria: successCriteria,
      expectedDeliverables: expectedDeliverables,
      suggestedTechnologies: suggestedTechnologies,
      constraints: constraints,
      difficultyLevel: difficultyLevel,
      timeline: timeline,
      complexityLevel: complexityLevel,
      youtubeLink: youtubeLink,
      datasetLink: datasetLink,
      referenceLinks: referenceLinks,
      contactInformation: contactInformation,
      maxIdeasAllowed: maxIdeasAllowed,
      ideaSubmissionDeadline: ideaSubmissionDeadline,
      minTeamSize: minTeamSize,
      maxTeamSize: maxTeamSize,
      preferredTechStack: preferredTechStack,
    );
  }

  String get departmentDisplayName => DepartmentModel.byCode(departmentCode)?.name ?? departmentCode;

  bool get isManual => (createdSource ?? '').trim() == ImportCreatedSource.manual.value;

  bool get isImported => (createdSource ?? '').trim() == ImportCreatedSource.csvImport.value;
}
