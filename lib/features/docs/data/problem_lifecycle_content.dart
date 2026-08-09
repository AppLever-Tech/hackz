import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import '../widgets/documentation_mermaid_diagram.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_hero.dart';
import 'docs_asset_paths.dart';

/// Section ids for Problem Lifecycle TOC.
abstract final class ProblemLifecycleSections {
  static const String infographic = 'infographic';
  static const String summary = 'summary';
  static const String lifecycle = 'lifecycle';
  static const String statuses = 'statuses';
  static const String classification = 'classification';
  static const String sources = 'sources';
  static const String submission = 'submission';
  static const String transitions = 'transitions';
  static const String roles = 'roles';
  static const String notes = 'notes';
  static const String faq = 'faq';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: infographic, title: 'Lifecycle Infographic'),
    DocSectionSpec(id: summary, title: 'Quick Summary'),
    DocSectionSpec(id: lifecycle, title: 'Problem Lifecycle'),
    DocSectionSpec(id: statuses, title: 'Problem Statuses'),
    DocSectionSpec(id: classification, title: 'Problem Classification'),
    DocSectionSpec(id: sources, title: 'Created Sources'),
    DocSectionSpec(id: submission, title: 'Submission Rules'),
    DocSectionSpec(id: transitions, title: 'State Transition'),
    DocSectionSpec(id: roles, title: 'Role Responsibilities'),
    DocSectionSpec(id: notes, title: 'Key Notes'),
    DocSectionSpec(id: faq, title: 'FAQ'),
  ];

  static List<String> get searchCorpus => const <String>[
        'draft active inactive archived',
        'csv import manual authoring',
        'college admin activate deactivate',
        'department admin domain category theme',
        'faculty submit ideas submission deadline max ideas',
        'idea lifecycle begins after active',
      ];
}

/// Builds Problem Lifecycle documentation body sections.
class ProblemLifecycleDocBody extends StatelessWidget {
  const ProblemLifecycleDocBody({
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
          title: 'Problem Lifecycle',
          description:
              'End-to-end catalog lifecycle for Hackz problem statements — from CSV draft and manual publish through activation, inactivity, and archival.',
          lastUpdated: DateTime(2026, 7, 30),
          readingMinutes: 8,
          imageAsset: DocsAssetPaths.problemLifecycle,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: ProblemLifecycleSections.infographic,
          title: 'Lifecycle Infographic',
          subtitle: 'Tap the image to enlarge. Maintains aspect ratio on web and mobile.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.problemLifecycle,
            maxHeight: 420,
            semanticLabel: 'Problem lifecycle infographic',
          ),
        ),
        _section(
          id: ProblemLifecycleSections.summary,
          title: 'Quick Summary',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _summaryCard(context, 'Draft', 'CSV imports only', DocStatusKind.draft, cols, c.maxWidth),
                  _summaryCard(context, 'Active', 'Accepts idea submissions', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Inactive', 'No new submissions', DocStatusKind.inactive, cols, c.maxWidth),
                  _summaryCard(context, 'Archived', 'Historical / reserved', DocStatusKind.archived, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
        _section(
          id: ProblemLifecycleSections.lifecycle,
          title: 'Problem Lifecycle',
          subtitle: 'Four catalog stages. Idea evaluation hangs off Active — it is not a ProblemStatus.',
          child: DocumentationTimeline(
            axis: DocTimelineAxis.vertical,
            items: <({String title, String body, Widget? pill})>[
              (
                title: 'Stage 1 — Draft',
                body:
                    'CSV imported problems only. Starts as Draft. College Admin activates. Department Admin edits own drafts. Delete allowed only while Draft.',
                pill: const DocumentationStatusPill(label: 'Draft', kind: DocStatusKind.draft),
              ),
              (
                title: 'Stage 2 — Active',
                body:
                    'Manual problems start here. Accepts idea submissions when status is Active, deadline not reached, and max idea limit not reached.',
                pill: const DocumentationStatusPill(label: 'Active', kind: DocStatusKind.active),
              ),
              (
                title: 'Stage 3 — Inactive',
                body:
                    'Visible in catalog. No new submissions. Existing ideas continue their lifecycle. College Admin can reactivate.',
                pill: const DocumentationStatusPill(label: 'Inactive', kind: DocStatusKind.inactive),
              ),
              (
                title: 'Stage 4 — Archived',
                body: 'Historical catalog state. Reserved in the model for future retirement of problems.',
                pill: const DocumentationStatusPill(label: 'Archived', kind: DocStatusKind.archived),
              ),
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.statuses,
          title: 'Problem Statuses',
          child: DocumentationTable(
            headers: const <String>['Status', 'Firestore', 'Meaning'],
            rows: const <List<String>>[
              <String>['Draft', 'draft', 'Awaiting review before activation'],
              <String>['Active', 'active', 'Teams can view and submit innovations'],
              <String>['Inactive', 'inactive', 'New submissions restricted'],
              <String>['Archived', 'archived', 'Removed from active catalog (reserved)'],
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.classification,
          title: 'Problem Classification',
          child: Column(
            children: <Widget>[
              DocumentationCard(
                title: 'Required',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <String>[
                    'Title',
                    'Description',
                    'Department',
                    'Domain',
                    'Category',
                    'Theme',
                  ]
                      .map((String e) => Chip(label: Text(e)))
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'Optional',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <String>[
                    'Tags',
                    'Attachments',
                    'Max Ideas',
                    'Submission Deadline',
                    'Team Size',
                    'Preferred Tech Stack',
                  ]
                      .map((String e) => Chip(label: Text(e)))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.sources,
          title: 'Created Sources',
          child: DocumentationTable(
            headers: const <String>['Source', 'Initial status', 'Who', 'Notes'],
            rows: const <List<String>>[
              <String>['Manual', 'Active', 'College Admin / Department Admin', 'Published immediately'],
              <String>['CSV Import', 'Draft', 'College Admin / Department Admin', 'Requires College Admin activation'],
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.submission,
          title: 'Submission Rules',
          child: Column(
            children: <Widget>[
              DocumentationInfoCard(
                tone: DocInfoTone.success,
                title: 'Problem must be Active',
                body: 'isSubmissionOpen is true only when ProblemStatus.active.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Submission deadline not expired',
                body: 'Per-problem ideaSubmissionDeadline blocks submit after the cutoff.',
              ),
              const SizedBox(height: 10),
              DocumentationInfoCard(
                tone: DocInfoTone.important,
                title: 'Max ideas not exceeded',
                body: 'Uses per-problem maxIdeasAllowed or org defaultMaxIdeasPerProblem.',
              ),
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.transitions,
          title: 'State Transition',
          child: DocumentationMermaidDiagram(
            title: 'Problem status diagram',
            source: r'''
stateDiagram-v2
  [*] --> active: Manual authoring
  [*] --> draft: CSV import
  draft --> active: College Admin Activate
  draft --> [*]: Delete draft
  active --> inactive: College Admin Deactivate
  inactive --> active: College Admin Reactivate
''',
          ),
        ),
        _section(
          id: ProblemLifecycleSections.roles,
          title: 'Role Responsibilities',
          child: DocumentationTable(
            headers: const <String>['Role', 'Responsibilities'],
            rows: const <List<String>>[
              <String>['College Admin', 'Activate Draft, Deactivate, Reactivate, manage complete catalog'],
              <String>['Department Admin', 'Create problems, import problems, manage department/own problems'],
              <String>['Faculty', 'View active problems, submit ideas'],
              <String>['Student', 'Participate in innovation (view catalog)'],
              <String>['Judge', 'View problem context via assigned ideas'],
              <String>['Coordinator', 'View for coordination / payments on ideas'],
            ],
          ),
        ),
        _section(
          id: ProblemLifecycleSections.notes,
          title: 'Key Notes',
          child: DocumentationCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <String>[
                'Manual problems start Active.',
                'CSV problems start Draft.',
                'Only College Admin activates Draft.',
                'Delete allowed only for Draft.',
                'Idea lifecycle begins after Active.',
                'Inactive blocks only new submissions.',
                'Existing ideas continue even if the problem becomes Inactive.',
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
          id: ProblemLifecycleSections.faq,
          title: 'FAQ',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'Why Draft?',
                body:
                    'CSV imports need a review gate before opening submissions. Draft keeps imported problems out of the live catalog until College Admin activates them.',
              ),
              (
                title: 'Why do manual problems start Active?',
                body:
                    'Authoring requires classification fields before publish. Once published from the authoring workspace, the problem is intentionally live.',
              ),
              (
                title: 'Can an Inactive problem receive ideas?',
                body:
                    'No. New submissions are blocked. Faculty see the gate as inactive.',
              ),
              (
                title: 'What happens to existing ideas?',
                body:
                    'They keep progressing through the Idea lifecycle (payment, Ideathon, evaluation) even if the problem later becomes Inactive.',
              ),
              (
                title: 'What is Archived?',
                body:
                    'A reserved catalog state in ProblemStatus for historical retirement. It appears in filters and the lifecycle strip; there is no production writer yet.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    String body,
    DocStatusKind kind,
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
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    );
  }
}
