import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_image_viewer.dart';
import '../widgets/documentation_primitives.dart';
import '../widgets/documentation_timeline_table.dart';
import 'docs_asset_paths.dart';
import 'docs_registry.dart';

/// Section ids for Innovation to Startup Program TOC.
abstract final class InnovationToStartupSections {
  static const String whatIs = 'what-is';
  static const String infographic = 'infographic';
  static const String journey = 'complete-journey';
  static const String features = 'platform-features';
  static const String objectives = 'program-objectives';
  static const String outcomes = 'expected-outcomes';
  static const String participants = 'target-participants';
  static const String benefits = 'institutional-benefits';
  static const String whyHackz = 'why-hackz';
  static const String faq = 'faq';
  static const String related = 'related-help';

  static const List<DocSectionSpec> all = <DocSectionSpec>[
    DocSectionSpec(id: whatIs, title: 'What is the Innovation to Startup Program?'),
    DocSectionSpec(id: infographic, title: 'Innovation Ecosystem Infographic'),
    DocSectionSpec(id: journey, title: 'Complete Innovation Journey'),
    DocSectionSpec(id: features, title: 'Hackz Platform Features'),
    DocSectionSpec(id: objectives, title: 'Program Objectives'),
    DocSectionSpec(id: outcomes, title: 'Expected Outcomes'),
    DocSectionSpec(id: participants, title: 'Target Participants'),
    DocSectionSpec(id: benefits, title: 'Institutional Benefits'),
    DocSectionSpec(id: whyHackz, title: 'Why Hackz?'),
    DocSectionSpec(id: faq, title: 'Frequently Asked Questions'),
    DocSectionSpec(id: related, title: 'Related Help'),
  ];

  static List<String> get searchCorpus => const <String>[
        'innovation to startup program ideathon idea validation patent prototype',
        'journal product pitch investors startup incubation entrepreneurship',
        'ipr intellectual property research publication mvp incubator',
        'engineering colleges faculty students innovation cells rankings',
        'mentor network certificates investor connect year-round ecosystem',
      ];
}

/// Builds Innovation to Startup Program documentation body sections.
class InnovationToStartupDocBody extends StatelessWidget {
  const InnovationToStartupDocBody({
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
    required String output,
    required List<String> modules,
    String? note,
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
            'Expected output',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            output,
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
          if (note != null) ...<Widget>[
            const SizedBox(height: 12),
            DocumentationInfoCard(
              title: 'Important',
              body: note,
              tone: DocInfoTone.important,
            ),
          ],
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
    final DocPageDefinition problemLifecycle = DocsRegistry.byId('problem-lifecycle');
    final DocPageDefinition ideaLifecycle = DocsRegistry.byId('idea-lifecycle');
    final DocPageDefinition evaluation = DocsRegistry.byId('evaluation-lifecycle');
    final DocPageDefinition ideathon = DocsRegistry.byId('ideathon');
    final DocPageDefinition hackathon = DocsRegistry.byId('hackathon');
    final DocPageDefinition roles = DocsRegistry.byId('roles-responsibilities');
    final DocPageDefinition csv = DocsRegistry.byId('csv-import');
    final DocPageDefinition sih = DocsRegistry.byId('smart-india-hackathon');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: 'Innovation to Startup Program',
          subtitle: 'Innovate • Protect • Build • Launch',
          description:
              'Hackz provides institutions with an end-to-end innovation ecosystem that helps students and faculty transform innovative ideas into patents, research publications, industry-ready products and successful startups.',
          lastUpdated: DateTime(2026, 8, 6),
          readingMinutes: 8,
          imageAsset: DocsAssetPaths.innovationToStartupProgram,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        _section(
          id: InnovationToStartupSections.whatIs,
          title: 'What is the Innovation to Startup Program?',
          subtitle:
              'A year-round institutional program—not a single event—for building a complete campus innovation ecosystem on Hackz.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'The Innovation to Startup Program helps engineering colleges nurture creativity, research, intellectual property and entrepreneurship across the academic year.',
                style: TextStyle(fontSize: 14.5, height: 1.5, color: cs.onSurface),
              ),
              const SizedBox(height: 14),
              DocumentationCard(
                title: 'Program focus areas',
                child: _bulletList(context, const <String>[
                  'Building innovation culture',
                  'Encouraging problem solving',
                  'Promoting entrepreneurship',
                  'Supporting research',
                  'Creating intellectual property',
                  'Product development',
                  'Startup ecosystem',
                ]),
              ),
              const SizedBox(height: 12),
              const DocumentationInfoCard(
                title: 'One platform for the full journey',
                body:
                    'Hackz manages the complete innovation journey within a single platform—from ideathons and idea validation through patents, prototypes, publications, products, investor pitches and startup incubation.',
                tone: DocInfoTone.important,
              ),
            ],
          ),
        ),
        _section(
          id: InnovationToStartupSections.infographic,
          title: 'Innovation Ecosystem Infographic',
          subtitle: 'Tap the image to enlarge. Maintains aspect ratio on web and mobile.',
          child: DocumentationImageViewer(
            assetPath: DocsAssetPaths.innovationToStartupProgram,
            maxHeight: 420,
            semanticLabel: 'Innovation to Startup Program ecosystem infographic',
          ),
        ),
        _section(
          id: InnovationToStartupSections.journey,
          title: 'Complete Innovation Journey',
          subtitle:
              'Official stage order matches the ecosystem infographic. Patent may begin before prototype depending on idea maturity and novelty.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DocumentationTimeline(
                axis: DocTimelineAxis.vertical,
                items: <({String title, String body, Widget? pill})>[
                  (
                    title: 'Ideathon',
                    body: 'Generate innovative ideas through problem identification and collaboration.',
                    pill: const DocumentationStatusPill(label: '1', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Idea Validation',
                    body: 'Validate market fit, feasibility and competitive position.',
                    pill: const DocumentationStatusPill(label: '2', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Patent',
                    body: 'Protect intellectual property through search, drafting and filing support.',
                    pill: const DocumentationStatusPill(label: '3', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Prototype',
                    body: 'Engineer and validate hardware, software and integrated solutions.',
                    pill: const DocumentationStatusPill(label: '4', kind: DocStatusKind.inactive),
                  ),
                  (
                    title: 'Journal',
                    body: 'Translate research into papers, conferences and publications.',
                    pill: const DocumentationStatusPill(label: '5', kind: DocStatusKind.active),
                  ),
                  (
                    title: 'Product',
                    body: 'Build MVPs and prepare go-to-market execution.',
                    pill: const DocumentationStatusPill(label: '6', kind: DocStatusKind.custom),
                  ),
                  (
                    title: 'Pitch for Investors',
                    body: 'Prepare business models, decks and investor-ready storytelling.',
                    pill: const DocumentationStatusPill(label: '7', kind: DocStatusKind.draft),
                  ),
                  (
                    title: 'Startup / Incubation',
                    body: 'Register, incubate, fund and scale ventures.',
                    pill: const DocumentationStatusPill(label: '8', kind: DocStatusKind.active),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _stageCard(
                context,
                name: '1. Ideathon',
                purpose: 'Generate innovative ideas.',
                activities: const <String>[
                  'Problem identification',
                  'Brainstorming',
                  'Team formation',
                  'Idea presentation',
                ],
                output: 'Candidate innovation ideas ready for validation.',
                modules: const <String>['Ideathons', 'Problems', 'Ideas', 'Teams'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '2. Idea Validation',
                purpose: 'Confirm that an idea is worth advancing.',
                activities: const <String>[
                  'Market research',
                  'Feasibility analysis',
                  'Competitor analysis',
                  'SWOT analysis',
                ],
                output: 'Validated innovation idea.',
                modules: const <String>['Ideas', 'Teams', 'Domains'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '3. Patent',
                purpose: 'Protect novel intellectual property.',
                activities: const <String>[
                  'Patent awareness',
                  'Patent search',
                  'Prior-art analysis',
                  'Patent drafting',
                  'Filing support',
                ],
                output: 'Patentable IP package and filing readiness.',
                modules: const <String>['Ideas', 'Domains', 'Help & Documentation'],
                note:
                    'Patent filing may begin before prototype development depending on the maturity and novelty of the idea. Prototype is not a prerequisite for Patent.',
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '4. Prototype',
                purpose: 'Turn validated concepts into working implementations.',
                activities: const <String>[
                  'Engineering design',
                  'Rapid prototyping',
                  'Hardware/software implementation',
                  'Integration',
                  'Testing',
                ],
                output: 'Working prototype with validation evidence.',
                modules: const <String>['Ideas', 'Teams', 'Hackathons'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '5. Journal',
                purpose: 'Capture academic research and publication outcomes.',
                activities: const <String>[
                  'Literature review',
                  'Research guidance',
                  'Paper writing',
                  'Conference publication',
                ],
                output: 'Research papers and conference submissions.',
                modules: const <String>['Ideas', 'Domains', 'Users'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '6. Product',
                purpose: 'Evolve prototypes into market-ready products and MVPs.',
                activities: const <String>[
                  'MVP development',
                  'Product engineering',
                  'User testing',
                  'Quality assurance',
                  'Go-to-market planning',
                ],
                output: 'Product / MVP with go-to-market plan.',
                modules: const <String>['Ideas', 'Teams', 'Reports & Analytics'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '7. Pitch for Investors',
                purpose: 'Prepare teams to communicate value to investors.',
                activities: const <String>[
                  'Business model',
                  'Pitch deck',
                  'Storytelling',
                  'Investor readiness',
                ],
                output: 'Investor-ready pitch materials.',
                modules: const <String>['Ideas', 'Teams', 'Evaluations'],
              ),
              const SizedBox(height: 12),
              _stageCard(
                context,
                name: '8. Startup / Incubation',
                purpose: 'Launch and grow ventures with institutional support.',
                activities: const <String>[
                  'Startup registration',
                  'Incubation',
                  'Funding',
                  'Mentoring',
                  'Scaling',
                ],
                output: 'Incubated startups progressing toward scale.',
                modules: const <String>['Users', 'Organization Settings', 'Reports & Analytics'],
              ),
            ],
          ),
        ),
        _section(
          id: InnovationToStartupSections.features,
          title: 'Hackz Platform Features',
          subtitle: 'Capabilities that support the Innovation to Startup journey.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Digital Innovation Management',
                    body: 'Submit, track and manage ideas online across the academic year.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.faculty,
                    title: 'Mentor Network',
                    body: 'Connect teams with domain experts and industry mentors.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.verification,
                    title: 'Patent & IP Support',
                    body: 'Guide patent search, drafting and filing assistance workflows.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.milestone,
                    title: 'Prototype Tracking',
                    body: 'Monitor progress from concept to working prototype.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.docs,
                    title: 'Research Guidance',
                    body: 'Support literature review, paper writing and publication readiness.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.scoring,
                    title: 'Startup Readiness',
                    body: 'Assess market potential, viability and entrepreneurial maturity.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.organizations,
                    title: 'Investor Connect',
                    body: 'Prepare pathways to investors, incubators and grant opportunities.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.achievement,
                    title: 'Certificates & Recognition',
                    body: 'Recognize innovation milestones and team achievements.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: InnovationToStartupSections.objectives,
          title: 'Program Objectives',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 2 : 1;
              final List<({String title, String body, DocInfoTone tone})> items =
                  const <({String title, String body, DocInfoTone tone})>[
                (
                  title: 'Promote innovation culture',
                  body: 'Make design thinking and problem solving a sustained campus practice.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Generate patentable ideas',
                  body: 'Convert validated innovations into protectable intellectual property.',
                  tone: DocInfoTone.success,
                ),
                (
                  title: 'Build industry-ready products',
                  body: 'Advance prototypes into MVPs and products with real-world utility.',
                  tone: DocInfoTone.note,
                ),
                (
                  title: 'Encourage publications',
                  body: 'Strengthen research output through guided papers and conferences.',
                  tone: DocInfoTone.warning,
                ),
                (
                  title: 'Develop entrepreneurial mindset',
                  body: 'Equip students and faculty to build investor-ready business models.',
                  tone: DocInfoTone.information,
                ),
                (
                  title: 'Support startup ecosystem',
                  body: 'Enable registration, incubation, mentoring and funding pathways.',
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
          id: InnovationToStartupSections.outcomes,
          title: 'Expected Outcomes',
          subtitle: 'Outcome categories institutions typically track—without fixed targets.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Innovation Ideas',
                    body: 'Pipeline of student and faculty ideas advancing through validation.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.verification,
                    title: 'Patent Filings',
                    body: 'Intellectual property packages prepared and filed where novelty warrants.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.milestone,
                    title: 'Prototypes',
                    body: 'Working prototypes demonstrating technical and user validation.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.docs,
                    title: 'Research Publications',
                    body: 'Journal and conference outputs linked to campus innovations.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.insights,
                    title: 'Products / MVPs',
                    body: 'Market-oriented products matured beyond early prototypes.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.leaderboard,
                    title: 'Investor Pitches',
                    body: 'Teams prepared to present business models to investors and incubators.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.achievement,
                    title: 'Startups',
                    body: 'Ventures progressing into incubation, funding and scale.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: InnovationToStartupSections.participants,
          title: 'Target Participants',
          subtitle: 'Who the program is designed for.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 900 ? 2 : 1;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Engineering Students',
                      child: Text(
                        'Students across branches who form teams, solve problems and build innovations.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Faculty',
                      child: Text(
                        'Mentors and research guides who support ideation, IP and publication pathways.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Innovation Cells',
                      child: Text(
                        'Campus innovation units coordinating programs, events and mentoring.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Research Centers',
                      child: Text(
                        'Centers advancing scholarly output and applied research from campus ideas.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Incubation Centers',
                      child: Text(
                        'Incubators supporting registration, mentoring, funding and growth.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _cardWidth(cols, c.maxWidth),
                    child: DocumentationCard(
                      title: 'Entrepreneurship Cells',
                      child: Text(
                        'Entrepreneurship cells building investor readiness and venture culture.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: InnovationToStartupSections.benefits,
          title: 'Institutional Benefits',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.ideas,
                    title: 'Innovation culture',
                    body: 'Sustained ideation and problem-solving across departments.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.leaderboard,
                    title: 'Improved rankings',
                    body: 'Stronger evidence for frameworks such as NAAC, NBA, NIRF, ARIIA, IIC and NISP.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.organizations,
                    title: 'Industry collaboration',
                    body: 'Closer links with mentors, industry experts and partners.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.docs,
                    title: 'Research ecosystem',
                    body: 'More structured pathways from projects to publications.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.achievement,
                    title: 'Startup ecosystem',
                    body: 'A clearer pipeline from campus ideas to incubated ventures.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.student,
                    title: 'Student employability',
                    body: 'Hands-on innovation experience that strengthens career readiness.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.faculty,
                    title: 'Entrepreneurship',
                    body: 'Faculty and students develop investor-ready entrepreneurial skills.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.insights,
                    title: 'Innovation visibility',
                    body: 'Institutional visibility for patents, prototypes, products and startups.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: InnovationToStartupSections.whyHackz,
          title: 'Why Hackz?',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _featureCard(
                    context,
                    icon: AppIcons.timelineWorkspace,
                    title: 'End-to-End Innovation Platform',
                    body: 'One system spanning ideation through incubation.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.website,
                    title: 'Technology Enabled',
                    body: 'Digital workflows that are easy to operate year-round.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.faculty,
                    title: 'Expert Mentoring',
                    body: 'Role-based mentoring and guidance across stages.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.verification,
                    title: 'Patent Support',
                    body: 'Structured IP awareness, search and filing readiness.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.achievement,
                    title: 'Startup Focused',
                    body: 'Designed to convert campus innovation into ventures.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.organizations,
                    title: 'Scalable Architecture',
                    body: 'Multi-tenant platform ready for growing programs.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.users,
                    title: 'Role-based Workflows',
                    body: 'Clear ownership for admins, faculty, judges and students.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                  _featureCard(
                    context,
                    icon: AppIcons.dashboard,
                    title: 'Modern Dashboards',
                    body: 'Operational visibility across the innovation pipeline.',
                    cols: cols,
                    maxWidth: c.maxWidth,
                  ),
                ],
              );
            },
          ),
        ),
        _section(
          id: InnovationToStartupSections.faq,
          title: 'Frequently Asked Questions',
          child: const DocumentationAccordion(
            items: <({String title, String body})>[
              (
                title: 'What is the Innovation to Startup Program?',
                body:
                    'It is a year-round institutional program on Hackz that helps colleges take ideas from ideathons through validation, patents, prototypes, publications, products, investor pitches and startup incubation.',
              ),
              (
                title: 'Can institutions customize the stages?',
                body:
                    'Institutions can emphasize stages based on maturity and capacity, while the official ecosystem flow remains Ideathon → Idea Validation → Patent → Prototype → Journal → Product → Pitch → Startup / Incubation.',
              ),
              (
                title: 'Can patents be filed before prototypes?',
                body:
                    'Yes. Patent filing may begin before prototype development depending on the maturity and novelty of the idea. Prototype is not a prerequisite for Patent.',
              ),
              (
                title: 'Can Hackz support research publications?',
                body:
                    'Yes. The Journal stage covers literature review, research guidance, paper writing and conference or journal publication pathways.',
              ),
              (
                title: 'Can Hackz manage multiple innovation programs?',
                body:
                    'Yes. Hackz is multi-tenant and role-based, so institutions can run concurrent innovation programs across departments within one platform.',
              ),
              (
                title: 'Can Hackz support startup incubation?',
                body:
                    'Yes. The Startup / Incubation stage covers registration, mentoring, funding connect and scaling with institutional support.',
              ),
              (
                title: 'Can Hackz be used outside engineering colleges?',
                body:
                    'Yes. While designed for engineering colleges, Hackz can support other institutions and organizations running structured innovation-to-startup programs.',
              ),
            ],
          ),
        ),
        _section(
          id: InnovationToStartupSections.related,
          title: 'Related Help',
          subtitle: 'Continue with platform, workflow and upcoming event-specific guides.',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int cols = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _relatedCard(context, overview, cols, c.maxWidth),
                  _relatedCard(context, problemLifecycle, cols, c.maxWidth),
                  _relatedCard(context, ideaLifecycle, cols, c.maxWidth),
                  _relatedCard(context, evaluation, cols, c.maxWidth),
                  _relatedCard(context, ideathon, cols, c.maxWidth),
                  _relatedCard(context, hackathon, cols, c.maxWidth),
                  _relatedCard(context, roles, cols, c.maxWidth),
                  _relatedCard(context, csv, cols, c.maxWidth),
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
