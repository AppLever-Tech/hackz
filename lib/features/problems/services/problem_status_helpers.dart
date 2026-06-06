import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../imports/models/import_created_source.dart';
import '../models/problem_status.dart';

/// Labels, colors, and icons for problem lifecycle and source indicators.
abstract final class ProblemStatusHelpers {
  ProblemStatusHelpers._();

  static String label(ProblemStatus status) {
    return switch (status) {
      ProblemStatus.draft => 'Draft',
      ProblemStatus.active => 'Active',
      ProblemStatus.inactive => 'Inactive',
      ProblemStatus.archived => 'Archived',
    };
  }

  static Color color(ProblemStatus status) {
    return switch (status) {
      ProblemStatus.draft => const Color(0xFF7C3AED),
      ProblemStatus.active => const Color(0xFF059669),
      ProblemStatus.inactive => const Color(0xFF64748B),
      ProblemStatus.archived => const Color(0xFF94A3B8),
    };
  }

  static Color background(ProblemStatus status) {
    return switch (status) {
      ProblemStatus.draft => const Color(0xFFF3EEFF),
      ProblemStatus.active => const Color(0xFFE6F8EF),
      ProblemStatus.inactive => const Color(0xFFF1F5F9),
      ProblemStatus.archived => const Color(0xFFF8FAFC),
    };
  }

  static IconData icon(ProblemStatus status) => AppIcons.forProblemStatus(status);

  static String sourceLabel(String? createdSource) {
    final String raw = (createdSource ?? '').trim();
    if (raw == ImportCreatedSource.csvImport.value) return 'Imported';
    if (raw == ImportCreatedSource.manual.value) return 'Manual';
    return '—';
  }

  static Color sourceColor(String? createdSource) {
    final String raw = (createdSource ?? '').trim();
    if (raw == ImportCreatedSource.csvImport.value) return const Color(0xFF0EA5E9);
    if (raw == ImportCreatedSource.manual.value) return const Color(0xFF475569);
    return const Color(0xFF94A3B8);
  }

  static Color sourceBackground(String? createdSource) {
    final String raw = (createdSource ?? '').trim();
    if (raw == ImportCreatedSource.csvImport.value) return const Color(0xFFE0F2FE);
    if (raw == ImportCreatedSource.manual.value) return const Color(0xFFF1F5F9);
    return const Color(0xFFF8FAFC);
  }

  static IconData sourceIcon(String? createdSource) {
    final String raw = (createdSource ?? '').trim();
    if (raw == ImportCreatedSource.csvImport.value) return Icons.upload_file_rounded;
    if (raw == ImportCreatedSource.manual.value) return Icons.edit_rounded;
    return Icons.help_outline_rounded;
  }

  static bool matchesSourceFilter(String? createdSource, ImportCreatedSource? filter) {
    if (filter == null) return true;
    return (createdSource ?? '').trim() == filter.value;
  }
}
