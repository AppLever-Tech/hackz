import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../screens/common/app_dialog_template.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../widgets/loading/hkz_async_loader.dart';
import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_summary.dart';
import '../models/import_type.dart';
import '../services/csv_parser_service.dart';
import '../services/import_handler.dart';
import '../services/import_registry.dart';
import '../services/import_template_service.dart';
import '../widgets/import_review_mobile_list.dart';
import '../widgets/import_review_table.dart';
import '../widgets/import_summary_metrics.dart';

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

  ImportHandler get _handler => widget.handler;

  Future<void> _downloadTemplate() async {
    final bool saved = await ImportTemplateService.downloadTemplate(
      fileName: _handler.templateFileName,
      csvContent: _handler.templateCsv,
    );
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: saved ? 'Template downloaded' : 'Template copied',
      message: saved
          ? 'CSV template saved to your device.'
          : 'CSV template copied to clipboard. Paste into a spreadsheet and save as .csv',
    );
  }

  Future<void> _pickCsv() async {
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

      final List<ImportReviewRow> validated = await _handler.validateRows(parsed, widget.contextData);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _rows = validated;
        _summary = ImportSummary.fromRows(validated);
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
        task: () => _handler.executeImport(_rows, widget.contextData),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _handler.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          _step == _ImportStep.template
              ? 'Download the template, fill it in, then upload for validation.'
              : _step == _ImportStep.review
                  ? 'Review validated rows before importing.'
                  : 'Import completed.',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
                'Step 1 · Download template',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Required columns: name, email, phone, role, department',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _downloadTemplate,
                icon: const Icon(AppIcons.download, size: 16),
                label: const Text('Download Template'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Step 2 · Upload CSV',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rows are validated before import. Invalid rows are excluded automatically.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy ? null : _pickCsv,
                icon: const Icon(AppIcons.attachments, size: 16),
                label: const Text('Upload CSV'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final ImportSummary summary = _summary ?? ImportSummary.fromRows(_rows);
    final bool isMobile = ResponsiveHelper.isMobile(context);
    final List<ImportReviewColumn> columns = _handler.requiredHeaders
        .map((String h) => ImportReviewColumn(key: h, label: _labelFor(h)))
        .toList(growable: false);

    return ListView(
      children: <Widget>[
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'File: $_fileName',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
        ImportSummaryMetrics(summary: summary),
        const SizedBox(height: 12),
        if (isMobile)
          ImportReviewMobileList(rows: _rows)
        else
          ImportReviewTable(rows: _rows, columns: columns),
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

  Widget _buildActions() {
    return Row(
      children: <Widget>[
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).pop(
                    _step == _ImportStep.result && (_result?.imported ?? 0) > 0,
                  ),
          child: Text(_step == _ImportStep.result ? 'Close' : 'Cancel'),
        ),
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
            onPressed: _busy || (_summary?.validRows ?? 0) == 0 ? null : _runImport,
            child: Text('Import ${_summary?.validRows ?? 0}'),
          ),
        ],
      ],
    );
  }

  String _labelFor(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }
}

/// Opens the shared CSV import workflow for [type].
Future<bool?> showImportWorkflow({
  required BuildContext context,
  required ImportType type,
  required ImportHandlerContext contextData,
}) {
  final ImportHandler handler = ImportRegistry.handlerFor(type);
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    width: DialogWidthPreset.wide,
    maxWidth: 980,
    child: SizedBox(
      height: ResponsiveHelper.isMobile(context) ? 520 : 560,
      child: ImportWorkflowDialog(handler: handler, contextData: contextData),
    ),
  );
}
