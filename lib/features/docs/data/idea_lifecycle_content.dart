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
    DocSectionSpec(id: flow, title: 'Submission & Evaluation Flow'),
    DocSectionSpec(id: roles, title: 'Role Responsibilities'),
    DocSectionSpec(id: transitions, title: 'Automatic vs Manual Transitions'),
    DocSectionSpec(id: rules, title: 'Key Business Rules'),
    DocSectionSpec(id: faq, title: 'FAQ'),
  ];

  static List<String> get searchCorpus => const <String>[
        'draft submitted underEvaluation evaluated readyForShortlisting',
        'shortlisted rejected ideathonAssigned ideathonEvaluated',
        'prototypeSelected winner archived',
        'faculty coordinator department admin judges system',
        'requiredJudgeEvaluations EvaluationAggregationSyncService',
        'payment verification evaluation assignment shortlisting',
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
              'Complete lifecycle of an innovation idea from submission through evaluation, shortlisting, ideathon, prototype selection and winner declaration.',
          lastUpdated: DateTime(2026, 7, 30),
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
                  _summaryCard(context, 'Draft', 'Faculty submission', DocStatusKind.draft, cols, c.maxWidth),
                  _summaryCard(context, 'Submitted', 'Payment verified', DocStatusKind.custom, cols, c.maxWidth),
                  _summaryCard(context, 'Under Evaluation', 'Judges assigned', DocStatusKind.inactive, cols, c.maxWidth),
                  _summaryCard(context, 'Ready for Shortlisting', 'Threshold met', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Shortlisted', 'Advances to ideathon', DocStatusKind.active, cols, c.maxWidth),
                  _summaryCard(context, 'Prototype Selected', 'After ideathon', DocStatusKind.custom, cols, c.maxWidth),
                  _summaryCard(context, 'Winner', 'Final declaration', DocStatusKind.custom, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
        _section(
          id: IdeaLifecycleSections.lifecycle,
          title: 'Idea Status Lifecycle',
          subtitle: 'Track B — every idea progresses through structured IdeaStatus values after an Active problem.',
          child: DocumentationTimeline(
            axis: DocTimelineAxis.vertical,
            items: <({String title, String body, Widget? pill})>[
              (
                title: 'Idea Draft',
                body:
                    'Status: draft. Faculty submits an innovation for an Active problem from the Innovation Submission Workspace. Team becomes locked. Payment verification may be required before evaluation.',
                pill: const DocumentationStatusPill(label: 'draft', kind: DocStatusKind.draft),
              ),
              (
                title: 'Submitted',
                body:
                    'Status: submitted. Coordinator verifies payment. Problem remains Active. Idea enters the evaluation pipeline.',
                pill: const DocumentationStatusPill(label: 'submitted'),
              ),
              (
                title: 'Under Evaluation',
                body:
                    'Status: underEvaluation. Department Admin assigns judges from Evaluation Assignment. An evaluation assignment group is created and linked to Problem + Idea.',
                pill: const DocumentationStatusPill(label: 'underEvaluation'),
              ),
              (
                title: 'Evaluated',
                body:
                    'Status: evaluated. Judges complete scoring. System advances via EvaluationAggregationSyncService. Aggregated evaluation and required evaluation count are checked.',
                pill: const DocumentationStatusPill(label: 'evaluated', kind: DocStatusKind.active),
              ),
              (
                title: 'Ready For Shortlisting',
                body:
                    'Status: readyForShortlisting. System detects evaluationCount ≥ requiredJudgeEvaluations (org setting). Department Admin can review Evaluation Results.',
                pill: const DocumentationStatusPill(label: 'readyForShortlisting', kind: DocStatusKind.active),
              ),
              (
                title: 'Shortlisted',
                body:
                    'Status: shortlisted. Manual decision by Department Admin from Evaluation Results. Idea may proceed to ideathon.',
                pill: const DocumentationStatusPill(label: 'shortlisted', kind: DocStatusKind.active),
              ),
              (
                title: 'Rejected',
                body:
                    'Status: rejected. Manual rejection by Department Admin from Evaluation Results. Lifecycle stops for this idea.',
                pill: const DocumentationStatusPill(label: 'rejected', kind: DocStatusKind.inactive),
              ),
              (
                title: 'Ideathon Assigned',
                body:
                    'Status: ideathonAssigned. Department Admin assigns the shortlisted idea to an Ideathon.',
                pill: const DocumentationStatusPill(label: 'ideathonAssigned'),
              ),
              (
                title: 'Ideathon Evaluated',
                body:
                    'Status: ideathonEvaluated. Ideathon judging completes. Judges evaluate; System records results.',
                pill: const DocumentationStatusPill(label: 'ideathonEvaluated', kind: DocStatusKind.active),
              ),
              (
                title: 'Prototype Selected',
                body:
                    'Status: prototypeSelected. Department Admin selects the winning prototype from ideathon results.',
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
        ),
        _section(
          id: IdeaLifecycleSections.statuses,
          title: 'Status Descriptions',
          child: DocumentationTable(
            headers: const <String>['Status', 'Firestore', 'Trigger', 'Role'],
            rows: const <List<String>>[
              <String>['Idea Draft', 'draft', 'Faculty submits on Active problem', 'Faculty'],
              <String>['Submitted', 'submitted', 'Payment verified', 'Coordinator'],
              <String>['Under Evaluation', 'underEvaluation', 'Judges assigned', 'Department Admin'],
              <String>['Evaluated', 'evaluated', 'Judges complete scoring', 'Judges / System'],
              <String>[
                'Ready For Shortlisting',
                'readyForShortlisting',
                'evaluationCount ≥ requiredJudgeEvaluations',
                'System',
              ],
              <String>['Shortlisted', 'shortlisted', 'Manual shortlist', 'Department Admin'],
              <String>['Rejected', 'rejected', 'Manual rejection', 'Department Admin'],
              <String>['Ideathon Assigned', 'ideathonAssigned', 'Assigned to Ideathon', 'Department Admin'],
              <String>['Ideathon Evaluated', 'ideathonEvaluated', 'Ideathon judging done', 'Judges / System'],
              <String>['Prototype Selected', 'prototypeSelected', 'Prototype chosen', 'Department Admin'],
              <String>['Winner', 'winner', 'Final declaration', 'Department Admin'],
              <String>['Archived', 'archived', 'Historical terminal state', 'System'],
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.flow,
          title: 'Submission & Evaluation Flow',
          subtitle: 'Business path from an Active problem through winner and archive.',
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
                _flowLine(context, 'Department Admin assigns judges → Under Evaluation'),
                _flowArrow(context),
                _flowLine(context, 'Judges evaluate → Evaluated'),
                _flowArrow(context),
                _flowLine(context, 'System checks requiredJudgeEvaluations → Ready For Shortlisting'),
                _flowArrow(context),
                _flowLine(context, 'Department Admin → Shortlisted or Rejected'),
                _flowArrow(context),
                _flowLine(context, 'Shortlisted → Ideathon Assigned → Ideathon Evaluated'),
                _flowArrow(context),
                _flowLine(context, 'Prototype Selected → Winner → Archived'),
                const SizedBox(height: 12),
                DocumentationInfoCard(
                  tone: DocInfoTone.note,
                  title: 'Rejected stops here',
                  body:
                      'Rejected ideas do not enter Ideathons. Only Shortlisted ideas continue to Ideathon Assigned and beyond.',
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
                'Assign judges, review evaluations, shortlist, reject, assign Ideathon, select prototype, declare winner',
              ],
              <String>['Judges', 'Evaluate ideas, submit scores, submit comments'],
              <String>[
                'System',
                'Aggregate scores, detect evaluation completion, compute averages, apply requiredJudgeEvaluations, transition to Ready For Shortlisting',
              ],
            ],
          ),
        ),
        _section(
          id: IdeaLifecycleSections.transitions,
          title: 'Automatic vs Manual Transitions',
          child: DocumentationTable(
            headers: const <String>['Type', 'Action'],
            rows: const <List<String>>[
              <String>['Manual', 'Faculty submits idea'],
              <String>['Manual', 'Coordinator verifies payment'],
              <String>['Manual', 'Department Admin assigns judges'],
              <String>['Manual', 'Department Admin shortlists'],
              <String>['Manual', 'Department Admin rejects'],
              <String>['Manual', 'Department Admin assigns Ideathon'],
              <String>['Manual', 'Department Admin selects prototype'],
              <String>['Manual', 'Department Admin declares winner'],
              <String>['Automatic', 'Evaluation aggregation'],
              <String>['Automatic', 'ReadyForShortlisting transition'],
              <String>['Automatic', 'Evaluation count reconciliation'],
              <String>['Automatic', 'Status synchronization'],
              <String>['Automatic', 'Archive (future lifecycle)'],
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
                'Judges never change Idea Status directly.',
                'System controls evaluation aggregation.',
                'ReadyForShortlisting is always a System transition.',
                'Department Admin makes the final shortlisting decision.',
                'Rejected ideas stop the lifecycle.',
                'Only Shortlisted ideas enter Ideathons.',
                'Prototype selection happens after Ideathon evaluation.',
                'Winner is declared after prototype evaluation.',
                'Archived is a historical terminal state.',
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
                    'After Faculty creates a Draft and the Coordinator verifies payment. That verification advances Draft → Submitted and places the idea in the evaluation pipeline.',
              ),
              (
                title: 'Who assigns judges?',
                body:
                    'Department Admin assigns judges from the Evaluation Assignment workspace. That action creates an evaluation assignment group linked to the Problem and Idea, and moves the idea to Under Evaluation.',
              ),
              (
                title: 'How is Ready For Shortlisting calculated?',
                body:
                    'The System compares evaluationCount to org setting requiredJudgeEvaluations. When evaluationCount ≥ requiredJudgeEvaluations, EvaluationAggregationSyncService advances the idea to readyForShortlisting automatically.',
              ),
              (
                title: 'Can judges shortlist ideas?',
                body:
                    'No. Judges score and comment only. Shortlist and reject decisions are made by Department Admin from Evaluation Results after the System marks Ready For Shortlisting.',
              ),
              (
                title: 'Can rejected ideas enter Ideathon?',
                body:
                    'No. Rejected is a terminal branch for the competitive path. Only Shortlisted ideas are assigned to Ideathons.',
              ),
              (
                title: 'Who selects prototypes?',
                body:
                    'Department Admin selects the prototype after Ideathon evaluation completes (status ideathonEvaluated → prototypeSelected).',
              ),
              (
                title: 'When is Winner assigned?',
                body:
                    'After prototype selection, Department Admin declares the final winner. Usage is restricted and typically follows ideathon / prototype outcomes.',
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
