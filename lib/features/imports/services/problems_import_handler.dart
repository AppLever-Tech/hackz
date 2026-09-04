import '../../domain/models/domain_model.dart';
import '../../domain/services/domain_department_resolver.dart';
import '../../domain/services/domain_service.dart';
import '../../problems/constants/problem_constants.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/models/problem_statement_source.dart';
import '../../problems/models/problem_status.dart';
import '../../problems/services/problem_source_identity.dart';
import '../../problems/services/problem_utils.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../models/import_created_source.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_summary.dart';
import '../models/import_type.dart';
import '../sources/problem_normalized_row_mapper.dart';
import 'csv_parser_service.dart';
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_handler.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class ProblemsImportHandler extends ImportHandler {
  static const List<String> headers = <String>[
    ImportConstants.titleColumnKey,
    ImportConstants.descriptionColumnKey,
    ImportConstants.themeColumnKey,
    ImportConstants.issuingOrganisationColumnKey,
    ImportConstants.issuingDepartmentColumnKey,
    ImportConstants.externalProblemIdColumnKey,
  ];

  @override
  ImportType get type => ImportType.problems;

  @override
  String get title => 'Import Problems';

  static const String templateExcelFileName = 'hackz_problems_import_template.xlsx';

  @override
  String get templateFileName => 'hackz_problems_import_template.csv';

  @override
  String get templateCsv => '''
title,description,theme,issuingOrganisation,issuingDepartment,externalProblemId
Smart Campus Navigation,Help students find classrooms quickly,,,,
Waste Segregation Monitor,Track recycling compliance on campus,Environment,Smart India Hackathon,MoE,SIH-2026-001
'''.trim();

  @override
  List<String> get requiredHeaders => const <String>[
        ImportConstants.titleColumnKey,
        ImportConstants.descriptionColumnKey,
      ];

  @override
  List<String> get reviewHeaders => const <String>[
        ImportConstants.titleColumnKey,
        ImportConstants.descriptionColumnKey,
      ];

  @override
  List<String> get expansionHeaders => const <String>[
        ImportConstants.externalProblemIdColumnKey,
        ImportConstants.themeColumnKey,
        ImportConstants.issuingOrganisationColumnKey,
        ImportConstants.issuingDepartmentColumnKey,
      ];

  @override
  List<String> get optionalHeaders => const <String>[
        ImportConstants.themeColumnKey,
        ImportConstants.issuingOrganisationColumnKey,
        ImportConstants.issuingDepartmentColumnKey,
        ImportConstants.externalProblemIdColumnKey,
      ];

  @override
  bool get blockImportOnAnyError => true;

  @override
  ImportSummary summarize(List<ImportReviewRow> rows) {
    final ImportSummary summary = ImportSummary.fromRows(rows);
    return ImportSummary(
      totalRows: summary.totalRows,
      validRows: summary.validRows,
      warningRows: summary.warningRows,
      errorRows: summary.errorRows,
      skippedRows: summary.skippedRows,
      previewCounts: <ImportPreviewCount>[
        ImportPreviewCount(label: 'Extracted', value: summary.totalRows),
        ImportPreviewCount(label: 'Valid', value: summary.validRows),
        ImportPreviewCount(label: 'Needs review', value: summary.warningRows),
        ImportPreviewCount(label: 'Invalid', value: summary.errorRows),
        ImportPreviewCount(
          label: 'Updates',
          value: rows.where((ImportReviewRow r) => (r.metadata['existingProblemId'] ?? '').isNotEmpty).length,
        ),
      ],
    );
  }

  @override
  List<String> get columnGuidancePoints => const <String>[
        'Theme defaults to Miscellaneous when blank.',
        'Category defaults to Software when blank.',
        'Organisation, department, domain, and source come from this screen — not the file.',
      ];

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final ProblemsImportHandlerContext problemContext = _requireContext(context);
    final _ProblemImportLookup lookup = await _ProblemImportLookup.load(problemContext);

    final Set<String> identitiesInFile = <String>{};
    final List<ImportReviewRow> review = <ImportReviewRow>[];

    for (var i = 0; i < rows.length; i++) {
      final Map<String, String> row = rows[i];
      final int rowNumber = i + 1;
      final String title = CsvParserService.cell(row, ImportConstants.titleColumnKey);
      final String description = CsvParserService.cell(row, ImportConstants.descriptionColumnKey);
      final String themeRaw = CsvParserService.cell(row, ImportConstants.themeColumnKey);
      final String theme = themeRaw.isEmpty ? ProblemConstants.defaultTheme : themeRaw;
      final String issuingOrganisation =
          CsvParserService.cell(row, ImportConstants.issuingOrganisationColumnKey);
      final String issuingDepartment =
          CsvParserService.cell(row, ImportConstants.issuingDepartmentColumnKey);
      final String sourceProblemId =
          CsvParserService.cell(row, ImportConstants.externalProblemIdColumnKey);
      final String categoryRaw =
          CsvParserService.cell(row, ProblemNormalizedRowMapper.categoryColumnKey);
      final String tagsRaw = CsvParserService.cell(row, ProblemNormalizedRowMapper.tagsColumnKey);
      final String category =
          ProblemConstants.resolveCategory(categoryRaw) ?? ProblemConstants.categorySoftware;
      final String catalogSource = ProblemSourceIdentity.resolveForImport(
        sourceProblemId: sourceProblemId,
        issuingOrganisation: issuingOrganisation,
        internal: problemContext.problemSource == ProblemStatementSource.internal,
      );

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';
      String existingProblemId = '';

      if (title.isEmpty) {
        issues.add('Missing title');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Title';
      }

      if (description.isEmpty) {
        issues.add('Missing description');
        severity = ImportRowSeverity.error;
        importable = false;
        statusLabel = 'Missing Description';
      }

      final String? identityKey = ProblemSourceIdentity.key(catalogSource, sourceProblemId);
      if (identityKey != null && importable) {
        if (identitiesInFile.contains(identityKey)) {
          issues.add('Duplicate source ID in file');
          severity = ImportRowSeverity.error;
          importable = false;
          statusLabel = 'Duplicate Source ID';
        } else {
          identitiesInFile.add(identityKey);
          final ProblemModel? existing = lookup.byIdentity[identityKey];
          if (existing != null) {
            existingProblemId = existing.problemId;
            issues.add('Existing $catalogSource problem will be updated');
            statusLabel = 'Update';
          }
        }
      }

      if (severity == ImportRowSeverity.valid && importable && statusLabel != 'Update') {
        statusLabel = 'Valid';
      }

      review.add(
        ImportReviewRow(
          rowNumber: rowNumber,
          values: <String, String>{
            ImportConstants.titleColumnKey: title,
            ImportConstants.descriptionColumnKey: description,
            ImportConstants.themeColumnKey: themeRaw,
            ImportConstants.issuingOrganisationColumnKey: issuingOrganisation,
            ImportConstants.issuingDepartmentColumnKey: issuingDepartment,
            ImportConstants.externalProblemIdColumnKey: sourceProblemId,
            if (tagsRaw.isNotEmpty) ProblemNormalizedRowMapper.tagsColumnKey: tagsRaw,
            if (categoryRaw.isNotEmpty) ProblemNormalizedRowMapper.categoryColumnKey: categoryRaw,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            'departmentCode': lookup.departmentCode,
            if (lookup.departmentName.isNotEmpty) 'departmentName': lookup.departmentName,
            'domainId': lookup.domainId,
            'category': category,
            'source': catalogSource,
            'theme': theme,
            if (themeRaw.isNotEmpty ||
                issuingOrganisation.isNotEmpty ||
                issuingDepartment.isNotEmpty ||
                sourceProblemId.isNotEmpty)
              'expandable': '1',
            if (issuingOrganisation.isNotEmpty) 'issuingOrganisation': issuingOrganisation,
            if (issuingDepartment.isNotEmpty) 'issuingDepartment': issuingDepartment,
            if (sourceProblemId.isNotEmpty) 'sourceProblemId': sourceProblemId,
            if (sourceProblemId.isNotEmpty) 'externalProblemId': sourceProblemId,
            if (existingProblemId.isNotEmpty) 'existingProblemId': existingProblemId,
          },
        ),
      );
    }

    return review;
  }

  @override
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context, {
    void Function(int current, int total)? onProgress,
  }) async {
    final ProblemsImportHandlerContext problemContext = _requireContext(context);
    final List<ImportReviewRow> importable =
        rows.where((ImportReviewRow r) => r.importable && !r.excluded).toList(growable: false);

    var imported = 0;
    var skipped = rows.length - importable.length;
    var failed = 0;
    final List<String> failures = <String>[];
    final int total = importable.length;

    for (var i = 0; i < importable.length; i++) {
      final ImportReviewRow row = importable[i];
      onProgress?.call(i + 1, total);
      try {
        final String departmentCode =
            row.metadata['departmentCode'] ?? problemContext.defaultDepartmentCode;
        final String domainId = row.metadata['domainId'] ?? '';
        if (domainId.isEmpty) {
          throw StateError(ImportConstants.generalProblemDomainFailedMessage);
        }
        final String sourceProblemId = (row.metadata['sourceProblemId'] ??
                row.valueFor(ImportConstants.externalProblemIdColumnKey))
            .trim();
        final String catalogSource =
            (row.metadata['source'] ?? ProblemSourceIdentity.college).trim();
        final String existingProblemId = (row.metadata['existingProblemId'] ?? '').trim();

        if (existingProblemId.isNotEmpty) {
          await FirestoreUtils.updateProblem(existingProblemId, <String, dynamic>{
            'title': row.valueFor(ImportConstants.titleColumnKey),
            'description': row.valueFor(ImportConstants.descriptionColumnKey),
            'category': row.metadata['category'] ?? ProblemConstants.categorySoftware,
            'theme': (row.metadata['theme'] ?? '').trim().isEmpty
                ? ProblemConstants.defaultTheme
                : row.metadata['theme']!.trim(),
            'tags': _tagsFor(row),
            'source': catalogSource,
            'issuingOrganisation': row.valueFor(ImportConstants.issuingOrganisationColumnKey),
            'issuingDepartment': row.valueFor(ImportConstants.issuingDepartmentColumnKey),
            if (sourceProblemId.isNotEmpty) 'sourceProblemId': sourceProblemId,
            if (sourceProblemId.isNotEmpty) 'externalProblemId': sourceProblemId,
          });
          imported++;
          continue;
        }

        final String problemId =
            HackzFirebase.current.firestore.collection(FirestoreUtils.hkzProblems).doc().id;
        final String problemNumber = await ProblemUtils.generateProblemNumber();

        final ProblemModel problem = ProblemModel(
          problemId: problemId,
          problemNumber: problemNumber,
          title: row.valueFor(ImportConstants.titleColumnKey),
          description: row.valueFor(ImportConstants.descriptionColumnKey),
          orgId: problemContext.orgId,
          orgType: problemContext.orgType,
          departmentCode: departmentCode,
          domainId: domainId,
          createdBy: problemContext.actorUserId,
          category: row.metadata['category'] ?? ProblemConstants.categorySoftware,
          theme: (row.metadata['theme'] ?? '').trim().isEmpty
              ? ProblemConstants.defaultTheme
              : row.metadata['theme']!.trim(),
          tags: _tagsFor(row),
          attachments: const <String>[],
          status: ProblemStatus.draft,
          createdAt: DateTime.now(),
          createdSource: problemContext.createdSource.value,
          source: catalogSource,
          issuingOrganisation: row.valueFor(ImportConstants.issuingOrganisationColumnKey),
          issuingDepartment: row.valueFor(ImportConstants.issuingDepartmentColumnKey),
          sourceProblemId: sourceProblemId,
          referenceLinks: problemContext.sourceUrl.trim().isEmpty
              ? const <String>[]
              : <String>[problemContext.sourceUrl.trim()],
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

  static ProblemsImportHandlerContext _requireContext(ImportHandlerContext context) {
    if (context is ProblemsImportHandlerContext) return context;
    throw StateError('Problem import requires organisation and department context.');
  }

  static List<String> _tagsFor(ImportReviewRow row) {
    final String raw = row.valueFor(ProblemNormalizedRowMapper.tagsColumnKey);
    if (raw.isEmpty) return const <String>[];
    return raw
        .split(RegExp(r'[,;]'))
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList(growable: false);
  }
}

class ProblemsImportHandlerContext extends ImportHandlerContext {
  ProblemsImportHandlerContext({
    required super.actorUserId,
    required super.orgId,
    required super.defaultDepartmentName,
    required super.defaultDepartmentCode,
    this.orgName = '',
    this.orgType = 'college',
    this.lockDepartment = false,
    this.problemSource = ProblemStatementSource.internal,
    this.sourceUrl = '',
    this.createdSource = ImportCreatedSource.csvImport,
  });

  final String orgName;
  final String orgType;
  final bool lockDepartment;
  final ProblemStatementSource problemSource;
  final String sourceUrl;
  final ImportCreatedSource createdSource;

  ProblemsImportHandlerContext copyWith({
    String? defaultDepartmentName,
    String? defaultDepartmentCode,
    String? orgName,
    ProblemStatementSource? problemSource,
    String? sourceUrl,
    ImportCreatedSource? createdSource,
  }) {
    return ProblemsImportHandlerContext(
      actorUserId: actorUserId,
      orgId: orgId,
      defaultDepartmentName: defaultDepartmentName ?? this.defaultDepartmentName,
      defaultDepartmentCode: defaultDepartmentCode ?? this.defaultDepartmentCode,
      orgName: orgName ?? this.orgName,
      orgType: orgType,
      lockDepartment: lockDepartment,
      problemSource: problemSource ?? this.problemSource,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdSource: createdSource ?? this.createdSource,
    );
  }
}

class _ProblemImportLookup {
  _ProblemImportLookup({
    required this.byIdentity,
    required this.departmentCode,
    required this.departmentName,
    required this.domainId,
  });

  final Map<String, ProblemModel> byIdentity;
  final String departmentCode;
  final String departmentName;
  final String domainId;

  static Future<_ProblemImportLookup> load(ProblemsImportHandlerContext context) async {
    final String departmentCode = context.defaultDepartmentCode.trim().toUpperCase();
    if (departmentCode.isEmpty) {
      throw StateError(ImportConstants.missingImportDepartmentMessage);
    }

    final ImportDepartmentLookup departments = await ImportDepartmentLookup.load(context.orgId);
    final ImportDepartmentValidation deptResult = ImportDepartmentValidator.validate(
      rawInput: departmentCode,
      lookup: departments,
    );
    if (!deptResult.isValid) {
      throw StateError(deptResult.errorMessage ?? ImportConstants.missingImportDepartmentMessage);
    }

    final String? departmentId = await DomainDepartmentResolver.departmentIdForCode(
      orgId: context.orgId,
      departmentCode: departmentCode,
    );
    if (departmentId == null || departmentId.isEmpty) {
      throw StateError(ImportConstants.generalProblemDomainFailedMessage);
    }

    final DomainModel domain;
    try {
      domain = await DomainService.ensureGeneralProblem(
        orgId: context.orgId,
        departmentId: departmentId,
      );
    } catch (e) {
      throw StateError(
        '${ImportConstants.generalProblemDomainFailedMessage} $e',
      );
    }
    if (domain.domainId.trim().isEmpty) {
      throw StateError(ImportConstants.generalProblemDomainFailedMessage);
    }

    final List<ProblemModel> problems = await FirestoreUtils.getProblemModelsByCollege(context.orgId);
    final Map<String, ProblemModel> byIdentity = <String, ProblemModel>{};
    for (final ProblemModel problem in problems) {
      final String? key = problem.sourceIdentityKey;
      if (key == null || byIdentity.containsKey(key)) continue;
      byIdentity[key] = problem;
    }

    return _ProblemImportLookup(
      byIdentity: byIdentity,
      departmentCode: deptResult.canonicalCode ?? departmentCode,
      departmentName: (deptResult.departmentName ?? context.defaultDepartmentName).trim(),
      domainId: domain.domainId,
    );
  }
}
