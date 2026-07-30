import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_hero.dart';
import 'docs_asset_paths.dart';

/// Section ids for Roles & Responsibilities TOC.
abstract final class RolesResponsibilitiesSections {
  static const String infographic = 'infographic';
  static const String overview = 'overview';
  static const String matrix = 'matrix';
  static const String roleWise = 'role-wise';
  static const String ownership = 'ownership';
  static const String guidelines = 'guidelines';
  static const String principles = 'principles';
  static const String faq = 'faq';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: infographic, title: 'Roles & Responsibilities Infographic'),
    DocSectionSpec(id: overview, title: 'Role Overview'),
    DocSectionSpec(id: matrix, title: 'Responsibility Matrix'),
    DocSectionSpec(id: roleWise, title: 'Role-wise Responsibilities'),
    DocSectionSpec(id: ownership, title: 'Ownership Across Lifecycle'),
    DocSectionSpec(id: guidelines, title: 'Permission Guidelines'),
    DocSectionSpec(id: principles, title: 'Key Principles'),
    DocSectionSpec(id: faq, title: 'FAQ'),
  ];

  static List<String> get searchCorpus => const <String>[
        'college admin department admin faculty coordinator judge student',
        'activate draft deactivate reactivate assign judges shortlist',
        'verify payment evaluate idea org evaluation config catalog',
        'least privilege department isolation ownership permissions',
      ];
}

/// Builds Roles & Responsibilities documentation body sections.
class RolesResponsibilitiesDocBody extends StatelessWidget {
  const RolesResponsibilitiesDocBody({
    super.key,
    required this.sectionKeys,
    this.onPrint,
  });

  final Map<String, GlobalKey> sectionKeys;
  final VoidCallback? onPrint;

  Widget _section({
    required String id,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return DocumentationSection(
      key: sectionKeys[id],
      id: id,
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'Roles & Responsibilities',
          description:
              'Understand the responsibilities, permissions and ownership of every Hackz user role across the complete innovation lifecycle.',
          lastUpdated: DateTime(2026, 7, 30),
          readingMinutes: 5,
          imageAsset: DocsAssetPaths.rolesResponsibilities,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: RolesResponsibilitiesSections.infographic,
          title: 'Roles & Responsibilities Infographic',
          subtitle: 'Tap the image to enlarge. Maintains aspect ratio on web and mobile.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.rolesResponsibilities,
            maxHeight: 420,
            semanticLabel: 'Roles and responsibilities matrix infographic',
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.overview,
          title: 'Role Overview',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100
                  ? 3
                  : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _roleCard(
                    context,
                    'College Admin',
                    DocStatusKind.active,
                    const <String>[
                      'Organization administration',
                      'Platform governance',
                      'Problem catalog approval',
                      'Global configuration',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Department Admin',
                    DocStatusKind.custom,
                    const <String>[
                      'Department management',
                      'Problem management',
                      'Judge assignments',
                      'Shortlisting',
                      'Ideathon management',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Faculty',
                    DocStatusKind.draft,
                    const <String>[
                      'Team mentoring',
                      'Problem guidance',
                      'Innovation submission',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Coordinator',
                    DocStatusKind.inactive,
                    const <String>[
                      'Payment verification',
                      'Event coordination',
                      'Operational support',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Judge',
                    DocStatusKind.active,
                    const <String>[
                      'Evaluate assigned ideas',
                      'Submit scores',
                      'Provide feedback',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Student',
                    DocStatusKind.archived,
                    const <String>[
                      'Participate in teams',
                      'Build innovations',
                      'Submit ideas through faculty workflow',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.matrix,
          title: 'Responsibility Matrix',
          subtitle: 'Who owns each stage — with restrictions called out.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationImageViewer(
                assetPath: DocsAssetPaths.rolesResponsibilities,
                maxHeight: 360,
                semanticLabel: 'Responsibility matrix reference',
              ),
              const SizedBox(height: 16),
              DocumentationTable(
                headers: const <String>['Stage / Action', 'Owner', 'Notes'],
                rows: const <List<String>>[
                  <String>[
                    'Create Problem (Manual)',
                    'College Admin, Dept Admin',
                    'Starts Active',
                  ],
                  <String>[
                    'Import Problems',
                    'College Admin, Dept Admin',
                    'Starts Draft',
                  ],
                  <String>[
                    'Activate Draft',
                    'College Admin only',
                    'Dept Admin cannot activate',
                  ],
                  <String>[
                    'Deactivate / Reactivate',
                    'College Admin only',
                    'Catalog visibility preserved when inactive',
                  ],
                  <String>[
                    'Edit Problem',
                    'College Admin (any), Dept Admin (own)',
                    'Dept scope limited to own problems',
                  ],
                  <String>[
                    'Assign Judges',
                    'Department Admin',
                    'Evaluation Assignment workspace',
                  ],
                  <String>[
                    'Submit Idea',
                    'Faculty',
                    'Only when problem is Active and gates pass',
                  ],
                  <String>[
                    'Verify Payment',
                    'Coordinator',
                    'Draft → Submitted',
                  ],
                  <String>[
                    'Evaluate Idea',
                    'Judge (assigned)',
                    'Scores and feedback only',
                  ],
                  <String>[
                    'Shortlist / Reject',
                    'Department Admin',
                    'Only when Ready for Shortlisting',
                  ],
                  <String>[
                    'Org Evaluation Configuration',
                    'College Admin',
                    'Dept Admin reads after login',
                  ],
                  <String>[
                    'View Problem Catalog',
                    'College Admin, Dept Admin, Faculty, Student',
                    'Role-scoped visibility',
                  ],
                ],
              ),
            ],
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.roleWise,
          title: 'Role-wise Responsibilities',
          child: Column(
            children: <Widget>[
              DocumentationCard(
                title: 'College Admin',
                child: _bulletList(context, const <String>[
                  'Manage organization',
                  'Manage departments',
                  'Activate imported problems',
                  'Deactivate / reactivate problems',
                  'Configure organization settings',
                  'View complete platform',
                  'Manage application metadata',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Department Admin',
                child: _bulletList(context, const <String>[
                  'Manage department users',
                  'Manage department domains',
                  'Create problems',
                  'Import problems',
                  'Edit department problems',
                  'Assign judges',
                  'Review evaluation results',
                  'Shortlist ideas',
                  'Manage ideathons',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Faculty',
                child: _bulletList(context, const <String>[
                  'Mentor student teams',
                  'Submit innovations',
                  'Participate as Internal Judge (only if enabled in Org Settings)',
                  'Cannot evaluate own mentored ideas',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Coordinator',
                child: _bulletList(context, const <String>[
                  'Verify payments',
                  'Support event execution',
                  'Track operational readiness',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Judge',
                child: _bulletList(context, const <String>[
                  'Evaluate assigned ideas',
                  'Submit evaluation',
                  'Provide comments',
                  'Cannot modify idea lifecycle',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Student',
                child: _bulletList(context, const <String>[
                  'Join teams',
                  'Participate in innovation',
                  'View eligible problems',
                  'Build prototypes',
                ]),
              ),
            ],
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.ownership,
          title: 'Ownership Across Lifecycle',
          subtitle: 'Who participates in each major workflow.',
          child: Column(
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Problem Lifecycle',
                body:
                    'College Admin governs activation and catalog control. Department Admin authors and manages department problems. Faculty and Student consume the catalog. Judge and Coordinator use problem context during idea operations.',
              ),
              const SizedBox(height: 12),
              DocumentationTable(
                headers: const <String>['Lifecycle', 'Primary roles'],
                rows: const <List<String>>[
                  <String>[
                    'Problem Lifecycle',
                    'College Admin, Department Admin, Faculty, Student, Judge, Coordinator',
                  ],
                  <String>[
                    'Idea Lifecycle',
                    'Faculty, Coordinator, Department Admin, Judge, System',
                  ],
                  <String>[
                    'Ideathon Lifecycle',
                    'Department Admin, Judge, Coordinator, System',
                  ],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'System ownership',
                body:
                    'Aggregation, Ready for Shortlisting, and reconciliation transitions are System-owned — roles never set those statuses directly.',
              ),
            ],
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.guidelines,
          title: 'Permission Guidelines',
          child: DocumentationCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <String>[
                'College Admin has organization-wide permissions.',
                'Department Admin manages only assigned departments.',
                'Faculty can only submit ideas for Active Problems.',
                'Judges evaluate only assigned ideas.',
                'Students participate through team workflows.',
                'Coordinators cannot modify evaluations.',
                'Lifecycle transitions remain role controlled.',
                'Automatic transitions are performed only by the System.',
              ]
                  .map(
                    (String line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(AppIcons.info, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(line)),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.principles,
          title: 'Key Principles',
          child: Column(
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Least privilege access',
                body: 'Each role receives only the actions required for its workflow.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Role-based ownership',
                body: 'Manual lifecycle actions are owned by a single accountable role.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Department isolation',
                body: 'Department Admin scope is limited to assigned departments and own problems.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.success,
                title: 'System-controlled lifecycle transitions',
                body: 'Aggregation and Ready for Shortlisting are never manually forced by judges or faculty.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Manual approvals only where required',
                body: 'Activation, payment verification, shortlisting, and winner declaration stay human-gated.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Consistent audit trail',
                body: 'Role actions and system transitions together form the operational history of each idea.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Organization Settings govern configurable behavior',
                body: 'Thresholds such as requiredJudgeEvaluations and internal-judge rules come from Org Settings.',
              ),
            ],
          ),
        ),
        _section(
          id: RolesResponsibilitiesSections.faq,
          title: 'FAQ',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'Who can create problems?',
                body:
                    'College Admin and Department Admin. Manual create starts Active. CSV import starts Draft and still needs College Admin activation.',
              ),
              (
                title: 'Who activates imported problems?',
                body:
                    'Only College Admin. Department Admin can import drafts but cannot activate them.',
              ),
              (
                title: 'Who assigns judges?',
                body:
                    'Department Admin assigns judges from the Evaluation Assignment workspace for ideas that have entered the evaluation pipeline.',
              ),
              (
                title: 'Can Faculty become Judges?',
                body:
                    'Yes, as Internal Judges only when enabled in Organization Settings. Faculty cannot evaluate their own mentored ideas.',
              ),
              (
                title: 'Can Judges shortlist ideas?',
                body:
                    'No. Judges score and comment only. Shortlist and reject are Department Admin actions after Ready for Shortlisting.',
              ),
              (
                title: 'Who verifies payments?',
                body:
                    'Coordinator verifies payment, which advances Draft ideas to Submitted.',
              ),
              (
                title: 'Who manages Ideathons?',
                body:
                    'Department Admin assigns shortlisted ideas to ideathons, drives ideathon operations, and selects prototypes / winners as configured.',
              ),
              (
                title: 'What does the System do automatically?',
                body:
                    'Aggregates evaluations, reconciles evaluation counts against requiredJudgeEvaluations, advances ideas to Ready for Shortlisting, and synchronizes related statuses.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulletList(BuildContext context, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('•  ', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _roleCard(
    BuildContext context,
    String title,
    DocStatusKind kind,
    List<String> bullets,
    int cols,
    double maxWidth,
  ) {
    final double width = cols == 1 ? maxWidth : (maxWidth - 12 * (cols - 1)) / cols;
    return SizedBox(
      width: width,
      child: DocumentationCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DocumentationStatusPill(label: title, kind: kind),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            ...bullets.map(
              (String b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $b'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
