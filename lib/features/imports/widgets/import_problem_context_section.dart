import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../problems/models/problem_statement_source.dart';
import '../services/import_department_lookup.dart';
import '../sources/problem_import_source_kind.dart';

/// Organisation, department, and import-from source for problem import.
class ImportProblemContextSection extends StatelessWidget {
  const ImportProblemContextSection({
    super.key,
    required this.orgName,
    required this.departmentCode,
    required this.departmentName,
    required this.lockDepartment,
    required this.departments,
    required this.importSource,
    required this.problemSource,
    required this.onDepartmentChanged,
    required this.onImportSourceChanged,
    required this.onProblemSourceChanged,
    this.loading = false,
    this.enabled = true,
  });

  final String orgName;
  final String departmentCode;
  final String departmentName;
  final bool lockDepartment;
  final List<ImportDepartmentInfo> departments;
  final ProblemImportSourceKind importSource;
  final ProblemStatementSource problemSource;
  final ValueChanged<ImportDepartmentInfo> onDepartmentChanged;
  final ValueChanged<ProblemImportSourceKind> onImportSourceChanged;
  final ValueChanged<ProblemStatementSource> onProblemSourceChanged;
  final bool loading;
  final bool enabled;

  static const double _stackBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stack = !constraints.hasBoundedWidth ||
                    constraints.maxWidth < _stackBreakpoint;
                final Widget department = _labeledField(
                  icon: AppIcons.departments,
                  label: 'Department',
                  field: lockDepartment ? _readOnlyValue(_departmentDisplay, locked: true) : _departmentSelect(),
                );
                final Widget importFrom = _labeledField(
                  icon: AppIcons.attachments,
                  label: 'Import from',
                  field: _importSourceSelect(),
                );
                final Widget organisation = _labeledField(
                  icon: AppIcons.organizations,
                  label: 'Organisation',
                  field: _readOnlyValue(orgName.trim().isEmpty ? '—' : orgName.trim()),
                );
                final Widget? csvSource = importSource == ProblemImportSourceKind.csv
                    ? _labeledField(
                        icon: Icons.public_outlined,
                        label: 'Source',
                        field: _csvSourceSelect(),
                      )
                    : null;

                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      department,
                      const SizedBox(height: 10),
                      importFrom,
                      if (csvSource != null) ...<Widget>[
                        const SizedBox(height: 10),
                        csvSource,
                      ],
                      const SizedBox(height: 10),
                      organisation,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(child: department),
                        const SizedBox(width: 16),
                        Expanded(child: importFrom),
                      ],
                    ),
                    if (csvSource != null) ...<Widget>[
                      const SizedBox(height: 10),
                      csvSource,
                    ],
                    const SizedBox(height: 10),
                    organisation,
                  ],
                );
              },
            ),
    );
  }

  Widget _labeledField({
    required IconData icon,
    required String label,
    required Widget field,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(label, style: HackzInputDecoration.labelStyle),
        const SizedBox(width: 6),
        Expanded(child: field),
      ],
    );
  }

  Widget _departmentSelect() {
    return HackzSelectField<String>(
      value: departmentCode.trim().isEmpty ? null : departmentCode.trim().toUpperCase(),
      hint: departments.isEmpty ? 'No departments found' : 'Select a department',
      enabled: enabled && departments.isNotEmpty,
      options: departments.map((ImportDepartmentInfo d) => d.code).toList(growable: false),
      labelBuilder: (String code) {
        final ImportDepartmentInfo match = departments.firstWhere(
          (ImportDepartmentInfo d) => d.code == code,
          orElse: () => ImportDepartmentInfo(code: code, name: code),
        );
        return match.displayLabel;
      },
      iconBuilder: (_) => AppIcons.departments,
      onChanged: (String code) {
        final ImportDepartmentInfo match = departments.firstWhere(
          (ImportDepartmentInfo d) => d.code == code,
          orElse: () => ImportDepartmentInfo(code: code, name: code),
        );
        onDepartmentChanged(match);
      },
    );
  }

  Widget _importSourceSelect() {
    return HackzSelectField<ProblemImportSourceKind>(
      value: importSource,
      hint: 'Select source',
      enabled: enabled,
      options: ProblemImportSourceKind.values,
      labelBuilder: (ProblemImportSourceKind kind) => kind.label,
      iconBuilder: (ProblemImportSourceKind kind) => kind.icon,
      onChanged: onImportSourceChanged,
    );
  }

  Widget _csvSourceSelect() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ProblemStatementSource>(
        showSelectedIcon: false,
        segments: const <ButtonSegment<ProblemStatementSource>>[
          ButtonSegment<ProblemStatementSource>(
            value: ProblemStatementSource.internal,
            label: Text('Internal'),
          ),
          ButtonSegment<ProblemStatementSource>(
            value: ProblemStatementSource.external,
            label: Text('External'),
          ),
        ],
        selected: <ProblemStatementSource>{problemSource},
        onSelectionChanged: (Set<ProblemStatementSource> next) {
          if (!enabled || next.isEmpty) return;
          onProblemSourceChanged(next.first);
        },
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _readOnlyValue(String value, {bool locked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          if (locked) const Icon(AppIcons.lock, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  String get _departmentDisplay {
    if (departmentName.trim().isNotEmpty && departmentCode.trim().isNotEmpty) {
      return '${departmentName.trim()} (${departmentCode.trim().toUpperCase()})';
    }
    if (departmentName.trim().isNotEmpty) return departmentName.trim();
    if (departmentCode.trim().isNotEmpty) return departmentCode.trim().toUpperCase();
    return '—';
  }
}
