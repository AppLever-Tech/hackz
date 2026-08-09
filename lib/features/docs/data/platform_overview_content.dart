import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import 'docs_registry.dart';

/// Section ids for Hackz Platform Overview TOC.
abstract final class PlatformOverviewSections {
  static const String whatIs = 'what-is-hackz';
  static const String whoUses = 'who-uses-hackz';
  static const String problems = 'problems-solved';
  static const String modules = 'platform-modules';
  static const String journey = 'innovation-journey';
  static const String workflows = 'supported-workflows';
  static const String highlights = 'platform-highlights';
  static const String principles = 'core-principles';
  static const String gettingStarted = 'getting-started';
  static const String faq = 'faq';
  static const String related = 'related-help';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: whatIs, title: 'What is Hackz?'),
    DocSectionSpec(id: whoUses, title: 'Who Uses Hackz?'),
    DocSectionSpec(id: problems, title: 'What Problems Does Hackz Solve?'),
    DocSectionSpec(id: modules, title: 'Platform Modules'),
    DocSectionSpec(id: journey, title: 'Innovation Journey'),
    DocSectionSpec(id: workflows, title: 'Supported Workflows'),
    DocSectionSpec(id: highlights, title: 'Platform Highlights'),
    DocSectionSpec(id: principles, title: 'Core Principles'),
    DocSectionSpec(id: gettingStarted, title: 'Getting Started'),
    DocSectionSpec(id: faq, title: 'Frequently Asked Questions'),
    DocSectionSpec(id: related, title: 'Related Help'),
  ];

  static List<String> get searchCorpus => const <String>[
        'hackz platform overview innovation lifecycle ideathon hackathon',
        'college admin department admin faculty coordinator judge student',
        'problem statements ideas evaluations teams domains csv import',
        'ideathon prototype transparent evaluation multi-tenant',
        'organization settings reports analytics feedback app metadata',
        'role-based access responsive dashboards getting started onboarding',
      ];
}

/// Builds Hackz Platform Overview documentation body sections.
class PlatformOverviewDocBody extends StatelessWidget {
  const PlatformOverviewDocBody({
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

  Widget _roleCard(
    BuildContext context,
    String title,
    DocStatusKind kind,
    List<String> bullets,
    int cols,
    double maxWidth,
  ) {
    return SizedBox(
      width: _cardWidth(cols, maxWidth),
      child: DocumentationCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DocumentationStatusPill(label: title, kind: kind),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            _bulletList(context, bullets),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(
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

  Widget _highlightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required int cols,
    required double maxWidth,
  }) {
    return _moduleCard(
      context,
      icon: icon,
      title: title,
      body: body,
      cols: cols,
      maxWidth: maxWidth,
    );
  }

  Widget _workflowCard(
    BuildContext context, {
    required DocPageDefinition page,
    required String summary,
    required int cols,
    required double maxWidth,
  }) {
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
                summary,
                style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Text(
                    'Open Help',
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

  Widget _readingGroup(
    BuildContext context, {
    required String role,
    required List<String> pageIds,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<DocPageDefinition> pages = pageIds
        .map(DocsRegistry.byId)
        .where((DocPageDefinition p) => p.id != DocsRegistry.helpHomeId)
        .toList(growable: false);

    return DocumentationCard(
      title: role,
      child: Column(
        children: pages
            .map(
              (DocPageDefinition page) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(page.icon, size: 20, color: cs.primary),
                title: Text(page.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  page.isPlaceholder ? 'Coming soon — ${page.description}' : page.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpenPage(page.id),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DocPageDefinition problemLifecycle = DocsRegistry.byId('problem-lifecycle');
    final DocPageDefinition ideaLifecycle = DocsRegistry.byId('idea-lifecycle');
    final DocPageDefinition evaluation = DocsRegistry.byId('evaluation-lifecycle');
    final DocPageDefinition ideathon = DocsRegistry.byId('ideathon');
    final DocPageDefinition hackathon = DocsRegistry.byId('hackathon');
    final DocPageDefinition roles = DocsRegistry.byId('roles-responsibilities');
    final DocPageDefinition csv = DocsRegistry.byId('csv-import');
    final DocPageDefinition innovationProgram = DocsRegistry.byId('innovation-to-startup');
    final DocPageDefinition sih = DocsRegistry.byId('smart-india-hackathon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'Hackz Platform Overview',
          subtitle: 'Innovation • Collaboration • Evaluation • Growth',
          description:
              'Hackz is a modern innovation management platform that helps engineering colleges and organizations manage ideathons, hackathons, innovation programs and startup initiatives through structured workflows, transparent evaluations and role-based collaboration.',
          lastUpdated: DateTime(2026, 8, 6),
          readingMinutes: 7,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: PlatformOverviewSections.whatIs,
          title: 'What is Hackz?',
          subtitle:
              'An end-to-end innovation management platform for educational institutions and organizations.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Hackz enables institutions to run the full innovation lifecycle—not only events—through structured, role-based collaboration.',
                style: TextStyle(fontSize: 14.5, height: 1.5, color: cs.onSurface),
              ),
              const SizedBox(height: 14),
              DocumentationCard(
                title: 'Institutions use Hackz to',
                child: _bulletList(context, const <String>[
                  'Manage innovation programs',
                  'Conduct ideathons',
                  'Conduct hackathons',
                  'Manage problem statements',
                  'Collect ideas',
                  'Evaluate innovations',
                  'Assign ideas to Ideathons',
                  'Organize events',
                  'Select prototypes',
                  'Track innovation progress',
                ]),
              ),
              const SizedBox(height: 12),
              const DocumentationInfoCard(
                title: 'More than event management',
                body:
                    'Hackz is not just an event management system—it is an innovation lifecycle platform spanning problem catalogs, idea workflows, evaluations, ideathons, prototypes and hackathons.',
                tone: DocInfoTone.important,
              ),
            ],
          ),
        ),
        _section(
          id: PlatformOverviewSections.whoUses,
          title: 'Who Uses Hackz?',
          subtitle: 'Role-based participation across the institution.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _roleCard(
                    context,
                    'College Admin',
                    DocStatusKind.active,
                    const <String>[
                      'Organization management',
                      'Platform administration',
                      'Problem approval',
                      'Organization configuration',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Department Admin',
                    DocStatusKind.custom,
                    const <String>[
                      'Department operations',
                      'Problem management',
                      'Judge assignments',
                      'Evaluation',
                      'Ideathon assignment',
                      'Event management',
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Faculty',
                    DocStatusKind.draft,
                    const <String>[
                      'Mentor teams',
                      'Submit innovations',
                      'Guide students',
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
                    ],
                    cols,
                    c.maxWidth,
                  ),
                  _roleCard(
                    context,
                    'Judge',
                    DocStatusKind.active,
                    const <String>[
                      'Evaluate ideas',
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
                      'Participate in innovation',
                      'Build teams',
                      'Develop solutions',
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
          id: PlatformOverviewSections.problems,
          title: 'What Problems Does Hackz Solve?',
          subtitle: 'Common institutional pain points—and how Hackz responds.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationCard(
                title: 'Institutional pain points',
                child: _bulletList(context, const <String>[
                  'Manual spreadsheet management',
                  'Email-based evaluations',
                  'Lost submissions',
                  'No evaluation transparency',
                  'Difficult Ideathon selection',
                  'Lack of analytics',
                  'No structured innovation workflow',
                  'Poor collaboration',
                ]),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final int cols = c.maxWidth > 900 ? 2 : 1;
                  final List<({String title, String body})> fixes =
                      const <({String title, String body})>[
                    (
                      title: 'Structured catalogs & submissions',
                      body:
                          'Problem statements and ideas live in governed workflows—no lost spreadsheets or scattered email threads.',
                    ),
                    (
                      title: 'Transparent evaluations',
                      body:
                          'Judge assignments, scoring and aggregation are visible and auditable, reducing bias and confusion.',
                    ),
                    (
                      title: 'Ideathon assignment',
                      body:
                          'Department admins assign Submitted ideas to Ideathons with clear eligibility and readiness controls.',
                    ),
                    (
                      title: 'Analytics & collaboration',
                      body:
                          'Dashboards, role-based workspaces and shared context keep faculty, students and admins aligned.',
                    ),
                  ];
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: fixes
                        .map(
                          (item) => SizedBox(
                            width: _cardWidth(cols, c.maxWidth),
                            child: DocumentationInfoCard(
                              title: item.title,
                              body: item.body,
                              tone: DocInfoTone.success,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
        _section(
          id: PlatformOverviewSections.modules,
          title: 'Platform Modules',
          subtitle: 'Core capabilities available across Hackz.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _moduleCard(
                    context,
                    icon: AppIcons.problems,
                    title: 'Problems',
                    body: 'Author, import, activate and manage problem statement catalogs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Idea Management',
                    body: 'Submit, track and progress innovations through the idea lifecycle.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.scoring,
                    title: 'Evaluations',
                    body: 'Assign judges, score ideas and aggregate evaluation results.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.teams,
                    title: 'Teams',
                    body: 'Form and manage student teams participating in innovation programs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.domains,
                    title: 'Domains',
                    body: 'Classify problems under department → domain hierarchies.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.users,
                    title: 'Users',
                    body: 'Invite, import and manage role-based access across the organization.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.submissions,
                    title: 'CSV Import',
                    body: 'Bulk import users and problems with validation and templates.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.ideathons,
                    title: 'Ideathons',
                    body: 'Assign Submitted ideas to Ideathons, then run evaluation and prototypes.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.insights,
                    title: 'Hackathons',
                    body: 'Operate hackathon programs as the innovation journey advances.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.orgSettings,
                    title: 'Organization Settings',
                    body: 'Configure evaluation rules, team policies and org preferences.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.leaderboard,
                    title: 'Reports & Analytics',
                    body: 'Track progress, evaluation outcomes and program health.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.docs,
                    title: 'Help & Documentation',
                    body: 'Role-aware Help with workflows, reference guides and FAQs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.feedback,
                    title: 'Feedback',
                    body: 'Capture issues and enhancements with screenshots and triage.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _moduleCard(
                    context,
                    icon: AppIcons.info,
                    title: 'App Metadata',
                    body: 'Platform about, terms, privacy and version information.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: PlatformOverviewSections.journey,
          title: 'Innovation Journey',
          subtitle:
              'High-level path from problems to innovation success. Each stage has a dedicated Help page.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTimeline(
                axis: DocTimelineAxis.vertical,
                items: <({String title, String body, Widget? pill})>[
                  (
                    title: 'Problem Statements',
                    body: 'Publish and govern the innovation catalog.',
                    pill: const DocumentationStatusPill(label: 'Problems', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Ideas',
                    body: 'Teams submit innovations against Active problems.',
                    pill: const DocumentationStatusPill(label: 'Ideas', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Evaluation',
                    body: 'Judges score assigned ideas with transparent aggregation.',
                    pill: const DocumentationStatusPill(label: 'Evaluate'),
                  ),
                  (
                    title: 'Ideathon Assigned',
                    body: 'Department admins assign Submitted ideas into Ideathon events.',
                    pill: const DocumentationStatusPill(label: 'Ideathon', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Ideathon',
                    body: 'Teams deepen concepts in structured ideathon rounds.',
                    pill: const DocumentationStatusPill(label: 'Ideathon', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Prototype',
                    body: 'Select promising prototypes after ideathon evaluation.',
                    pill: const DocumentationStatusPill(
                      label: 'Prototype',
                      kind: DocStatusKind.custom,
                    ),
                  ),
                  (
                    title: 'Hackathon',
                    body: 'Build and compete in hackathon programs.',
                    pill: const DocumentationStatusPill(label: 'Hackathon', kind: DocStatusKind.inactive),
                  ),
                  (
                    title: 'Innovation Success',
                    body: 'Recognize winners and track outcomes across the program.',
                    pill: const DocumentationStatusPill(label: 'Success', kind: DocStatusKind.active),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const DocumentationInfoCard(
                title: 'Deep-dive Help pages',
                body:
                    'Use Problem Lifecycle, Idea Lifecycle, Evaluation Workflow, Ideathon and Hackathon guides for stage-level detail—this overview stays intentionally high level.',
                tone: DocInfoTone.note,
              ),
            ],
          ),
        ),
        _section(
          id: PlatformOverviewSections.workflows,
          title: 'Supported Workflows',
          subtitle: 'Open a dedicated Help guide for each workflow.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _workflowCard(
                    context,
                    page: problemLifecycle,
                    summary:
                        'How problem statements move from draft and import through activation, deactivation and catalog governance.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _workflowCard(
                    context,
                    page: ideaLifecycle,
                    summary:
                        'How ideas progress from submission through Ideathon assignment, Ideathon evaluation and winners.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _workflowCard(
                    context,
                    page: evaluation,
                    summary:
                        'Judge assignment, scoring, aggregation and results.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _workflowCard(
                    context,
                    page: ideathon,
                    summary: 'Ideathon assignment, evaluation and prototype selection.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _workflowCard(
                    context,
                    page: hackathon,
                    summary: 'Hackathon operating model for later-stage innovation programs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: PlatformOverviewSections.highlights,
          title: 'Platform Highlights',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _highlightCard(
                    context,
                    icon: AppIcons.users,
                    title: 'Role-Based Access',
                    body: 'Least-privilege workspaces for every institutional role.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.scoring,
                    title: 'Transparent Evaluations',
                    body: 'Assignable judging with visible scores and aggregation.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.submissions,
                    title: 'CSV Imports',
                    body: 'Validated bulk onboarding for users and problem catalogs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.phone,
                    title: 'Responsive Web & Mobile',
                    body: 'Dashboards and Help that adapt from desktop to phone.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.dashboard,
                    title: 'Modern Dashboards',
                    body: 'Role-aware metrics, alerts and operational shortcuts.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.organizations,
                    title: 'Multi-tenant Architecture',
                    body: 'Organization isolation with shared platform capabilities.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.domains,
                    title: 'Domain-based Problem Catalog',
                    body: 'Department → domain classification for discoverability.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.insights,
                    title: 'Evaluation Analytics',
                    body: 'Track scoring progress, thresholds and outcomes.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.ideathons,
                    title: 'Ideathon Management',
                    body: 'Structured rounds after Ideathon assignment.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.statusWinner,
                    title: 'Hackathon Support',
                    body: 'Extend the journey into build-and-compete programs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.timelineWorkspace,
                    title: 'Reusable Components',
                    body: 'Consistent chrome, workspaces and documentation patterns.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _highlightCard(
                    context,
                    icon: AppIcons.website,
                    title: 'Cloud Native Architecture',
                    body: 'Firebase-backed services for scale and reliability.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: PlatformOverviewSections.principles,
          title: 'Core Principles',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 2 : 1;
              final List<({String title, String body, DocInfoTone tone})> items =
                  const <({String title, String body, DocInfoTone tone})>[
                (
                  title: 'Role-based ownership',
                  body: 'Clear owners for catalog, evaluation, payments and events.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Transparent evaluation',
                  body: 'Scores and assignments remain visible to authorized roles.',
                  tone: DocInfoTone.success,
                ),
                (
                  title: 'Reusable workflows',
                  body: 'The same lifecycle patterns support ideathons and hackathons.',
                  tone: DocInfoTone.note,
                ),
                (
                  title: 'Department isolation',
                  body: 'Operations stay scoped to the right department boundaries.',
                  tone: DocInfoTone.warning,
                ),
                (
                  title: 'Configurable organization settings',
                  body: 'Institutions tune evaluation and team rules without code changes.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Scalable architecture',
                  body: 'Multi-tenant design grows with new programs and campuses.',
                  tone: DocInfoTone.success,
                ),
                (
                  title: 'Responsive design',
                  body: 'First-class experiences on desktop, tablet and mobile.',
                  tone: DocInfoTone.note,
                ),
                (
                  title: 'Audit-friendly workflows',
                  body: 'Status history and role actions support institutional oversight.',
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
          id: PlatformOverviewSections.gettingStarted,
          title: 'Getting Started',
          subtitle: 'Recommended reading by role—shortcuts into existing Help pages.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _readingGroup(
                context,
                role: 'For Students',
                pageIds: const <String>['idea-lifecycle', 'roles-responsibilities'],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'Faculty',
                pageIds: const <String>['problem-lifecycle', 'idea-lifecycle'],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'Judge',
                pageIds: const <String>['evaluation-lifecycle', 'roles-responsibilities'],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'Coordinator',
                pageIds: const <String>['evaluation-lifecycle'],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'Department Admin',
                pageIds: const <String>[
                  'problem-lifecycle',
                  'evaluation-lifecycle',
                  'csv-import',
                ],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'College Admin',
                pageIds: const <String>[
                  'org-settings',
                  'problem-lifecycle',
                  'csv-import',
                ],
              ),
              const SizedBox(height: 12),
              _readingGroup(
                context,
                role: 'System Admin',
                pageIds: const <String>[
                  'org-settings',
                  'user-management',
                  'domain-management',
                ],
              ),
            ],
          ),
        ),
        _section(
          id: PlatformOverviewSections.faq,
          title: 'Frequently Asked Questions',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'What is Hackz?',
                body:
                    'Hackz is an end-to-end innovation management platform for institutions. It covers problem catalogs, idea submission, evaluation, ideathons, prototypes and hackathons.',
              ),
              (
                title: 'Who can use Hackz?',
                body:
                    'College Admin, Department Admin, Faculty, Coordinator, Judge and Student roles—each with role-based workspaces and permissions.',
              ),
              (
                title: 'Can Hackz be used outside engineering colleges?',
                body:
                    'Yes. Hackz is designed for educational institutions and organizations running structured innovation programs, not only engineering colleges.',
              ),
              (
                title: 'Can Hackz conduct Ideathons?',
                body:
                    'Yes. Ideas go Submitted → Ideathon Assigned. Institutions can then run ideathon workflows including evaluation and prototype selection.',
              ),
              (
                title: 'Can Hackz conduct Hackathons?',
                body:
                    'Yes. Hackathon support extends the innovation journey beyond ideathons into build-and-compete programs.',
              ),
              (
                title: 'How are ideas evaluated?',
                body:
                    'Department admins assign judges; judges score assigned ideas; the platform aggregates scores and advances ideas when evaluation thresholds are met.',
              ),
              (
                title: 'How do ideas enter an Ideathon?',
                body:
                    'Ideas go Submitted → Ideathon Assigned. Authorized department administrators assign eligible Submitted ideas to Ideathon events.',
              ),
              (
                title: 'Can Hackz manage multiple departments?',
                body:
                    'Yes. Problems, domains, judges and operations are scoped by department with organization-level governance for College Admins.',
              ),
              (
                title: 'Does Hackz support role-based access?',
                body:
                    'Yes. Access, menus and Help recommendations are role-aware so each user sees the responsibilities that apply to them.',
              ),
              (
                title: 'Does Hackz work on mobile devices?',
                body:
                    'Yes. Dashboards, workspaces and Help are responsive across desktop, laptop, tablet and mobile.',
              ),
              (
                title: 'Can organizations customize workflows?',
                body:
                    'Organization settings let institutions configure evaluation rules, team policies and related preferences without changing application code.',
              ),
            ],
          ),
        ),
        _section(
          id: PlatformOverviewSections.related,
          title: 'Related Help',
          subtitle: 'Continue with workflow guides and upcoming institution solutions.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _relatedCard(context, problemLifecycle, cols, c.maxWidth),
                  _relatedCard(context, ideaLifecycle, cols, c.maxWidth),
                  _relatedCard(context, evaluation, cols, c.maxWidth),
                  _relatedCard(context, roles, cols, c.maxWidth),
                  _relatedCard(context, csv, cols, c.maxWidth),
                  _relatedCard(context, innovationProgram, cols, c.maxWidth),
                  _relatedCard(context, sih, cols, c.maxWidth),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
