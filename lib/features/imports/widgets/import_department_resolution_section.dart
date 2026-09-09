import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/import_department_lookup.dart';
import '../services/import_department_resolution_policy.dart';
import 'import_create_department_dialog.dart';

class ImportDepartmentResolutionResult {
  const ImportDepartmentResolutionResult({
    required this.mapping,
    this.saveAlias = false,
    this.reloadLookup = false,
  });

  final ImportDepartmentMapping mapping;
  final bool saveAlias;
  final bool reloadLookup;
}

/// Compact unresolved-department list shown before CSV user/team import.
class ImportDepartmentResolutionSection extends StatelessWidget {
  const ImportDepartmentResolutionSection({
    super.key,
    required this.unresolved,
    required this.departments,
    required this.actor,
    required this.busy,
    required this.onResolved,
  });

  final List<ImportUnresolvedDepartment> unresolved;
  final List<ImportDepartmentInfo> departments;
  final UserModel actor;
  final bool busy;
  final Future<void> Function(String rawValue, ImportDepartmentResolutionResult result) onResolved;

  UserRole get _role => UserRole.fromCode(actor.role);

  @override
  Widget build(BuildContext context) {
    if (unresolved.isEmpty) return const SizedBox.shrink();
    final bool canMap = ImportDepartmentResolutionPolicy.canMap(_role);
    final bool canCreate = ImportDepartmentResolutionPolicy.canCreateDepartment(_role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Unresolved departments',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF9A3412)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Import is blocked until every department value is mapped. No records will be imported.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: unresolved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final ImportUnresolvedDepartment item = unresolved[index];
                return _UnresolvedDepartmentTile(
                  item: item,
                  canMap: canMap,
                  canCreate: canCreate,
                  enabled: !busy,
                  onMap: () => _mapExisting(context, item),
                  onCreate: () => _createDepartment(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mapExisting(BuildContext context, ImportUnresolvedDepartment item) async {
    if (departments.isEmpty) {
      FeedbackService.showWarning(
        context,
        title: 'No departments',
        message: ImportDepartmentResolutionPolicy.canCreateDepartment(_role)
            ? 'Create a department for this value, or add one under Department Management.'
            : 'Ask a College Admin to create the department, or map to an existing department if one is available.',
      );
      return;
    }
    final ImportDepartmentResolutionResult? result = await showAppDialog<ImportDepartmentResolutionResult>(
      context: context,
      width: DialogWidthPreset.compact,
      child: _MapExistingDepartmentDialog(
        csvValue: item.rawValue,
        departments: departments,
        canSaveAlias: ImportDepartmentResolutionPolicy.canSaveAlias(_role),
      ),
    );
    if (result == null) return;
    await onResolved(item.rawValue, result);
  }

  Future<void> _createDepartment(BuildContext context, ImportUnresolvedDepartment item) async {
    final ImportDepartmentInfo? created = await showImportCreateDepartmentDialog(
      context: context,
      actor: actor,
      csvValue: item.rawValue,
      lookup: ImportDepartmentLookup(departments: departments),
    );
    if (created == null) return;
    await onResolved(
      item.rawValue,
      ImportDepartmentResolutionResult(mapping: created.toMapping(), reloadLookup: true),
    );
  }
}

class _UnresolvedDepartmentTile extends StatelessWidget {
  const _UnresolvedDepartmentTile({
    required this.item,
    required this.canMap,
    required this.canCreate,
    required this.enabled,
    required this.onMap,
    required this.onCreate,
  });

  final ImportUnresolvedDepartment item;
  final bool canMap;
  final bool canCreate;
  final bool enabled;
  final VoidCallback onMap;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.rawValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          Text(
            'No existing match · ${item.rowCount} row${item.rowCount == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (canMap)
                OutlinedButton(
                  onPressed: enabled ? onMap : null,
                  child: const Text('Map to Existing'),
                ),
              if (canCreate)
                FilledButton(
                  onPressed: enabled ? onCreate : null,
                  child: const Text('Create Department'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapExistingDepartmentDialog extends StatefulWidget {
  const _MapExistingDepartmentDialog({
    required this.csvValue,
    required this.departments,
    required this.canSaveAlias,
  });

  final String csvValue;
  final List<ImportDepartmentInfo> departments;
  final bool canSaveAlias;

  @override
  State<_MapExistingDepartmentDialog> createState() => _MapExistingDepartmentDialogState();
}

class _MapExistingDepartmentDialogState extends State<_MapExistingDepartmentDialog> {
  ImportDepartmentInfo? _selected;
  bool _saveAlias = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(AppIcons.departments, color: Color(0xFF6A38FF), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Map to existing department',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.csvValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 12),
        HackzSelectField<ImportDepartmentInfo>(
          value: _selected,
          options: widget.departments,
          compact: true,
          hint: 'Select department',
          labelBuilder: (ImportDepartmentInfo d) => d.displayLabel,
          onChanged: (ImportDepartmentInfo d) => setState(() => _selected = d),
        ),
        if (widget.canSaveAlias) ...<Widget>[
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            value: _saveAlias,
            onChanged: (bool? value) => setState(() => _saveAlias = value ?? false),
            title: const Text(
              'Save this value as a department alias',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(
                        ImportDepartmentResolutionResult(
                          mapping: _selected!.toMapping(),
                          saveAlias: _saveAlias,
                          reloadLookup: _saveAlias,
                        ),
                      ),
              child: const Text('Map'),
            ),
          ],
        ),
      ],
    );
  }
}
