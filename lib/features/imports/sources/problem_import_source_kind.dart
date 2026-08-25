import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// How problem records are obtained before they enter the shared import pipeline.
enum ProblemImportSourceKind {
  csv('CSV'),
  excel('Excel (.xlsx, .xls)'),
  googleSheet('Google Sheet'),
  googleDoc('Google Doc');

  const ProblemImportSourceKind(this.label);

  final String label;

  bool get isGoogle => this == googleDoc || this == googleSheet;

  bool get isFile => this == csv || this == excel;

  IconData get icon => switch (this) {
        csv => AppIcons.attachments,
        excel => AppIcons.spreadsheet,
        googleDoc => AppIcons.docs,
        googleSheet => AppIcons.spreadsheet,
      };
}
