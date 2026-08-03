import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../user/models/enums/user_role.dart';
import '../data/idea_lifecycle_content.dart';
import '../data/problem_lifecycle_content.dart';
import '../data/roles_responsibilities_content.dart';
import '../models/doc_models.dart';
import '../screens/pages/placeholder_doc_page.dart';
import 'docs_asset_paths.dart';

/// Central registry — add future Help pages here only; layout stays unchanged.
abstract final class DocsRegistry {
  DocsRegistry._();

  static const String helpHomeId = 'help-home';

  static final DocPageDefinition helpHomePage = DocPageDefinition(
    id: helpHomeId,
    title: 'Help Home',
    description: 'Learn how Hackz works and understand your responsibilities.',
    icon: AppIcons.docs,
    builder: (_) => const SizedBox.shrink(),
    category: DocCategory.gettingStarted,
  );

  static final List<DocPageDefinition> pages = <DocPageDefinition>[
    DocPageDefinition(
      id: 'getting-started',
      title: 'Getting Started',
      description: 'Orientation for new Hackz users.',
      icon: AppIcons.info,
      isPlaceholder: true,
      category: DocCategory.gettingStarted,
      builder: (_) => const PlaceholderDocPage(
        title: 'Getting Started',
        description: 'A short orientation guide for new Hackz users will land here.',
      ),
    ),
    DocPageDefinition(
      id: 'problem-lifecycle',
      title: 'Problem Lifecycle',
      description: 'Catalog stages for Hackz problem statements.',
      icon: AppIcons.problems,
      lastUpdated: DateTime(2026, 7, 30),
      readingMinutes: 8,
      heroImageAsset: DocsAssetPaths.problemLifecycle,
      searchKeywords: ProblemLifecycleSections.searchCorpus,
      category: DocCategory.workflows,
      builder: (_) => const SizedBox.shrink(),
    ),
    DocPageDefinition(
      id: 'idea-lifecycle',
      title: 'Idea Lifecycle',
      description:
          'Complete lifecycle of an innovation idea from submission through evaluation, shortlisting, ideathon, prototype selection and winner declaration.',
      icon: AppIcons.ideas,
      lastUpdated: DateTime(2026, 7, 30),
      readingMinutes: 6,
      heroImageAsset: DocsAssetPaths.ideaLifecycle,
      searchKeywords: IdeaLifecycleSections.searchCorpus,
      category: DocCategory.workflows,
      builder: (_) => const SizedBox.shrink(),
    ),
    DocPageDefinition(
      id: 'evaluation-lifecycle',
      title: 'Evaluation Workflow',
      description: 'Assignments, scoring, shortlisting, and evaluation results.',
      icon: AppIcons.scoring,
      isPlaceholder: true,
      category: DocCategory.workflows,
      builder: (_) => const PlaceholderDocPage(
        title: 'Evaluation Workflow',
        description: 'Judge assignment, aggregation, ready-for-shortlisting, and results.',
      ),
    ),
    DocPageDefinition(
      id: 'ideathon',
      title: 'Ideathon',
      description: 'Post-shortlist ideathon workflows.',
      icon: AppIcons.ideathons,
      isPlaceholder: true,
      category: DocCategory.workflows,
      builder: (_) => const PlaceholderDocPage(
        title: 'Ideathon',
        description: 'Ideathon assignment, evaluation, and prototype selection.',
      ),
    ),
    DocPageDefinition(
      id: 'hackathon',
      title: 'Hackathon',
      description: 'Hackathon operating model (planned).',
      icon: AppIcons.insights,
      isPlaceholder: true,
      category: DocCategory.workflows,
      builder: (_) => const PlaceholderDocPage(
        title: 'Hackathon',
        description: 'Future Hackathon documentation will land here.',
      ),
    ),
    DocPageDefinition(
      id: 'innovation-submission',
      title: 'Innovation Submission',
      description: 'How faculty submit innovations against Active problems.',
      icon: AppIcons.ideas,
      isPlaceholder: true,
      category: DocCategory.workflows,
      builder: (_) => const PlaceholderDocPage(
        title: 'Innovation Submission',
        description: 'Faculty innovation submission workspace guide (coming soon).',
      ),
    ),
    DocPageDefinition(
      id: 'payment-verification',
      title: 'Payment Verification',
      description: 'Coordinator payment verification for submitted ideas.',
      icon: AppIcons.payments,
      isPlaceholder: true,
      category: DocCategory.workflows,
      builder: (_) => const PlaceholderDocPage(
        title: 'Payment Verification',
        description: 'Payment verification and operational readiness (coming soon).',
      ),
    ),
    DocPageDefinition(
      id: 'roles-responsibilities',
      title: 'Roles & Responsibilities',
      description:
          'Understand the responsibilities, permissions and ownership of every Hackz user role across the complete innovation lifecycle.',
      icon: AppIcons.users,
      lastUpdated: DateTime(2026, 7, 30),
      readingMinutes: 5,
      heroImageAsset: DocsAssetPaths.rolesResponsibilities,
      searchKeywords: RolesResponsibilitiesSections.searchCorpus,
      category: DocCategory.reference,
      builder: (_) => const SizedBox.shrink(),
    ),
    DocPageDefinition(
      id: 'csv-import',
      title: 'CSV Import',
      description: 'Users and problems import pipelines.',
      icon: AppIcons.submissions,
      isPlaceholder: true,
      category: DocCategory.reference,
      builder: (_) => const PlaceholderDocPage(
        title: 'CSV Import',
        description: 'Templates, validation, department codes, and domain codes.',
      ),
    ),
    DocPageDefinition(
      id: 'faq',
      title: 'FAQ',
      description: 'Frequently asked questions about Hackz.',
      icon: AppIcons.info,
      isPlaceholder: true,
      category: DocCategory.reference,
      builder: (_) => const PlaceholderDocPage(
        title: 'FAQ',
        description: 'Cross-cutting frequently asked questions will land here.',
      ),
    ),
    DocPageDefinition(
      id: 'org-settings',
      title: 'Organization Settings',
      description: 'Org configuration and evaluation settings.',
      icon: AppIcons.orgSettings,
      isPlaceholder: true,
      category: DocCategory.administration,
      adminOnly: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'Organization Settings',
        description: 'Evaluation configuration, team rules, and session cache lifecycle.',
      ),
    ),
    DocPageDefinition(
      id: 'domain-management',
      title: 'Domain Management',
      description: 'Department → Domain hierarchy for problem classification.',
      icon: AppIcons.domains,
      isPlaceholder: true,
      category: DocCategory.administration,
      adminOnly: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'Domain Management',
        description: 'Create and manage domains under departments (coming soon).',
      ),
    ),
    DocPageDefinition(
      id: 'user-management',
      title: 'User Management',
      description: 'Manage organization and department users.',
      icon: AppIcons.users,
      isPlaceholder: true,
      category: DocCategory.administration,
      adminOnly: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'User Management',
        description: 'Invite, import, and manage users (coming soon).',
      ),
    ),
  ];

  /// Recommended page ids per role (shortcuts into [pages], no duplicates).
  static List<String> recommendedIdsFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => const <String>[
          'problem-lifecycle',
          'idea-lifecycle',
          'roles-responsibilities',
          'csv-import',
          'org-settings',
        ],
      UserRole.collegeAdmin => const <String>[
          'problem-lifecycle',
          'idea-lifecycle',
          'roles-responsibilities',
          'csv-import',
          'org-settings',
        ],
      UserRole.departmentAdmin => const <String>[
          'problem-lifecycle',
          'idea-lifecycle',
          'roles-responsibilities',
          'csv-import',
          'evaluation-lifecycle',
          'ideathon',
        ],
      UserRole.faculty => const <String>[
          'idea-lifecycle',
          'problem-lifecycle',
          'roles-responsibilities',
          'innovation-submission',
          'evaluation-lifecycle',
        ],
      UserRole.judge => const <String>[
          'evaluation-lifecycle',
          'idea-lifecycle',
          'roles-responsibilities',
          'ideathon',
        ],
      UserRole.coordinator => const <String>[
          'idea-lifecycle',
          'payment-verification',
          'roles-responsibilities',
          'ideathon',
        ],
      UserRole.student => const <String>[
          'problem-lifecycle',
          'idea-lifecycle',
          'roles-responsibilities',
          'ideathon',
        ],
    };
  }

  static List<DocPageDefinition> visiblePagesFor(UserRole? role) {
    if (role == null) {
      return pages.where((DocPageDefinition p) => !p.adminOnly).toList(growable: false);
    }
    return pages.where((DocPageDefinition p) => p.isVisibleTo(role)).toList(growable: false);
  }

  static List<DocPageDefinition> recommendedPagesFor(UserRole role) {
    final List<DocPageDefinition> visible = visiblePagesFor(role);
    final Map<String, DocPageDefinition> byId = <String, DocPageDefinition>{
      for (final DocPageDefinition p in visible) p.id: p,
    };
    return recommendedIdsFor(role)
        .map((String id) => byId[id])
        .whereType<DocPageDefinition>()
        .toList(growable: false);
  }

  static List<(DocCategory, List<DocPageDefinition>)> groupedVisiblePages(UserRole? role) {
    final List<DocPageDefinition> visible = visiblePagesFor(role);
    final List<(DocCategory, List<DocPageDefinition>)> out =
        <(DocCategory, List<DocPageDefinition>)>[];
    for (final DocCategory cat in DocCategory.values) {
      final List<DocPageDefinition> group =
          visible.where((DocPageDefinition p) => p.category == cat).toList(growable: false);
      if (group.isEmpty) continue;
      out.add((cat, group));
    }
    return out;
  }

  static DocPageDefinition byId(String id) {
    if (id == helpHomeId) return helpHomePage;
    return pages.firstWhere(
      (DocPageDefinition p) => p.id == id,
      orElse: () => helpHomePage,
    );
  }

  static int indexOf(String id, {List<DocPageDefinition>? among}) {
    final List<DocPageDefinition> list = among ?? pages;
    return list.indexWhere((DocPageDefinition p) => p.id == id);
  }

  static DocPageDefinition? previousOf(String id, {List<DocPageDefinition>? among}) {
    final List<DocPageDefinition> list = among ?? pages;
    final int i = indexOf(id, among: list);
    if (i <= 0) return null;
    return list[i - 1];
  }

  static DocPageDefinition? nextOf(String id, {List<DocPageDefinition>? among}) {
    final List<DocPageDefinition> list = among ?? pages;
    final int i = indexOf(id, among: list);
    if (i < 0 || i >= list.length - 1) return null;
    return list[i + 1];
  }

  static List<DocSectionSpec> sectionsFor(String id) {
    if (id == helpHomeId) return const <DocSectionSpec>[];
    if (id == 'problem-lifecycle') return ProblemLifecycleSections.all;
    if (id == 'idea-lifecycle') return IdeaLifecycleSections.all;
    if (id == 'roles-responsibilities') return RolesResponsibilitiesSections.all;
    return const <DocSectionSpec>[
      DocSectionSpec(id: 'overview', title: 'Overview'),
    ];
  }

  /// Maps dashboard menu labels / workspace contexts to Help page ids.
  static String? helpPageForContext(String contextKey) {
    final String key = contextKey.trim().toLowerCase();
    return switch (key) {
      'problem statements' || 'problem workspace' || 'problem details' || 'problems' =>
        'problem-lifecycle',
      'ideas dashboard' || 'idea workspace' || 'idea details' || 'innovation submission' =>
        'idea-lifecycle',
      'problem import' || 'csv import' || 'import' => 'csv-import',
      'evaluation results' ||
      'evaluation assignment' ||
      'shortlisting' ||
      'judge dashboard' ||
      'judges panel' ||
      'evaluation extensions' =>
        'evaluation-lifecycle',
      'ideathons' || 'ideathon' || 'ideathon workspace' => 'ideathon',
      'hackathon' || 'hackathon workspace' => 'hackathon',
      'org settings' || 'organization settings' => 'org-settings',
      'domains' || 'domain management' => 'domain-management',
      'manage college' || 'manage department' || 'user management' || 'organizations' =>
        'user-management',
      'payments' || 'payment verification' => 'payment-verification',
      'roles' || 'roles & responsibilities' => 'roles-responsibilities',
      _ => null,
    };
  }
}
