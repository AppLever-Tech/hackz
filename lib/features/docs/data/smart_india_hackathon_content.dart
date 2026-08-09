import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import 'docs_asset_paths.dart';
import 'docs_registry.dart';

/// Section ids for Smart India Hackathon TOC.
abstract final class SmartIndiaHackathonSections {
  static const String about = 'about-sih';
  static const String infographic = 'sih-workflow-infographic';
  static const String workflow = 'complete-sih-workflow';
  static const String howHackz = 'how-hackz-supports-sih';
  static const String whyHackz = 'why-hackz';
  static const String benefits = 'benefits';
  static const String outcomes = 'expected-outcomes';
  static const String faq = 'faq';
  static const String related = 'related-help';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: about, title: 'About Smart India Hackathon'),
    DocSectionSpec(id: infographic, title: 'SIH Workflow Infographic'),
    DocSectionSpec(id: workflow, title: 'Complete SIH Workflow'),
    DocSectionSpec(id: howHackz, title: 'How Hackz Supports SIH'),
    DocSectionSpec(id: whyHackz, title: 'Why Hackz is the Right Choice'),
    DocSectionSpec(id: benefits, title: 'Benefits to Institutions'),
    DocSectionSpec(id: outcomes, title: 'Expected Outcomes'),
    DocSectionSpec(id: faq, title: 'Frequently Asked Questions'),
    DocSectionSpec(id: related, title: 'Related Help'),
  ];

  static List<String> get searchCorpus => const <String>[
        'smart india hackathon sih 2026 internal selection shortlist nominate',
        'problem statements team formation idea submission screening mentors',
        'prototype evaluation scoring mock presentation nomination',
        'transparent rubrics analytics institution workflow',
      ];
}

/// Builds Smart India Hackathon documentation body sections.
class SmartIndiaHackathonDocBody extends StatelessWidget {
  const SmartIndiaHackathonDocBody({
    super.key,
    required this.sectionKeys,
    required this.onOpenPage,
    this.onPrint,
  });

  final Map<String, GlobalKey> sectionKeys;
  final ValueChanged<String> onOpenPage;
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

  double _cardWidth(int cols, double maxWidth) =>
      cols == 1 ? maxWidth : (maxWidth - 12 * (cols - 1)) / cols;

  Widget _bulletList(BuildContext context, List<String> lines) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(AppIcons.info, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required int cols,
    required double maxWidth,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: _cardWidth(cols, maxWidth),
      child: DocumentationCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageCard(
    BuildContext context, {
    required String name,
    required String purpose,
    required List<String> activities,
    required String outcome,
    required List<String> modules,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DocumentationCard(
      title: name,
      subtitle: purpose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Primary activities',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _bulletList(context, activities),
          const SizedBox(height: 8),
          Text(
            'Expected outcome',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            outcome,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(
            'Hackz modules used',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modules
                .map(
                  (String m) => DocumentationStatusPill(
                    label: m,
                    kind: DocStatusKind.custom,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _relatedCard(BuildContext context, DocPageDefinition page, int cols, double maxWidth) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: _cardWidth(cols, maxWidth),
      child: DocumentationCard(
        child: InkWell(
          onTap: () => onOpenPage(page.id),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(page.icon, color: cs.primary),
                  const Spacer(),
                  if (page.isPlaceholder)
                    const DocumentationStatusPill(label: 'Soon', kind: DocStatusKind.inactive),
                ],
              ),
              const SizedBox(height: 10),
              Text(page.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                page.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    'Open',
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(AppIcons.chevronRight, size: 16, color: cs.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DocPageDefinition overview = DocsRegistry.byId('platform-overview');
    final DocPageDefinition innovationProgram = DocsRegistry.byId('innovation-to-startup');
    final DocPageDefinition problemLifecycle = DocsRegistry.byId('problem-lifecycle');
    final DocPageDefinition ideaLifecycle = DocsRegistry.byId('idea-lifecycle');
    final DocPageDefinition evaluation = DocsRegistry.byId('evaluation-lifecycle');
    final DocPageDefinition ideathon = DocsRegistry.byId('ideathon');
    final DocPageDefinition hackathon = DocsRegistry.byId('hackathon');
    final DocPageDefinition roles = DocsRegistry.byId('roles-responsibilities');
    final DocPageDefinition csv = DocsRegistry.byId('csv-import');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'Smart India Hackathon',
          subtitle: 'Plan • Evaluate • Shortlist • Nominate',
          description:
              'Hackz provides a structured, transparent and data-driven platform that enables institutions to conduct their complete internal Smart India Hackathon selection process using configurable workflows, multi-level evaluations and analytics.',
          lastUpdated: DateTime(2026, 8, 6),
          readingMinutes: 7,
          imageAsset: DocsAssetPaths.smartIndiaHackathonWorkflow,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: SmartIndiaHackathonSections.about,
          title: 'About Smart India Hackathon',
          subtitle: 'Context for institutional internal selection on Hackz.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Smart India Hackathon (SIH) is a national innovation program where institutions nominate their strongest student teams to solve official problem statements. Colleges typically run an internal selection process before final nomination.',
                style: TextStyle(fontSize: 14.5, height: 1.5, color: cs.onSurface),
              ),
              const SizedBox(height: 14),
              DocumentationCard(
                title: 'Why institutions run internal rounds',
                child: _bulletList(context, const <String>[
                  'Identify the strongest teams fairly and transparently',
                  'Improve solution quality through mentoring and iteration',
                  'Track prototypes, evaluations and presentations in one place',
                  'Nominate institution representatives with auditable evidence',
                ]),
              ),
              const SizedBox(height: 12),
              DocumentationCard(
                title: 'How Hackz supports SIH selection',
                child: _bulletList(context, const <String>[
                  'Publish and manage SIH problem statements',
                  'Register students, form teams and collect idea submissions',
                  'Screen, mentor, evaluate and shortlist with structured workflows',
                  'Generate rankings and support final team nomination',
                ]),
              ),
              const SizedBox(height: 12),
              const DocumentationInfoCard(
                title: 'Internal workflow — not the official SIH process',
                body:
                    'This Help page describes how an institution can run its internal Smart India Hackathon selection using Hackz. It does not replace or document the official Smart India Hackathon rules, portals or national process.',
                tone: DocInfoTone.important,
              ),
            ],
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.infographic,
          title: 'SIH Workflow Infographic',
          subtitle: 'Tap the image to enlarge. Maintains aspect ratio on web and mobile.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.smartIndiaHackathonWorkflow,
            maxHeight: 420,
            semanticLabel: 'Smart India Hackathon internal shortlisting workflow infographic',
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.workflow,
          title: 'Complete SIH Workflow',
          subtitle: 'Eleven stages from official problem publish through institutional nomination.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTimeline(
                axis: DocTimelineAxis.vertical,
                items: <({String title, String body, Widget? pill})>[
                  (
                    title: 'SIH Problem Statements',
                    body: 'Upload and publish official SIH problem statements on Hackz.',
                    pill: const DocumentationStatusPill(label: '1', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Student Registration & Profiles',
                    body: 'Students register and complete skills, interests and experience profiles.',
                    pill: const DocumentationStatusPill(label: '2', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Team Formation',
                    body: 'Students form teams aligned to skills and problem preferences.',
                    pill: const DocumentationStatusPill(label: '3', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Idea Submission',
                    body: 'Teams submit solutions against selected problem statements.',
                    pill: const DocumentationStatusPill(label: '4', kind: DocStatusKind.inactive),
                  ),
                  (
                    title: 'Internal Screening',
                    body: 'Faculty and mentors screen ideas for relevance and feasibility.',
                    pill: const DocumentationStatusPill(label: '5', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Mentor Review & Guidance',
                    body: 'Selected teams receive feedback and iterative improvement support.',
                    pill: const DocumentationStatusPill(label: '6', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Prototype Development Tracking',
                    body: 'Track milestones, deliverables and prototype progress.',
                    pill: const DocumentationStatusPill(label: '7', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Evaluation & Scoring',
                    body: 'Multi-criteria evaluation using pre-defined rubrics.',
                    pill: const DocumentationStatusPill(label: '8', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Mock Presentation & Q&A',
                    body: 'Teams present in mock rounds; feedback and scores are recorded.',
                    pill: const DocumentationStatusPill(label: '9', kind: DocStatusKind.inactive),
                  ),
                  (
                    title: 'Shortlist Top Teams',
                    body: 'Rankings and expert recommendations drive shortlisting.',
                    pill: const DocumentationStatusPill(label: '10', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'SIH Team Nomination',
                    body: 'Nominate top teams to represent the institution at SIH.',
                    pill: const DocumentationStatusPill(label: '11', kind: DocStatusKind.active),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _stageCard(
                context,
                name: '1. SIH Problem Statements',
                purpose: 'Make official SIH problem statements available on Hackz.',
                activities: const <String>[
                  'Upload official SIH problem statements',
                  'Classify and organize problems for discovery',
                  'Publish the internal SIH problem catalog',
                ],
                outcome: 'Students and faculty can browse the full SIH problem set on Hackz.',
                modules: const <String>['Problems', 'Domains', 'CSV Import'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '2. Student Registration & Profiles',
                purpose: 'Onboard participating students with complete profiles.',
                activities: const <String>[
                  'Student registration',
                  'Create profiles',
                  'Capture skills, interests and experience',
                ],
                outcome: 'A ready pool of student profiles for team formation.',
                modules: const <String>['Users', 'Students'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '3. Team Formation',
                purpose: 'Form balanced teams around skills and problem preferences.',
                activities: const <String>[
                  'Create or join teams',
                  'Align members by skills and interests',
                  'Select preferred problem statements',
                ],
                outcome: 'Teams ready to submit ideas against selected problems.',
                modules: const <String>['Teams', 'Users'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '4. Idea Submission',
                purpose: 'Collect team solutions against SIH problems.',
                activities: const <String>[
                  'Submit ideas and solution narratives',
                  'Attach supporting documents where required',
                  'Track submission status',
                ],
                outcome: 'A complete set of SIH idea submissions for screening.',
                modules: const <String>['Ideas', 'Problems', 'Teams'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '5. Internal Screening',
                purpose: 'Filter ideas for relevance and feasibility before deeper mentoring.',
                activities: const <String>[
                  'Faculty and mentor screening',
                  'Relevance and feasibility checks',
                  'Advance promising submissions',
                ],
                outcome: 'A screened shortlist of ideas ready for mentor guidance.',
                modules: const <String>['Ideas', 'Evaluations', 'Users'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '6. Mentor Review & Guidance',
                purpose: 'Improve solution quality through structured mentoring.',
                activities: const <String>[
                  'Assign mentors',
                  'Provide feedback and improvement guidance',
                  'Iterate on team solutions',
                ],
                outcome: 'Stronger, mentor-reviewed solutions advancing to prototype work.',
                modules: const <String>['Ideas', 'Users', 'Teams'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '7. Prototype Development Tracking',
                purpose: 'Monitor build progress toward demo-ready prototypes.',
                activities: const <String>[
                  'Track milestones and deliverables',
                  'Monitor prototype progress',
                  'Capture evidence of implementation',
                ],
                outcome: 'Visible prototype maturity across competing teams.',
                modules: const <String>['Ideas', 'Teams', 'Attachments'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '8. Evaluation & Scoring',
                purpose: 'Score teams fairly using multi-criteria rubrics.',
                activities: const <String>[
                  'Assign judges or expert evaluators',
                  'Apply pre-defined evaluation rubrics',
                  'Aggregate scores transparently',
                ],
                outcome: 'Comparable evaluation scores across SIH submissions.',
                modules: const <String>['Evaluations', 'Judges', 'Ideas'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '9. Mock Presentation & Q&A',
                purpose: 'Prepare teams for high-stakes presentation and defense.',
                activities: const <String>[
                  'Conduct mock presentation rounds',
                  'Record feedback and scores',
                  'Coach teams on Q&A readiness',
                ],
                outcome: 'Presentation-ready teams with recorded mock feedback.',
                modules: const <String>['Evaluations', 'Ideas', 'Teams'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '10. Shortlist Top Teams',
                purpose: 'Identify the strongest teams for institutional nomination.',
                activities: const <String>[
                  'Review rankings and analytics',
                  'Apply expert recommendations',
                  'Confirm shortlisted teams',
                ],
                outcome: 'A ranked shortlist of top SIH candidate teams.',
                modules: const <String>['Evaluations', 'Reports & Analytics', 'Ideas'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '11. SIH Team Nomination',
                purpose: 'Nominate institution representatives for Smart India Hackathon.',
                activities: const <String>[
                  'Select final nominee teams',
                  'Record nomination decisions',
                  'Prepare teams for external SIH participation',
                ],
                outcome: 'Institutional SIH nominees ready for the national stage.',
                modules: const <String>['Ideas', 'Teams', 'Reports & Analytics'],
              ),
            ],
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.howHackz,
          title: 'How Hackz Supports SIH',
          subtitle: 'Platform capabilities used throughout the internal SIH workflow.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.problems,
                    title: 'Problem Management',
                    body: 'Publish and organize official SIH problem statements for campus discovery.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.users,
                    title: 'Student & Team Management',
                    body: 'Register students, complete profiles and form balanced SIH teams.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Idea Submission',
                    body: 'Collect solutions against selected SIH problems with tracked status.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.judges,
                    title: 'Judge Assignment',
                    body: 'Assign evaluators for screening, scoring and mock presentation rounds.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.scoring,
                    title: 'Transparent Evaluation',
                    body: 'Use rubrics, multi-level scoring and visible aggregation for fairness.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.insights,
                    title: 'Evaluation Analytics',
                    body: 'Track participation, progress, scores and rankings on dashboards.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.milestone,
                    title: 'Prototype Tracking',
                    body: 'Monitor milestones, deliverables and prototype maturity over time.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.faculty,
                    title: 'Mentor Collaboration',
                    body: 'Connect teams with mentors for guidance, feedback and iteration.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.dashboard,
                    title: 'Reports & Dashboards',
                    body: 'Operational visibility for admins coordinating SIH selection.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.adminProfile,
                    title: 'Role-based Access',
                    body: 'Least-privilege workspaces for students, faculty, judges and admins.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.whyHackz,
          title: 'Why Hackz is the Right Choice',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 2 : 1;
              final List<({String title, String body, DocInfoTone tone})> items =
                  const <({String title, String body, DocInfoTone tone})>[
                (
                  title: 'Centralized Platform',
                  body:
                      'Manage registrations, ideas, teams, mentors, evaluations and documents in one place.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Transparent Evaluation',
                  body:
                      'Pre-defined rubrics, multi-level evaluation and automated scoring support fairness.',
                  tone: DocInfoTone.success,
                ),
                (
                  title: 'Real-time Analytics',
                  body:
                      'Track participation, progress, scores and rankings through powerful dashboards.',
                  tone: DocInfoTone.note,
                ),
                (
                  title: 'Mentor & Expert Collaboration',
                  body:
                      'Connect internal and external mentors for better guidance and stronger solutions.',
                  tone: DocInfoTone.warning,
                ),
                (
                  title: 'Document Management',
                  body:
                      'Secure storage for prototypes, reports, presentations and related artifacts.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Secure Cloud Platform',
                  body:
                      'Enterprise-grade security, data privacy and reliable cloud infrastructure.',
                  tone: DocInfoTone.important,
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: _cardWidth(cols, c.maxWidth),
                        child: DocumentationInfoCard(
                          title: item.title,
                          body: item.body,
                          tone: item.tone,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.benefits,
          title: 'Benefits to Institutions',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.leaderboard,
                    title: 'Better Team Selection',
                    body: 'Nominate stronger SIH teams using structured evidence and rankings.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.student,
                    title: 'Improved Student Participation',
                    body: 'Clear pathways from registration to nomination increase engagement.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.scoring,
                    title: 'Structured Evaluation',
                    body: 'Rubrics and multi-level scoring replace ad-hoc selection chats.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.clock,
                    title: 'Reduced Manual Work',
                    body: 'Centralized workflows reduce spreadsheet and email overhead.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.achievement,
                    title: 'Improved SIH Readiness',
                    body: 'Mock presentations and mentoring prepare teams for national competition.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Innovation Culture',
                    body: 'Campus-wide SIH cycles strengthen problem-solving culture.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.organizations,
                    title: 'Industry Collaboration',
                    body: 'Mentors and experts collaborate with students through shared workflows.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.outcomes,
          title: 'Expected Outcomes',
          subtitle: 'Results institutions typically achieve with a Hackz-led SIH selection.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 2 : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'High-quality shortlisted teams',
                      body:
                          'Top innovative teams ready to represent the institution at Smart India Hackathon.',
                      tone: DocInfoTone.success,
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'Transparent evaluations',
                      body: 'Comparable scores and auditable decisions across the selection cycle.',
                      tone: DocInfoTone.information,
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'Improved prototype quality',
                      body: 'Milestone tracking and mentoring raise prototype maturity before nomination.',
                      tone: DocInfoTone.note,
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'Better documentation',
                      body: 'Ideas, evaluations, presentations and artifacts remain organized on platform.',
                      tone: DocInfoTone.warning,
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'Institution-wide participation',
                      body: 'Broader student and faculty involvement across departments and domains.',
                      tone: DocInfoTone.information,
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: const DocumentationInfoCard(
                      title: 'Improved SIH success rate',
                      body:
                          'Stronger preparation, selection quality and readiness for national competition.',
                      tone: DocInfoTone.important,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.faq,
          title: 'Frequently Asked Questions',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'What is Smart India Hackathon?',
                body:
                    'Smart India Hackathon is a national innovation program where student teams solve official problem statements. Institutions typically run an internal selection process before nominating teams.',
              ),
              (
                title: 'How does Hackz help institutions?',
                body:
                    'Hackz provides an end-to-end internal workflow—from publishing SIH problems to idea submission, mentoring, evaluation, shortlisting and nomination—with transparent scoring and analytics.',
              ),
              (
                title: 'Can institutions customize the workflow?',
                body:
                    'Yes. Institutions can emphasize screening, mentoring, prototype tracking or mock presentations based on capacity while keeping the overall SIH selection journey intact.',
              ),
              (
                title: 'Can evaluation criteria be configured?',
                body:
                    'Yes. Evaluation rubrics and judge assignment can be configured so multi-criteria scoring matches institutional SIH selection standards.',
              ),
              (
                title: 'How are teams shortlisted?',
                body:
                    'Hackz supports rankings from evaluations and expert recommendations so administrators can shortlist top teams with transparent evidence.',
              ),
              (
                title: 'Who performs the final nomination?',
                body:
                    'Authorized institutional administrators nominate the final teams that will represent the college at Smart India Hackathon.',
              ),
              (
                title: 'Can Hackz be used beyond SIH?',
                body:
                    'Yes. Hackz also supports year-round innovation programs such as the Innovation to Startup Program, ideathons, hackathons and ongoing evaluation workflows.',
              ),
            ],
          ),
        ),
        _section(
          id: SmartIndiaHackathonSections.related,
          title: 'Related Help',
          subtitle: 'Continue with platform, institution solutions and lifecycle guides.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _relatedCard(context, overview, cols, c.maxWidth),
                  _relatedCard(context, innovationProgram, cols, c.maxWidth),
                  _relatedCard(context, problemLifecycle, cols, c.maxWidth),
                  _relatedCard(context, ideaLifecycle, cols, c.maxWidth),
                  _relatedCard(context, evaluation, cols, c.maxWidth),
                  _relatedCard(context, ideathon, cols, c.maxWidth),
                  _relatedCard(context, hackathon, cols, c.maxWidth),
                  _relatedCard(context, roles, cols, c.maxWidth),
                  _relatedCard(context, csv, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
