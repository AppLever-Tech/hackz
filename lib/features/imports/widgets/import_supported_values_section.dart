import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../user/constants/csv_import_role_constants.dart';
import '../../user/services/user_role_labels.dart';
import '../services/import_department_lookup.dart';
import '../services/import_template_service.dart';
import 'reference_values_viewer.dart';

/// User-import reference data: allowed roles and department codes.
class ImportSupportedValuesSection extends StatefulWidget {
  const ImportSupportedValuesSection({
    super.key,
    required this.departments,
    required this.supportedRoles,
    this.loading = false,
    this.enabled = true,
  });

  final List<ImportDepartmentInfo> departments;
  final Set<String>? supportedRoles;
  final bool loading;
  final bool enabled;

  static const int _departmentSearchThreshold = 10;

  @override
  State<ImportSupportedValuesSection> createState() => _ImportSupportedValuesSectionState();
}

class _ImportSupportedValuesSectionState extends State<ImportSupportedValuesSection> {
  bool _downloadingCodes = false;

  Future<void> _downloadDepartmentCodes() async {
    if (widget.departments.isEmpty) {
      FeedbackService.showWarning(
        context,
        title: 'No departments',
        message: 'Create departments under Department Management first.',
      );
      return;
    }

    setState(() => _downloadingCodes = true);
    try {
      final ImportTemplateDownloadResult result = await ImportTemplateService.downloadTemplate(
        fileName: ImportDepartmentInfo.departmentCodesFileName,
        csvContent: ImportDepartmentLookup(departments: widget.departments).buildDepartmentCodesCsv(),
      );
      if (!mounted || result == ImportTemplateDownloadResult.cancelled) return;
      await FeedbackService.showSuccess(
        context,
        title: result == ImportTemplateDownloadResult.saved ? 'Department codes downloaded' : 'Department codes copied',
        message: result == ImportTemplateDownloadResult.saved
            ? 'Department codes CSV saved to your device.'
            : 'Department codes copied to clipboard. Paste into a spreadsheet and save as .csv',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Could not save department codes', message: '$e');
    } finally {
      if (mounted) setState(() => _downloadingCodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showRoles = widget.supportedRoles != null && widget.supportedRoles!.isNotEmpty;
    final bool canDownload = widget.enabled && !_downloadingCodes && widget.departments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Supported Values',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 4),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else ...<Widget>[
          if (showRoles)
            _ReferenceTile(
              icon: AppIcons.users,
              title: 'Supported Roles',
              onTap: () => showReferenceValuesViewer(
                context: context,
                config: _rolesConfig(widget.supportedRoles!),
              ),
            ),
          _ReferenceTile(
            icon: AppIcons.departments,
            title: 'Department Codes',
            onTap: widget.departments.isEmpty
                ? null
                : () => showReferenceValuesViewer(
                      context: context,
                      config: _departmentsConfig(widget.departments),
                    ),
            subtitle: widget.departments.isEmpty ? 'No departments found yet' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: canDownload ? _downloadDepartmentCodes : null,
              icon: const Icon(AppIcons.download, size: 16),
              label: const Text('Download Department Codes'),
            ),
          ),
        ],
      ],
    );
  }

  static ReferenceValuesViewerConfig _rolesConfig(Set<String> allowedRoles) {
    final List<ReferenceValueItem> items = CsvImportRoleConstants.all
        .where(allowedRoles.contains)
        .map((String role) {
          final String? code = CsvImportRoleConstants.toRoleCode(role);
          return ReferenceValueItem(
            primary: role,
            secondary: code == null ? null : UserRoleLabels.labelForCode(code),
          );
        })
        .toList(growable: false);
    return ReferenceValuesViewerConfig(
      title: 'Supported Roles',
      subtitle: 'Role values are case-sensitive.',
      items: items,
      enableSearch: false,
    );
  }

  static ReferenceValuesViewerConfig _departmentsConfig(List<ImportDepartmentInfo> departments) {
    final List<ReferenceValueItem> items = departments
        .map(
          (ImportDepartmentInfo d) => ReferenceValueItem(
            primary: d.code,
            secondary: d.name.isEmpty ? null : d.name,
            searchTerms: <String>[d.code, d.name],
          ),
        )
        .toList(growable: false);
    return ReferenceValuesViewerConfig(
      title: 'Department Codes',
      subtitle: 'Use department codes in CSV imports, not display names.',
      items: items,
      enableSearch: true,
      searchThreshold: ImportSupportedValuesSection._departmentSearchThreshold,
      emptyMessage: 'No departments found. Create departments under Department Management first.',
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 20, color: const Color(0xFF475569)),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onTap == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              ),
            ),
            subtitle: subtitle == null
                ? null
                : Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                  ),
            trailing: Icon(
              AppIcons.chevronRight,
              size: 18,
              color: onTap == null ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
