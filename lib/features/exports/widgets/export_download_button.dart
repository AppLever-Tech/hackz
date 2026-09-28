import 'package:flutter/material.dart';

import '../../../core/download/hackz_file_download.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/icon_only_filter_button.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';
import '../models/export_exception.dart';
import '../models/export_format.dart';
import '../models/export_request.dart';
import '../services/export_data_provider.dart';
import '../services/export_service.dart';

/// Compact Download / Export control for list and event toolbars.
class ExportDownloadButton extends StatefulWidget {
  const ExportDownloadButton({
    super.key,
    required this.provider,
    required this.requestFor,
    this.labeled = true,
    this.label = 'Download',
  });

  final ExportDataProvider provider;
  final ExportRequest Function(ExportFormat format) requestFor;
  final bool labeled;
  final String label;

  @override
  State<ExportDownloadButton> createState() => _ExportDownloadButtonState();
}

class _ExportDownloadButtonState extends State<ExportDownloadButton> {
  bool _busy = false;

  List<ExportFormat> get _formats => widget.provider.supportedFormats;

  Future<void> _run(ExportFormat format) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final HackzFileDownloadResult result = await ExportService.export(
        request: widget.requestFor(format),
        provider: widget.provider,
      );
      if (!mounted || result == HackzFileDownloadResult.cancelled) return;
      await FeedbackService.showSuccess(
        context,
        title: 'Download ready',
        message: result == HackzFileDownloadResult.copied
            ? 'Export copied to the clipboard.'
            : '${format.label} file saved to your device.',
      );
    } on ExportException catch (error) {
      if (!mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Unable to download',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Unable to download',
        message: '$error',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_formats.isEmpty) return const SizedBox.shrink();
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: HkzProgressIndicator(size: 22, strokeWidth: 2.4),
      );
    }
    if (_formats.length == 1) {
      return _single(_formats.first);
    }
    return _menu();
  }

  Widget _single(ExportFormat format) {
    if (!widget.labeled) {
      return IconOnlyFilterButton(
        icon: AppIcons.download,
        tooltip: 'Download ${format.label}',
        selected: false,
        color: const Color(0xFF4A67FF),
        onTap: () => _run(format),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _run(format),
      icon: const Icon(AppIcons.download, size: MobileToolbarButtonStyles.toolbarIconSize),
      label: Text(widget.label),
      style: MobileToolbarButtonStyles.outlined(compact: true),
    );
  }

  Widget _menu() {
    return HackzPopupMenuButton(
      tooltip: widget.label,
      minWidth: 180,
      actions: _formats
          .map(
            (ExportFormat format) => HackzMenuAction(
              value: format.name,
              icon: format == ExportFormat.pdf ? AppIcons.attachmentPdf : AppIcons.spreadsheet,
              label: format.label,
            ),
          )
          .toList(growable: false),
      onSelected: (String value) {
        final ExportFormat format = _formats.firstWhere((ExportFormat item) => item.name == value);
        _run(format);
      },
      child: widget.labeled ? _labeledShell() : _iconShell(),
    );
  }

  Widget _labeledShell() {
    return Container(
      height: MobileToolbarButtonStyles.compactHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: MobileToolbarButtonStyles.compactHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: MobileToolbarButtonStyles.separatorColor, width: 1.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(AppIcons.download, size: MobileToolbarButtonStyles.toolbarIconSize, color: Color(0xFF334155)),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _iconShell() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Icon(AppIcons.download, size: 16, color: Color(0xFF475569)),
    );
  }
}
