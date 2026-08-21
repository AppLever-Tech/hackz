import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_async_loader.dart';
import '../../../utils/firestore_utils.dart';
import '../../../features/docs/widgets/help_action_button.dart';
import '../../problems/models/problem_statement_source.dart';
import '../constants/import_constants.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_summary.dart';
import '../models/import_type.dart';
import '../services/csv_parser_service.dart';
import '../services/import_department_lookup.dart';
import '../services/import_handler.dart';
import '../services/import_platform_support.dart';
import '../services/import_registry.dart';
import '../services/import_template_service.dart';
import '../services/problems_import_handler.dart';
import '../widgets/import_problem_context_section.dart';
import '../widgets/import_review_table.dart';
import '../widgets/import_summary_metrics.dart';
import '../widgets/import_supported_values_section.dart';

enum _ImportStep { template, review, result }

class ImportWorkflowDialog extends StatefulWidget {
  const ImportWorkflowDialog({
    super.key,
    required this.handler,
    required this.contextData,
  });

  final ImportHandler handler;
  final ImportHandlerContext contextData;

  @override
  State<ImportWorkflowDialog> createState() => _ImportWorkflowDialogState();
}

class _ImportWorkflowDialogState extends State<ImportWorkflowDialog> {
  _ImportStep _step = _ImportStep.template;
  bool _busy = false;
  String? _fileName;
  List<ImportReviewRow> _rows = const <ImportReviewRow>[];
  ImportSummary? _summary;
  ImportExecutionResult? _result;
  ImportDepartmentLookup? _departments;
  bool _lookupsLoading = true;
  String _orgName = '';
  String _selectedDepartmentCode = '';
  String _selectedDepartmentName = '';
  ProblemStatementSource _problemSource = ProblemStatementSource.internal;

  ImportHandler get _handler => widget.handler;
  bool get _isProblemsImport => _handler.type == ImportType.problems;
  ProblemsImportHandlerContext? get _problemContext =>
      widget.contextData is ProblemsImportHandlerContext
          ? widget.contextData as ProblemsImportHandlerContext
          : null;

  bool get _hasDepartment => _selectedDepartmentCode.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final ProblemsImportHandlerContext? problemContext = _problemContext;
    _orgName = problemContext?.orgName.trim().isNotEmpty == true
        ? problemContext!.orgName.trim()
        : widget.contextData.orgId;
    _selectedDepartmentCode = widget.contextData.defaultDepartmentCode.trim().toUpperCase();
    _selectedDepartmentName = widget.contextData.defaultDepartmentName.trim();
    _problemSource = problemContext?.problemSource ?? ProblemStatementSource.internal;
    _loadReferenceLookups();
  }

  Future<void> _loadReferenceLookups() async {
    try {
      final ImportDepartmentLookup deptLookup =
          await ImportDepartmentLookup.load(widget.contextData.orgId);
      String orgName = _orgName;
      if (_isProblemsImport) {
        final org = await FirestoreUtils.fetchOrganization(widget.contextData.orgId);
        final String fetched = (org?.name ?? '').trim();
        if (fetched.isNotEmpty) orgName = fetched;
      }
      if (_selectedDepartmentName.isEmpty && _selectedDepartmentCode.isNotEmpty) {
        _selectedDepartmentName = deptLookup.codeToName[_selectedDepartmentCode] ?? '';
      }
      if (!mounted) return;
      setState(() {
        _departments = deptLookup;
        _orgName = orgName;
        _lookupsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _lookupsLoading = false);
    }
  }

  ImportHandlerContext _effectiveContext() {
    final ProblemsImportHandlerContext? problemContext = _problemContext;
    if (problemContext == null) return widget.contextData;
    return problemContext.copyWith(
      defaultDepartmentCode: _selectedDepartmentCode,
      defaultDepartmentName: _selectedDepartmentName,
      orgName: _orgName,
      problemSource: _problemSource,
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final ImportTemplateDownloadResult result = await ImportTemplateService.downloadTemplate(
        fileName: _handler.templateFileName,
        csvContent: _handler.templateCsv,
      );
      if (!mounted || result == ImportTemplateDownloadResult.cancelled) return;
      await FeedbackService.showSuccess(
        context,
        title: result == ImportTemplateDownloadResult.saved ? 'Template downloaded' : 'Template copied',
        message: result == ImportTemplateDownloadResult.saved
            ? 'CSV template saved to your device.'
            : 'CSV template copied to clipboard. Paste into a spreadsheet and save as .csv',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Could not save template', message: '$e');
    }
  }

  Future<void> _pickCsv() async {
    if (_isProblemsImport && !_hasDepartment) {
      FeedbackService.showWarning(
        context,
        title: 'Department required',
        message: ImportConstants.missingImportDepartmentMessage,
      );
      return;
    }

    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
      withData: true,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final PlatformFile file = picked.files.first;
    final List<int>? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      FeedbackService.showWarning(context, title: 'Upload failed', message: 'Could not read the selected CSV file.');
      return;
    }

    setState(() => _busy = true);
    try {
      final List<Map<String, String>> parsed = CsvParserService.parseBytes(bytes);
      if (parsed.isEmpty) {
        if (!mounted) return;
        FeedbackService.showWarning(context, title: 'Empty file', message: 'No data rows found in the CSV.');
        return;
      }

      final List<ImportReviewRow> validated = await _handler.validateRows(parsed, _effectiveContext());
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _rows = validated;
        _summary = _handler.summarize(validated);
        _step = _ImportStep.review;
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Validation failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImport() async {
    final List<ImportReviewRow> importable =
        _rows.where((ImportReviewRow r) => r.importable).toList(growable: false);
    if (importable.isEmpty) {
      FeedbackService.showWarning(
        context,
        title: 'Nothing to import',
        message: 'No valid rows are ready for import.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final ImportExecutionResult result = await HkzAsyncLoader.run<ImportExecutionResult>(
        context,
        title: 'Importing',
        message: 'Creating ${importable.length} record${importable.length == 1 ? '' : 's'}...',
        task: () => _handler.executeImport(_rows, _effectiveContext()),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = _ImportStep.result;
      });
      if (result.imported > 0) {
        FeedbackService.showSuccess(
          context,
          title: 'Import complete',
          message: 'Imported ${result.imported}, skipped ${result.skipped}, failed ${result.failed}.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Import failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _handler.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                _step == _ImportStep.template
                    ? 'Download the template, fill it in, then upload for validation.'
                    : _step == _ImportStep.review
                        ? 'Review validated rows before importing.'
                        : 'Import completed.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ),
            const HelpActionButton(pageId: 'csv-import'),
            if (_step == _ImportStep.template) ...<Widget>[
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: _busy || (_isProblemsImport && !_hasDepartment) ? null : _pickCsv,
                icon: const Icon(AppIcons.attachments, size: 16),
                label: Text(compact ? 'Upload' : 'Upload CSV'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 10),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_busy) const SizedBox(height: 10),
        Expanded(child: _buildBody()),
        const SizedBox(height: 12),
        _buildActions(),
      ],
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      _ImportStep.template => _buildTemplateStep(),
      _ImportStep.review => _buildReviewStep(),
      _ImportStep.result => _buildResultStep(),
    };
  }

  Widget _buildTemplateStep() {
    return ListView(
      children: <Widget>[
        if (_isProblemsImport) ...<Widget>[
          ImportProblemContextSection(
            orgName: _orgName,
            departmentCode: _selectedDepartmentCode,
            departmentName: _selectedDepartmentName,
            lockDepartment: _problemContext?.lockDepartment ?? false,
            departments: _departments?.departments ?? const <ImportDepartmentInfo>[],
            source: _problemSource,
            loading: _lookupsLoading,
            enabled: !_busy,
            onDepartmentChanged: (ImportDepartmentInfo dept) {
              setState(() {
                _selectedDepartmentCode = dept.code;
                _selectedDepartmentName = dept.name;
              });
            },
            onSourceChanged: (ProblemStatementSource source) {
              setState(() => _problemSource = source);
            },
          ),
          const SizedBox(height: 12),
        ] else ...<Widget>[
          ImportSupportedValuesSection(
            departments: _departments?.departments ?? const <ImportDepartmentInfo>[],
            supportedRoles: widget.contextData.supportedCsvRoles,
            loading: _lookupsLoading,
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Download template',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Text(
                ImportConstants.requiredColumnsHint(_handler.requiredHeaders),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              if (_handler.columnGuidance.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  _handler.columnGuidance,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _downloadTemplate,
                icon: const Icon(AppIcons.download, size: 16),
                label: const Text('Download CSV Template'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final ImportSummary summary = _summary ?? _handler.summarize(_rows);
    final List<ImportReviewColumn> columns = _handler.reviewHeaders
        .map((String h) => ImportReviewColumn(key: h, label: ImportConstants.headerLabel(h)))
        .toList(growable: false);
    final List<ImportReviewColumn> expansionColumns = _handler.expansionHeaders
        .map((String h) => ImportReviewColumn(key: h, label: ImportConstants.headerLabel(h)))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'File: $_fileName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
        ImportSummaryMetrics(summary: summary),
        const SizedBox(height: 12),
        Expanded(
          child: ImportReviewTable(rows: _rows, columns: columns, expansionColumns: expansionColumns),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final ImportExecutionResult result = _result ?? const ImportExecutionResult(imported: 0, skipped: 0, failed: 0);
    return ListView(
      children: <Widget>[
        ImportSummaryMetrics(
          summary: ImportSummary(
            totalRows: result.totalProcessed,
            validRows: result.imported,
            warningRows: result.skipped,
            errorRows: result.failed,
            skippedRows: result.skipped,
          ),
        ),
        const SizedBox(height: 12),
        _resultTile('Imported', result.imported, const Color(0xFF047857)),
        _resultTile('Skipped', result.skipped, const Color(0xFFB45309)),
        _resultTile('Failed', result.failed, const Color(0xFFB91C1C)),
        if (result.failures.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text('Failures', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...result.failures.map(
            (String f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(f, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultTile(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const Spacer(),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  bool get _canImport {
    final ImportSummary? summary = _summary;
    if (summary == null) return false;
    if (summary.validRows <= 0) return false;
    if (_handler.blockImportOnAnyError && summary.errorRows > 0) return false;
    return true;
  }

  Widget _buildActions() {
    return Row(
      children: <Widget>[
        const Spacer(),
        if (_step == _ImportStep.review) ...<Widget>[
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _step = _ImportStep.template;
                      _rows = const <ImportReviewRow>[];
                      _summary = null;
                      _fileName = null;
                    }),
            child: const Text('Back'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy || !_canImport ? null : _runImport,
            child: Text('Import ${_summary?.validRows ?? 0}'),
          ),
          const SizedBox(width: 8),
        ],
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).pop(
                    _step == _ImportStep.result && (_result?.imported ?? 0) > 0,
                  ),
          child: Text(_step == _ImportStep.result ? 'Close' : 'Cancel'),
        ),
      ],
    );
  }
}

/// Opens the shared CSV import workflow for [type] (tablet and desktop/web only).
Future<bool?> showImportWorkflow({
  required BuildContext context,
  required ImportType type,
  required ImportHandlerContext contextData,
}) {
  if (!ImportPlatformSupport.isSupported(context)) {
    return Future<bool?>.value(null);
  }

  final ImportHandler handler = ImportRegistry.handlerFor(type);
  final bool mobile = ResponsiveHelper.isMobile(context);
  final double dialogHeight = mobile
      ? (MediaQuery.sizeOf(context).height * 0.86).clamp(420.0, 720.0)
      : 560;
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    width: DialogWidthPreset.wide,
    maxWidth: 980,
    child: SizedBox(
      height: dialogHeight,
      child: ImportWorkflowDialog(handler: handler, contextData: contextData),
    ),
  );
}
