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
        'problem draft submitted ideathonAssigned ideathonEvaluated',
        'prototypeSelected winner archived',
        'underEvaluation evaluated rejected historical',
        'faculty coordinator department admin judges system',
        'ideathon assignment evaluation infrastructure payment verification',
        'submitted to ideathon assigned phase 1 lifecycle',
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
              'Complete lifecycle of an innovation idea from problem submission through Ideathon assignment, Ideathon evaluation, prototype selection and winner declaration.',
          lastUpdated: DateTime(2026, 8, 9),
          readingMinutes: 6,
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
                  _summaryCard(context, 'Idea (Submitted)', 'Payment verified', DocStatusKind.custom, cols, c.maxWidth),
                  _summaryCard(context, 'Ideathon Assigned', 'Enters Ideathon', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Ideathon Evaluated', 'Ideathon judging done', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Prototype Selected', 'After Ideathon', DocStatusKind.custom, cols, c.maxWidth),
                  _summaryCard(context, 'Winner', 'Final declaration', DocStatusKind.custom, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
        _section(
          id: IdeaLifecycleSections.lifecycle,
          title: 'Idea Status Lifecycle',
          subtitle:
              'Phase 1 primary path — ideas go Submitted → Ideathon Assigned. Evaluation infrastructure remains for Ideathon evaluation later.',
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
                        'Status: draft. Faculty submits an innovation from the Innovation Submission Workspace. Team becomes locked. Payment verification may be required before the idea is treated as submitted.',
                    pill: const DocumentationStatusPill(label: 'draft', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Idea (Submitted)',
                    body:
                        'Status: submitted. Coordinator verifies payment. The idea is eligible for Ideathon assignment — Ideas go Submitted → Ideathon Assigned.',
                    pill: const DocumentationStatusPill(label: 'submitted'),
                  ),
                  (
                    title: 'Ideathon Assigned',
                    body:
                        'Status: ideathonAssigned. Department Admin assigns the submitted idea to an Ideathon.',
                    pill: const DocumentationStatusPill(label: 'ideathonAssigned'),
                  ),
                  (
                    title: 'Ideathon Evaluated',
                    body:
                        'Status: ideathonEvaluated. Ideathon judging completes. Evaluation infrastructure (assignments, scoring, aggregation) is reused for Ideathon evaluation; it is not a pre-Ideathon gate.',
                    pill: const DocumentationStatusPill(label: 'ideathonEvaluated', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Prototype Selected',
                    body:
                        'Status: prototypeSelected. Department Admin selects the winning prototype from Ideathon results.',
                    pill: const DocumentationStatusPill(label: 'prototypeSelected'),
                  ),
                  (
                    title: 'Winner',
                    body:
                        'Status: winner. Final winner declared by Department Admin (restricted usage).',
                    pill: const DocumentationStatusPill(label: 'winner', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Archived',
                    body:
                        'Status: archived. Historical record only after event completion.',
                    pill: const DocumentationStatusPill(label: 'archived', kind: DocStatusKind.archived),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.note,
                title: 'Legacy evaluation statuses',
                body:
                    'Statuses such as underEvaluation, evaluated, and rejected may still appear on older ideas or during evaluation workflows. They are not a separate gate before Ideathon entry — new ideas follow Submitted → Ideathon Assigned.',
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
                  <String>['Idea Draft', 'draft', 'Faculty submits on Active problem', 'Faculty'],
                  <String>['Submitted', 'submitted', 'Payment verified', 'Coordinator'],
                  <String>['Ideathon Assigned', 'ideathonAssigned', 'Assigned to Ideathon', 'Department Admin'],
                  <String>['Ideathon Evaluated', 'ideathonEvaluated', 'Ideathon judging done', 'Judges / System'],
                  <String>['Prototype Selected', 'prototypeSelected', 'Prototype chosen', 'Department Admin'],
                  <String>['Winner', 'winner', 'Final declaration', 'Department Admin'],
                  <String>['Archived', 'archived', 'Historical terminal state', 'System'],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.information,
                title: 'Legacy evaluation statuses (not the Ideathon-entry gate)',
                body:
                    'underEvaluation, evaluated, and rejected may still appear on older ideas or during evaluation. Recommendation-engine selection and automatic advancement from evaluation scores into Ideathon participation are not part of the product flow — Ideas go Submitted → Ideathon Assigned.',
              ),
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.flow,
          title: 'Submission & Ideathon Flow',
          subtitle: 'Phase 1 business path from an Active problem through winner and archive.',
          child: DocumentationCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _flowLine(context, 'Problem Active'),
                _flowArrow(context),
                _flowLine(context, 'Faculty submits idea → Draft'),
                _flowArrow(context),
                _flowLine(context, 'Coordinator verifies payment → Submitted'),
                _flowArrow(context),
                _flowLine(context, 'Department Admin assigns to Ideathon → Ideathon Assigned'),
                _flowArrow(context),
                _flowLine(context, 'Ideathon judging → Ideathon Evaluated'),
                _flowArrow(context),
                _flowLine(context, 'Prototype Selected → Winner → Archived'),
                const SizedBox(height: 12),
                DocumentationInfoCard(
                  tone: DocInfoTone.note,
                  title: 'Direct Ideathon assignment',
                  body:
                      'Ideas go Submitted → Ideathon Assigned. Department Admin assigns eligible ideas to Ideathons; evaluation and selection happen in Ideathon phases, not as a separate pre-Ideathon gate.',
                ),
                const SizedBox(height: 12),
                DocumentationInfoCard(
                  tone: DocInfoTone.information,
                  title: 'Evaluation infrastructure retained',
                  body:
                      'Assignment, scoring, and aggregation capabilities still exist and will be reused for Ideathon evaluation. They are not a gate that ideas must pass before Ideathon assignment.',
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
              <String>['Faculty', 'Submit innovation, maintain team'],
              <String>['Coordinator', 'Verify payment, approve submission'],
              <String>[
                'Department Admin',
                'Assign ideas to Ideathons, run Ideathon operations, select prototype, declare winner',
              ],
              <String>[
                'Judges',
                'Evaluate during Ideathon phases (and any configured evaluation assignments); submit scores and comments',
              ],
              <String>[
                'System',
                'Support evaluation aggregation and status synchronization for Ideathon evaluation; does not auto-advance ideas into Ideathons from pre-Ideathon scores',
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
                  <String>['Manual', 'Faculty submits idea'],
                  <String>['Manual', 'Coordinator verifies payment'],
                  <String>['Manual', 'Department Admin assigns Ideathon'],
                  <String>['Manual', 'Department Admin selects prototype'],
                  <String>['Manual', 'Department Admin declares winner'],
                  <String>['Automatic', 'Ideathon evaluation aggregation / status sync (when used)'],
                  <String>['Automatic', 'Archive (future lifecycle)'],
                ],
              ),
              const SizedBox(height: 12),
              DocumentationInfoCard(
                tone: DocInfoTone.warning,
                title: 'Not part of the primary path',
                body:
                    'Automatic advancement from evaluation scores to Ideathon participation and recommendation-engine selection are not part of Phase 1 flow. Ideas go Submitted → Ideathon Assigned by Department Admin assignment.',
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
                'Faculty creates Draft ideas.',
                'Coordinator verification moves Draft → Submitted.',
                'Ideas go Submitted → Ideathon Assigned by Department Admin assignment.',
                'Evaluation scores do not automatically advance an idea into Ideathon participation.',
                'Recommendation-engine selection is not part of the product flow for Ideathon entry.',
                'Judges never change Idea Status directly.',
                'Evaluation infrastructure remains available and will be reused for Ideathon evaluation.',
                'Prototype selection happens after Ideathon evaluation.',
                'Winner is declared after prototype selection.',
                'Archived is a historical terminal state.',
                'Legacy evaluation statuses (underEvaluation, evaluated, rejected) may still appear on older ideas.',
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
                    'After Faculty creates a Draft and the Coordinator verifies payment. That verification advances Draft → Submitted. The idea is then eligible for Ideathon assignment.',
              ),
              (
                title: 'How do ideas enter an Ideathon?',
                body:
                    'Ideas go Submitted → Ideathon Assigned. Department Admin assigns Submitted ideas to Ideathons directly. There is no separate pre-Ideathon selection status on the product path.',
              ),
              (
                title: 'Can judges decide Ideathon entry?',
                body:
                    'No. Judges score and comment during configured evaluation / Ideathon judging. Ideathon entry is by Department Admin assignment from Submitted — not by judge selection or a recommendation engine.',
              ),
              (
                title: 'Who assigns ideas to Ideathons?',
                body:
                    'Department Admin assigns Submitted ideas to Ideathons (status → ideathonAssigned). Evaluation and selection then continue in Ideathon phases.',
              ),
              (
                title: 'Who selects prototypes?',
                body:
                    'Department Admin selects the prototype after Ideathon evaluation completes (status ideathonEvaluated → prototypeSelected).',
              ),
              (
                title: 'When is Winner assigned?',
                body:
                    'After prototype selection, Department Admin declares the final winner. Usage is restricted and typically follows Ideathon / prototype outcomes.',
              ),
              (
                title: 'Why is Archived required?',
                body:
                    'Archived preserves a historical terminal record after the event completes, without keeping the idea in active operational queues.',
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
