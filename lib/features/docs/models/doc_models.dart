import 'package:flutter/material.dart';

/// Identifies a documentation page in the registry.
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
