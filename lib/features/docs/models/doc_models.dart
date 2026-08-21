import 'package:flutter/material.dart';

import '../../user/models/enums/user_role.dart';

/// Help content categories for sidebar grouping.
enum DocCategory {
  gettingStarted,
  institutionSolutions,
  workflows,
  reference,
  administration,
}

extension DocCategoryLabels on DocCategory {
  String get label => switch (this) {
        DocCategory.gettingStarted => 'Getting Started',
        DocCategory.institutionSolutions => 'Institution Solutions',
        DocCategory.workflows => 'Workflows',
        DocCategory.reference => 'Reference',
        DocCategory.administration => 'Administration',
      };
}

/// Identifies a documentation / Help page in the registry.
class DocPageDefinition {
  const DocPageDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
    this.lastUpdated,
    this.readingMinutes = 5,
    this.isPlaceholder = false,
    this.heroImageAsset,
    this.searchKeywords = const <String>[],
    this.category = DocCategory.reference,
    this.adminOnly = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;
  final DateTime? lastUpdated;
  final int readingMinutes;
  final bool isPlaceholder;
  final String? heroImageAsset;
  final List<String> searchKeywords;
  final DocCategory category;

  /// When true, hidden from non-admin Help browsers (Faculty/Judge/Coordinator/Team Member).
  final bool adminOnly;

  bool isVisibleTo(UserRole role) {
    if (!adminOnly) return true;
    return role == UserRole.sysAdmin ||
        role == UserRole.collegeAdmin ||
        role == UserRole.departmentAdmin;
  }
}

/// A scroll-anchored section used for TOC and deep links.
class DocSectionSpec {
  const DocSectionSpec({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

enum DocInfoTone { information, important, success, warning, note }

enum DocStatusKind { draft, active, inactive, archived, custom }

enum DocTimelineAxis { vertical, horizontal }
