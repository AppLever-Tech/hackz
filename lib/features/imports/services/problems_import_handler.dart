import 'package:cloud_firestore/cloud_firestore.dart';

import '../../problems/constants/problem_constants.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/models/problem_status.dart';
import '../../problems/services/problem_utils.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../models/import_created_source.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_type.dart';
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_domain_lookup.dart';
import 'import_domain_validator.dart';
import 'import_handler.dart';

class ProblemsImportHandler implements ImportHandler {
  static const List<String> headers = <String>[
    'title',
    'description',
    'category',
    ImportConstants.departmentColumnKey,
    ImportConstants.domainCodeColumnKey,
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
title,description,category,${ImportConstants.departmentColumnKey},${ImportConstants.domainCodeColumnKey},theme,tags
Smart Campus Navigation,Help students find classrooms quickly,Software,CSE,CLOUDSEC,Mobility,"IoT,Mobile"
Waste Segregation Monitor,Track recycling compliance on campus,Hardware,CSE,IAM,Environment,"IoT,AI/ML"
'''.trim();

  @override
  List<String> get requiredHeaders => const <String>[
        'title',
        'category',
        ImportConstants.departmentColumnKey,
        ImportConstants.domainCodeColumnKey,
      ];

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
      final String departmentRaw = _cell(row, ImportConstants.departmentColumnKey);
      final String domainRaw = _cell(row, ImportConstants.domainCodeColumnKey);
      final String theme = _cell(row, 'theme');
      final String tagsRaw = _cell(row, 'tags');

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';
      String? departmentCode;
      String? departmentName;
      String? domainId;
      String? domainCode;

      if (title.isEmpty) {
        issues.add('Missing title');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Title';
      }

      final ImportDepartmentValidation deptResult = ImportDepartmentValidator.validate(
        rawInput: departmentRaw,
        lookup: lookup.departments,
      );
      if (!deptResult.isValid) {
        issues.add(deptResult.errorMessage ?? 'Invalid department code');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = deptResult.statusLabel ?? 'Invalid Department';
      } else {
        departmentCode = deptResult.canonicalCode;
        departmentName = deptResult.departmentName;
      }

      final ImportDomainValidation domainResult = ImportDomainValidator.validate(
        rawInput: domainRaw,
        departmentCode: departmentCode,
        lookup: lookup.domains,
      );
      if (!domainResult.isValid) {
        issues.add(domainResult.errorMessage ?? 'Invalid domain code');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = domainResult.statusLabel ?? 'Invalid Domain';
      } else {
        domainId = domainResult.domainId;
        domainCode = domainResult.canonicalCode;
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

      if (severity == ImportRowSeverity.valid && importable) {
        statusLabel = 'Valid';
      }

      review.add(
        ImportReviewRow(
          rowNumber: rowNumber,
          values: <String, String>{
            'title': title,
            'description': description,
            'category': resolvedCategory ?? category,
            ImportConstants.departmentColumnKey: departmentCode ?? departmentRaw,
            ImportConstants.domainCodeColumnKey: domainCode ?? domainRaw,
            'theme': theme,
            'tags': tagsRaw,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            if (departmentCode != null) 'departmentCode': departmentCode,
            if (departmentName != null && departmentName.isNotEmpty) 'departmentName': departmentName,
            if (domainId != null) 'domainId': domainId,
            if (domainCode != null) 'domainCode': domainCode,
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
        final String departmentCode =
            row.metadata['departmentCode'] ?? row.valueFor(ImportConstants.departmentColumnKey);
        final String domainId = row.metadata['domainId'] ?? '';
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
          domainId: domainId,
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
    required this.departments,
    required this.domains,
  });

  final Set<String> existingTitles;
  final ImportDepartmentLookup departments;
  final ImportDomainLookup domains;

  static Future<_ProblemImportLookup> load(String orgId) async {
    final List<ProblemModel> problems = await FirestoreUtils.getProblemModelsByCollege(orgId);
    final ImportDepartmentLookup departments = await ImportDepartmentLookup.load(orgId);
    final ImportDomainLookup domains = await ImportDomainLookup.load(orgId);

    return _ProblemImportLookup(
      existingTitles: problems
          .map((ProblemModel p) => p.title.trim().toLowerCase())
          .where((String t) => t.isNotEmpty)
          .toSet(),
      departments: departments,
      domains: domains,
    );
  }
}
