import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/domain_model.dart';
import '../../domain/services/domain_department_resolver.dart';
import '../../domain/services/domain_service.dart';
import '../../problems/constants/problem_constants.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/models/problem_statement_source.dart';
import '../../problems/models/problem_status.dart';
import '../../problems/services/problem_utils.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../models/import_created_source.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_type.dart';
import 'csv_parser_service.dart';
import 'import_department_lookup.dart';
import 'import_department_validator.dart';
import 'import_handler.dart';

class ProblemsImportHandler implements ImportHandler {
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
  String get columnGuidance =>
      'Required: title, description. Theme defaults to Miscellaneous when blank. '
      'Issuer fields are optional. Category is always Software; you can change it after import. '
      'Organisation, department, domain, and source come from this screen — not the CSV.';

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    final ProblemsImportHandlerContext problemContext = _requireContext(context);
    final _ProblemImportLookup lookup = await _ProblemImportLookup.load(problemContext);

    final Set<String> titlesInFile = <String>{};
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
      final String externalProblemId =
          CsvParserService.cell(row, ImportConstants.externalProblemIdColumnKey);

      final List<String> issues = <String>[];
      ImportRowSeverity severity = ImportRowSeverity.valid;
      var importable = true;
      String statusLabel = 'Valid';

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
            ImportConstants.titleColumnKey: title,
            ImportConstants.descriptionColumnKey: description,
            ImportConstants.themeColumnKey: themeRaw,
            ImportConstants.issuingOrganisationColumnKey: issuingOrganisation,
            ImportConstants.issuingDepartmentColumnKey: issuingDepartment,
            ImportConstants.externalProblemIdColumnKey: externalProblemId,
          },
          severity: severity,
          statusLabel: statusLabel,
          messages: issues,
          importable: importable,
          metadata: <String, String>{
            'departmentCode': lookup.departmentCode,
            if (lookup.departmentName.isNotEmpty) 'departmentName': lookup.departmentName,
            'domainId': lookup.domainId,
            'category': ProblemConstants.categorySoftware,
            'source': problemContext.problemSource.value,
            'theme': theme,
            if (themeRaw.isNotEmpty ||
                issuingOrganisation.isNotEmpty ||
                issuingDepartment.isNotEmpty ||
                externalProblemId.isNotEmpty)
              'expandable': '1',
            if (issuingOrganisation.isNotEmpty) 'issuingOrganisation': issuingOrganisation,
            if (issuingDepartment.isNotEmpty) 'issuingDepartment': issuingDepartment,
            if (externalProblemId.isNotEmpty) 'externalProblemId': externalProblemId,
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
    final ProblemsImportHandlerContext problemContext = _requireContext(context);
    final List<ImportReviewRow> importable =
        rows.where((ImportReviewRow r) => r.importable).toList(growable: false);

    var imported = 0;
    var skipped = rows.length - importable.length;
    var failed = 0;
    final List<String> failures = <String>[];

    for (final ImportReviewRow row in importable) {
      try {
        final String departmentCode =
            row.metadata['departmentCode'] ?? problemContext.defaultDepartmentCode;
        final String domainId = row.metadata['domainId'] ?? '';
        if (domainId.isEmpty) {
          throw StateError(ImportConstants.generalProblemDomainFailedMessage);
        }
        final String problemId =
            FirebaseFirestore.instance.collection(FirestoreUtils.hkzProblems).doc().id;
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
          category: ProblemConstants.categorySoftware,
          theme: (row.metadata['theme'] ?? '').trim().isEmpty
              ? ProblemConstants.defaultTheme
              : row.metadata['theme']!.trim(),
          tags: const <String>[],
          attachments: const <String>[],
          status: ProblemStatus.draft,
          createdAt: DateTime.now(),
          createdSource: ImportCreatedSource.csvImport.value,
          source: row.metadata['source'] ?? problemContext.problemSource.value,
          issuingOrganisation: row.valueFor(ImportConstants.issuingOrganisationColumnKey),
          issuingDepartment: row.valueFor(ImportConstants.issuingDepartmentColumnKey),
          externalProblemId: row.valueFor(ImportConstants.externalProblemIdColumnKey),
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
  });

  final String orgName;
  final String orgType;
  final bool lockDepartment;
  final ProblemStatementSource problemSource;

  ProblemsImportHandlerContext copyWith({
    String? defaultDepartmentName,
    String? defaultDepartmentCode,
    String? orgName,
    ProblemStatementSource? problemSource,
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
    );
  }
}

class _ProblemImportLookup {
  _ProblemImportLookup({
    required this.existingTitles,
    required this.departmentCode,
    required this.departmentName,
    required this.domainId,
  });

  final Set<String> existingTitles;
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

    return _ProblemImportLookup(
      existingTitles: problems
          .map((ProblemModel p) => p.title.trim().toLowerCase())
          .where((String t) => t.isNotEmpty)
          .toSet(),
      departmentCode: deptResult.canonicalCode ?? departmentCode,
      departmentName: (deptResult.departmentName ?? context.defaultDepartmentName).trim(),
      domainId: domain.domainId,
    );
  }
}
