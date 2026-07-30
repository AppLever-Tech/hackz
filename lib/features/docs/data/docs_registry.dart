import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../data/problem_lifecycle_content.dart';
import '../models/doc_models.dart';
import '../screens/pages/placeholder_doc_page.dart';
import 'docs_asset_paths.dart';

/// Central registry — add future docs here only; layout stays unchanged.
abstract final class DocsRegistry {
  DocsRegistry._();

  static final List<DocPageDefinition> pages = <DocPageDefinition>[
    DocPageDefinition(
      id: 'problem-lifecycle',
      title: 'Problem Lifecycle',
      description: 'Catalog stages for Hackz problem statements.',
      icon: AppIcons.problems,
      lastUpdated: DateTime(2026, 7, 30),
      readingMinutes: 8,
      heroImageAsset: DocsAssetPaths.problemLifecycle,
      searchKeywords: ProblemLifecycleSections.searchCorpus,
      builder: (BuildContext context) => const SizedBox.shrink(), // assembled by shell
    ),
    DocPageDefinition(
      id: 'idea-lifecycle',
      title: 'Idea Lifecycle',
      description: 'Innovation journey from draft to winner.',
      icon: AppIcons.ideas,
      isPlaceholder: true,
      searchKeywords: const <String>['idea', 'shortlist', 'evaluation'],
      builder: (_) => const PlaceholderDocPage(
        title: 'Idea Lifecycle',
        description: 'Document the full IdeaStatus journey attached to active problems.',
      ),
    ),
    DocPageDefinition(
      id: 'evaluation-lifecycle',
      title: 'Evaluation Lifecycle',
      description: 'Assignments, scoring, and shortlisting.',
      icon: AppIcons.scoring,
      isPlaceholder: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'Evaluation Lifecycle',
        description: 'Judge assignment, aggregation, ready-for-shortlisting, and results.',
      ),
    ),
    DocPageDefinition(
      id: 'ideathon',
      title: 'Ideathon',
      description: 'Post-shortlist ideathon workflows.',
      icon: AppIcons.ideathons,
      isPlaceholder: true,
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
      builder: (_) => const PlaceholderDocPage(
        title: 'Hackathon',
        description: 'Future Hackathon documentation will land here.',
      ),
    ),
    DocPageDefinition(
      id: 'csv-import',
      title: 'CSV Import',
      description: 'Users and problems import pipelines.',
      icon: AppIcons.submissions,
      isPlaceholder: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'CSV Import',
        description: 'Templates, validation, department codes, and domain codes.',
      ),
    ),
    DocPageDefinition(
      id: 'roles-permissions',
      title: 'Roles & Permissions',
      description: 'Who can view and act across Hackz.',
      icon: AppIcons.users,
      isPlaceholder: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'Roles & Permissions',
        description: 'Role matrix for SysAdmin through Student.',
      ),
    ),
    DocPageDefinition(
      id: 'org-settings',
      title: 'Organization Settings',
      description: 'Org configuration and evaluation settings.',
      icon: AppIcons.orgSettings,
      isPlaceholder: true,
      builder: (_) => const PlaceholderDocPage(
        title: 'Organization Settings',
        description: 'Evaluation configuration, team rules, and session cache lifecycle.',
      ),
    ),
  ];

  static DocPageDefinition byId(String id) {
    return pages.firstWhere(
      (DocPageDefinition p) => p.id == id,
      orElse: () => pages.first,
    );
  }

  static int indexOf(String id) => pages.indexWhere((DocPageDefinition p) => p.id == id);

  static DocPageDefinition? previousOf(String id) {
    final int i = indexOf(id);
    if (i <= 0) return null;
    return pages[i - 1];
  }

  static DocPageDefinition? nextOf(String id) {
    final int i = indexOf(id);
    if (i < 0 || i >= pages.length - 1) return null;
    return pages[i + 1];
  }

  static List<DocSectionSpec> sectionsFor(String id) {
    if (id == 'problem-lifecycle') return ProblemLifecycleSections.all;
    return const <DocSectionSpec>[
      DocSectionSpec(id: 'overview', title: 'Overview'),
    ];
  }
}
