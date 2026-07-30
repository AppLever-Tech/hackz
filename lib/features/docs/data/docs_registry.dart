import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../data/idea_lifecycle_content.dart';
import '../data/problem_lifecycle_content.dart';
import '../data/roles_responsibilities_content.dart';
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
      description:
          'Complete lifecycle of an innovation idea from submission through evaluation, shortlisting, ideathon, prototype selection and winner declaration.',
      icon: AppIcons.ideas,
      lastUpdated: DateTime(2026, 7, 30),
      readingMinutes: 6,
      heroImageAsset: DocsAssetPaths.ideaLifecycle,
      searchKeywords: IdeaLifecycleSections.searchCorpus,
      builder: (BuildContext context) => const SizedBox.shrink(), // assembled by shell
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
      builder: (BuildContext context) => const SizedBox.shrink(), // assembled by shell
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
    if (id == 'idea-lifecycle') return IdeaLifecycleSections.all;
    if (id == 'roles-responsibilities') return RolesResponsibilitiesSections.all;
    return const <DocSectionSpec>[
      DocSectionSpec(id: 'overview', title: 'Overview'),
    ];
  }
}
