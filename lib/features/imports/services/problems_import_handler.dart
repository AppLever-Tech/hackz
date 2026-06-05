import 'package:cloud_firestore/cloud_firestore.dart';

import '../../problems/constants/problem_constants.dart';
import '../../organization/models/department_model.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/models/problem_status.dart';
import '../../problems/services/problem_utils.dart';
import '../../../utils/firestore_utils.dart';
import '../models/import_created_source.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_type.dart';
import 'import_handler.dart';

class ProblemsImportHandler implements ImportHandler {
  static const List<String> headers = <String>[
    'title',
    'description',
    'category',
    'department',
    'theme',
    'tags',
  ];

  @override
  ImportType get type => ImportType.problems;

  @override
  String get title => 'Import Problems';

  @override
  String get templateFileName => 'hackz_problems_import_template.csv';

  @override
  String get templateCsv => '''
title,description,category,department,theme,tags
Smart Campus Navigation,Help students find classrooms quickly,Software,CSE,Mobility,"IoT,Mobile"
Waste Segregation Monitor,Track recycling compliance on campus,Hardware,CSE,Environment,"IoT,AI/ML"
'''.trim();

  @override
  List<String> get requiredHeaders => const <String>['title', 'category', 'department'];

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final _ProblemImportLookup lookup = await _ProblemImportLookup.load(context.orgId);
    final Set<String> titlesInFile = <String>{};
    final List<ImportReviewRow> review = <ImportReviewRow>[];

    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int rowNumber = i + 2;
      final String title = _cell(row, 'title');
      final String description = _cell(row, 'description');
      final String category = _cell(row, 'category');
      final String departmentRaw = _cell(row, 'department');
      final String theme = _cell(row, 'theme');
      final String tagsRaw = _cell(row, 'tags');

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';
      String departmentStatus = '';

      if (title.isEmpty) {
        issues.add('Missing title');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Title';
      }
      if (departmentRaw.isEmpty) {
        issues.add('Missing department');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Department';
      } else {
        final String departmentCode = DepartmentModel.resolveCode(departmentRaw);
        final DepartmentModel? dept = DepartmentModel.byCode(departmentCode);
        if (dept == null && !lookup.knownDepartmentCodes.contains(departmentCode)) {
          issues.add('Unknown department');
          severity = ImportRowSeverity.error;
          importable = false;
          statusLabel = 'Invalid Department';
        } else {
          departmentStatus = dept?.name ?? departmentRaw;
        }
      }

      String? resolvedCategory;
      if (category.isEmpty) {
        issues.add('Missing category');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Category';
      } else {
        resolvedCategory = ProblemConstants.resolveCategory(category);
        if (resolvedCategory == null) {
          issues.add('Category must be Software or Hardware');
          severity = ImportRowSeverity.error;
          importable = false;
          statusLabel = 'Invalid Category';
        }
      }

      final String normalizedTitle = title.trim().toLowerCase();
      if (normalizedTitle.isNotEmpty) {
        if (titlesInFile.contains(normalizedTitle)) {
          issues.add('Duplicate title in file');
          severity = ImportRowSeverity.error;
          importable = false;
          statusLabel = 'Duplicate Title';
        } else if (lookup.existingTitles.contains(normalizedTitle)) {
          issues.add('Problem title already exists');
          severity = ImportRowSeverity.warning;
          importable = false;
          statusLabel = 'Duplicate';
        }
        titlesInFile.add(normalizedTitle);
      }

      final String departmentCode = departmentRaw.isEmpty
          ? ''
          : DepartmentModel.resolveCode(departmentRaw);

      review.add(
        ImportReviewRow(
          rowNumber: rowNumber,
          values: <String, String>{
            'title': title,
            'description': description,
            'category': resolvedCategory ?? category,
            'department': departmentStatus.isEmpty ? departmentRaw : departmentStatus,
            'theme': theme,
            'tags': tagsRaw,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            if (departmentCode.isNotEmpty) 'departmentCode': departmentCode,
            if (resolvedCategory != null) 'category': resolvedCategory,
            if (tagsRaw.isNotEmpty) 'tags': tagsRaw,
          },
        ),
      );
    }

    return review;
  }

  @override
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context,
  ) async {
    final List<ImportReviewRow> importable =
        rows.where((ImportReviewRow r) => r.importable).toList(growable: false);

    var imported = 0;
    var skipped = rows.length - importable.length;
    var failed = 0;
    final List<String> failures = <String>[];

    for (final ImportReviewRow row in importable) {
      try {
        final String departmentCode = row.metadata['departmentCode'] ??
            DepartmentModel.resolveCode(row.valueFor('department'));
        final String problemId =
            FirebaseFirestore.instance.collection(FirestoreUtils.hkzProblems).doc().id;
        final String problemNumber = await ProblemUtils.generateProblemNumber();
        final List<String> tags = _parseTags(row.metadata['tags'] ?? row.valueFor('tags'));

        final ProblemModel problem = ProblemModel(
          problemId: problemId,
          problemNumber: problemNumber,
          title: row.valueFor('title'),
          description: row.valueFor('description'),
          orgId: context.orgId,
          orgType: 'college',
          departmentCode: departmentCode,
          createdBy: context.actorUserId,
          category: row.metadata['category'] ?? row.valueFor('category'),
          theme: row.valueFor('theme'),
          tags: tags,
          attachments: const <String>[],
          status: ProblemStatus.draft,
          createdAt: DateTime.now(),
          createdSource: ImportCreatedSource.csvImport.value,
        );

        await FirestoreUtils.createProblemWithId(problem: problem, problemId: problemId);
        imported++;
      } catch (e) {
        failed++;
        failures.add('Row ${row.rowNumber}: $e');
      }
    }

    return ImportExecutionResult(
      imported: imported,
      skipped: skipped,
      failed: failed,
      failures: failures,
    );
  }

  static String _cell(Map<String, String> row, String key) => (row[key] ?? '').trim();

  static List<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return const <String>[];
    return raw
        .split(RegExp(r'[;,]'))
        .map((String t) => t.trim())
        .where((String t) => t.isNotEmpty)
        .toList(growable: false);
  }
}

class _ProblemImportLookup {
  _ProblemImportLookup({
    required this.existingTitles,
    required this.knownDepartmentCodes,
  });

  final Set<String> existingTitles;
  final Set<String> knownDepartmentCodes;

  static Future<_ProblemImportLookup> load(String orgId) async {
    final List<ProblemModel> problems = await FirestoreUtils.getProblemModelsByCollege(orgId);
    final List<Map<String, dynamic>> departments = await FirestoreUtils.getDepartmentsByCollege(orgId);

    return _ProblemImportLookup(
      existingTitles: problems
          .map((ProblemModel p) => p.title.trim().toLowerCase())
          .where((String t) => t.isNotEmpty)
          .toSet(),
      knownDepartmentCodes: departments
          .map((Map<String, dynamic> d) => ((d['code'] as String?) ?? '').trim().toUpperCase())
          .where((String c) => c.isNotEmpty)
          .toSet(),
    );
  }
}
