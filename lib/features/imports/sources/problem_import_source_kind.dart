import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// How problem records are obtained before they enter the shared import pipeline.
enum ProblemImportSourceKind {
  csv('CSV'),
  googleDoc('Google Doc'),
  googleSheet('Google Sheet');

  const ProblemImportSourceKind(this.label);

  final String label;

  bool get isGoogle => this == googleDoc || this == googleSheet;

  IconData get icon => switch (this) {
        csv => AppIcons.attachments,
        googleDoc => AppIcons.docs,
        googleSheet => AppIcons.spreadsheet,
      };
}
