import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_hero.dart';
import 'docs_asset_paths.dart';

/// Section ids for Idea Lifecycle TOC.
abstract final class IdeaLifecycleSections {
  static const String infographic = 'infographic';
  static const String summary = 'summary';
  static const String lifecycle = 'lifecycle';
  static const String statuses = 'statuses';
  static const String flow = 'flow';
  static const String roles = 'roles';
  static const String transitions = 'transitions';
  static const String rules = 'rules';
  static const String faq = 'faq';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: infographic, title: 'Lifecycle Infographic'),
    DocSectionSpec(id: summary, title: 'Quick Summary'),
    DocSectionSpec(id: lifecycle, title: 'Idea Status Lifecycle'),
    DocSectionSpec(id: statuses, title: 'Status Descriptions'),
    DocSectionSpec(id: flow, title: 'Submission & Ideathon Flow'),
    DocSectionSpec(id: roles, title: 'Role Responsibilities'),
    DocSectionSpec(id: transitions, title: 'Automatic vs Manual Transitions'),
    DocSectionSpec(id: rules, title: 'Key Business Rules'),
    DocSectionSpec(id: faq, title: 'FAQ'),
  ];

  static List<String> get searchCorpus => const <String>[
        'problem draft submitted idea status',
        'ideathon participation payment pending ready for execution',
        'evaluation aggregate score reused for ideathon evaluation',
        'faculty coordinator department admin judges system',
        'ideathon participation minimum ideas org setting',
        'submitted idea added to ideathon via participation record',
      ];
}

/// Builds Idea Lifecycle documentation body sections.
class IdeaLifecycleDocBody extends StatelessWidget {
  const IdeaLifecycleDocBody({
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
          title: 'Idea Lifecycle',
          description:
              'An innovation idea has just two statuses — Draft and Submitted. Ideathon participation (payment, readiness) is tracked separately on an IdeathonParticipation record once a submitted idea is added to an Ideathon.',
          lastUpdated: DateTime(2026, 8, 9),
          readingMinutes: 5,
          imageAsset: DocsAssetPaths.ideaLifecycle,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: IdeaLifecycleSections.infographic,
          title: 'Lifecycle Infographic',
          subtitle: 'Tap the image to enlarge. Maintains aspect ratio on web and mobile.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.ideaLifecycle,
            maxHeight: 420,
            semanticLabel: 'Idea lifecycle infographic',
          ),
        ),
        _section(
          id: IdeaLifecycleSections.summary,
          title: 'Quick Summary',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100
                  ? 4
                  : (c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1));
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _summaryCard(context, 'Problem', 'Active problem catalog', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Idea Draft', 'Being authored by faculty', DocStatusKind.draft, cols, c.maxWidth),
                  _summaryCard(context, 'Idea Submitted', 'Locked, eligible for an Ideathon', DocStatusKind.custom, cols, c.maxWidth),
                  _summaryCard(context, 'Ideathon Participation', 'Payment → ready for execution', DocStatusKind.active, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
        _section(
          id: IdeaLifecycleSections.lifecycle,
          title: 'Idea Status Lifecycle',
          subtitle: 'Ideas only ever hold two statuses. Everything past submission is tracked on IdeathonParticipation.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTimeline(
                axis: DocTimelineAxis.vertical,
                items: <({String title, String body, Widget? pill})>[
                  (
                    title: 'Problem',
                    body:
                        'An Active problem is published in the catalog. Faculty can submit innovations only against Active problems.',
                    pill: const DocumentationStatusPill(label: 'problem', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Idea Draft',
                    body:
                        'Status: draft. Faculty submits an innovation from the Innovation Submission Workspace. The idea can still be edited while in this status.',
                    pill: const DocumentationStatusPill(label: 'draft', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Idea Submitted',
                    body:
                        'Status: submitted. The idea is finalized and locked. Submitted ideas are the pool eligible to be added to an Ideathon.',
                    pill: const DocumentationStatusPill(label: 'submitted'),
                  ),
                  (
                    title: 'Added to an Ideathon',
                    body:
                        'A submitted idea can be added to an Ideathon once the org reaches its minimum-ideas threshold. This creates an IdeathonParticipation record — the idea itself stays "submitted".',
                    pill: const DocumentationStatusPill(label: 'participation: paymentPending'),
                  ),
                  (
                    title: 'Ready For Execution',
                    body:
                        'Once the participation payment is verified, the IdeathonParticipation status moves to readyForExecution. Ideathon evaluation, scoring, and results reuse the shared evaluation infrastructure (assignments, scoring, aggregation).',
                    pill: const DocumentationStatusPill(label: 'participation: readyForExecution', kind: DocStatusKind.active),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Evaluation aggregates stay on the idea',
                body:
                    'Average score, evaluator count, and rank remain on the idea record regardless of status, so judge scoring and results screens keep working when evaluation runs during Ideathon participation.',
              ),
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.statuses,
          title: 'Status Descriptions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTable(
                headers: const <String>['Status', 'Naming', 'Trigger', 'Role'],
                rows: const <List<String>>[
                  <String>['Idea Draft', 'draft', 'Faculty submits on an Active problem', 'Faculty'],
                  <String>['Idea Submitted', 'submitted', 'Faculty finalizes and locks the idea', 'Faculty'],
                  <String>['Payment Pending', 'paymentPending', 'Idea added to an Ideathon', 'Department Admin / Coordinator'],
                  <String>['Ready For Execution', 'readyForExecution', 'Ideathon participation payment verified', 'Coordinator'],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'IdeaStatus vs IdeathonParticipationStatus',
                body:
                    'IdeaStatus (draft, submitted) describes the idea document itself. IdeathonParticipationStatus (paymentPending, readyForExecution) is a separate, per-Ideathon record — an idea keeps its "submitted" status the entire time it participates in one or more Ideathons.',
              ),
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.flow,
          title: 'Submission & Ideathon Flow',
          subtitle: 'Business path from an Active problem through Ideathon participation.',
          child: DocumentationCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _flowLine(context, 'Problem Active'),
                _flowArrow(context),
                _flowLine(context, 'Faculty submits idea → Draft'),
                _flowArrow(context),
                _flowLine(context, 'Faculty finalizes → Submitted'),
                _flowArrow(context),
                _flowLine(context, 'Org reaches minimum submitted ideas for an Ideathon'),
                _flowArrow(context),
                _flowLine(context, 'Idea added to Ideathon → IdeathonParticipation (paymentPending)'),
                _flowArrow(context),
                _flowLine(context, 'Participation payment verified → readyForExecution'),
                const SizedBox(height: 12),
                DocumentationInfoCard(
                  tone: DocInfoTone.note,
                  title: 'The idea status never changes past Submitted',
                  body:
                      'Once an idea is submitted, all Ideathon-related state (assignment, payment, readiness) lives on its IdeathonParticipation record, not on the idea document.',
                ),
                const SizedBox(height: 12),
                DocumentationInfoCard(
                  tone: DocInfoTone.information,
                  title: 'Evaluation infrastructure retained',
                  body:
                      'Assignment, scoring, and aggregation capabilities exist independently of idea status and are reused for Ideathon evaluation.',
                ),
              ],
            ),
          ),
        ),
        _section(
          id: IdeaLifecycleSections.roles,
          title: 'Role Responsibilities',
          child: DocumentationTable(
            headers: const <String>['Role', 'Responsibilities'],
            rows: const <List<String>>[
              <String>['Faculty', 'Submit and finalize innovation, maintain team'],
              <String>['Coordinator', 'Verify Ideathon participation payment'],
              <String>[
                'Department Admin',
                'Add eligible submitted ideas to Ideathons, run Ideathon operations',
              ],
              <String>[
                'Judges',
                'Evaluate assigned ideas during Ideathon phases; submit scores and comments',
              ],
              <String>[
                'System',
                'Maintain evaluation aggregates on the idea record; sync IdeathonParticipation status from payment verification',
              ],
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.transitions,
          title: 'Automatic vs Manual Transitions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTable(
                headers: const <String>['Type', 'Action'],
                rows: const <List<String>>[
                  <String>['Manual', 'Faculty submits idea (Draft)'],
                  <String>['Manual', 'Faculty finalizes idea (Submitted)'],
                  <String>['Manual', 'Department Admin adds a submitted idea to an Ideathon'],
                  <String>['Manual', 'Coordinator verifies Ideathon participation payment'],
                  <String>['Automatic', 'Evaluation aggregation sync on the idea (average score, evaluator count)'],
                  <String>['Automatic', 'IdeathonParticipation → readyForExecution once payment is verified'],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Not part of the current flow',
                body:
                    'Automatic advancement from evaluation scores into Ideathon participation and recommendation-engine selection are not part of the product flow. Adding an idea to an Ideathon is always a manual Department Admin action.',
              ),
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.rules,
          title: 'Key Business Rules',
          child: DocumentationCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <String>[
                'Ideas can only be submitted against Active Problems.',
                'Faculty creates Draft ideas; finalizing moves Draft → Submitted.',
                'IdeaStatus only ever has two values: draft and submitted.',
                'Only Submitted ideas are eligible to be added to an Ideathon.',
                'An org must reach its configured minimum submitted-ideas threshold before an Ideathon can start.',
                'Adding an idea to an Ideathon creates an IdeathonParticipation record (status: paymentPending); the idea keeps its Submitted status.',
                'Verifying the participation payment moves IdeathonParticipation to readyForExecution.',
                'Judges never change Idea Status directly — they submit scores that update the idea\'s evaluation aggregate.',
                'Evaluation infrastructure (assignments, scoring, aggregation) is reused for Ideathon evaluation.',
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
          id: IdeaLifecycleSections.faq,
          title: 'FAQ',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'When does an idea become Submitted?',
                body:
                    'After Faculty finalizes a Draft idea from the Innovation Submission Workspace. That action advances Draft → Submitted and locks the idea for editing.',
              ),
              (
                title: 'How do ideas enter an Ideathon?',
                body:
                    'A Department Admin adds an eligible Submitted idea to an Ideathon once the org has reached its minimum-ideas threshold. This creates an IdeathonParticipation record; the idea itself stays Submitted.',
              ),
              (
                title: 'Does the idea status change once it joins an Ideathon?',
                body:
                    'No. IdeaStatus stays Submitted. Ideathon-specific state (payment, readiness) is tracked on the separate IdeathonParticipation record.',
              ),
              (
                title: 'What does readyForExecution mean?',
                body:
                    'It means the Ideathon participation payment has been verified for that idea, so it is ready for Ideathon-phase evaluation and execution.',
              ),
              (
                title: 'Can judges decide Ideathon entry?',
                body:
                    'No. Judges score and comment during evaluation; entry into an Ideathon is a manual Department Admin action, not an automatic result of scores.',
              ),
              (
                title: 'What happened to statuses like "Ideathon Assigned" or "Winner"?',
                body:
                    'They have been replaced. Idea documents only carry draft/submitted status; Ideathon assignment, execution, and outcomes are modeled on IdeathonParticipation and future Ideathon-execution records instead.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _flowLine(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _flowArrow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(
        Icons.arrow_downward_rounded,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
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
