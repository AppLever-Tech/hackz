import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../services/import_department_lookup.dart';
import '../services/import_department_resolution_policy.dart';
import 'import_create_department_dialog.dart';

class ImportDepartmentResolutionResult {
  const ImportDepartmentResolutionResult({
    required this.mapping,
    this.saveAlias = false,
    this.reloadLookup = false,
    this.departmentCreated = false,
  });

  final ImportDepartmentMapping mapping;
  final bool saveAlias;
  final bool reloadLookup;
  final bool departmentCreated;
}

enum _DepartmentMapMode { map, assignAdmin }

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
    final bool canAssign = ImportDepartmentResolutionPolicy.canAssignAdministrator(_role);

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
            constraints: const BoxConstraints(maxHeight: 280),
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
                  canAssign: canAssign,
                  canCreate: canCreate,
                  enabled: !busy,
                  onMap: () => _openMap(context, item, _DepartmentMapMode.map),
                  onAssign: () => _openMap(context, item, _DepartmentMapMode.assignAdmin),
                  onCreate: () => _createDepartment(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(BuildContext context, ImportUnresolvedDepartment item, _DepartmentMapMode mode) async {
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
        orgId: actor.orgId,
        mode: mode,
        canSaveAlias: ImportDepartmentResolutionPolicy.canSaveAlias(_role),
        canAssignAdmin: ImportDepartmentResolutionPolicy.canAssignAdministrator(_role),
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
      ImportDepartmentResolutionResult(
        mapping: created.toMapping(),
        reloadLookup: true,
        departmentCreated: true,
      ),
    );
  }
}

class _UnresolvedDepartmentTile extends StatelessWidget {
  const _UnresolvedDepartmentTile({
    required this.item,
    required this.canMap,
    required this.canAssign,
    required this.canCreate,
    required this.enabled,
    required this.onMap,
    required this.onAssign,
    required this.onCreate,
  });

  final ImportUnresolvedDepartment item;
  final bool canMap;
  final bool canAssign;
  final bool canCreate;
  final bool enabled;
  final VoidCallback onMap;
  final VoidCallback onAssign;
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
              if (canAssign)
                OutlinedButton(
                  onPressed: enabled ? onAssign : null,
                  child: const Text('Assign Administrator'),
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
    required this.orgId,
    required this.mode,
    required this.canSaveAlias,
    required this.canAssignAdmin,
  });

  final String csvValue;
  final List<ImportDepartmentInfo> departments;
  final String orgId;
  final _DepartmentMapMode mode;
  final bool canSaveAlias;
  final bool canAssignAdmin;

  @override
  State<_MapExistingDepartmentDialog> createState() => _MapExistingDepartmentDialogState();
}

class _MapExistingDepartmentDialogState extends State<_MapExistingDepartmentDialog> {
  ImportDepartmentInfo? _selected;
  UserModel? _selectedAdmin;
  List<UserModel> _admins = const <UserModel>[];
  bool _saveAlias = false;
  bool _loadingAdmins = false;
  bool _saving = false;

  bool get _needsAdmin {
    final ImportDepartmentInfo? department = _selected;
    if (department == null) return false;
    if (department.hasAdministrator && widget.mode == _DepartmentMapMode.map) return false;
    return !department.hasAdministrator;
  }

  @override
  void initState() {
    super.initState();
    if (widget.canAssignAdmin) _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final List<UserModel> admins =
          await FirestoreUtils.listEligibleDepartmentAdministrators(orgId: widget.orgId);
      if (!mounted) return;
      setState(() {
        _admins = admins;
        _loadingAdmins = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
    }
  }

  Future<void> _submit() async {
    final ImportDepartmentInfo? department = _selected;
    if (department == null) return;
    final bool assignAdmin = _needsAdmin;

    if (assignAdmin && !widget.canAssignAdmin) {
      FeedbackService.showWarning(
        context,
        title: 'Administrator required',
        message: ImportConstants.coordinatorCannotAssignAdminMessage,
      );
      return;
    }

    if (assignAdmin) {
      final UserModel? admin = _selectedAdmin;
      if (admin == null || !UserRole.isEligibleDepartmentAdministrator(admin.role)) {
        FeedbackService.showWarning(
          context,
          title: 'Administrator required',
          message: ImportConstants.departmentAdminAssignRequiredMessage,
        );
        return;
      }
      if (department.id.trim().isEmpty) {
        FeedbackService.showWarning(
          context,
          title: 'Department required',
          message: 'Select a department that can be assigned an administrator.',
        );
        return;
      }
      setState(() => _saving = true);
      try {
        await FirestoreUtils.setDepartmentAdmin(
          departmentId: department.id,
          adminUserId: admin.userId,
        );
      } catch (e) {
        if (!mounted) return;
        FeedbackService.showError(context, title: 'Could not assign administrator', message: '$e');
        setState(() => _saving = false);
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      ImportDepartmentResolutionResult(
        mapping: department.toMapping(),
        saveAlias: _saveAlias,
        reloadLookup: _saveAlias || assignAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool assignMode = widget.mode == _DepartmentMapMode.assignAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(AppIcons.departments, color: Color(0xFF6A38FF), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                assignMode ? 'Assign administrator' : 'Map to existing department',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
          enabled: !_saving,
          labelBuilder: (ImportDepartmentInfo d) => d.displayLabel,
          onChanged: (ImportDepartmentInfo d) => setState(() {
            _selected = d;
            _selectedAdmin = null;
          }),
        ),
        if (_needsAdmin) ...<Widget>[
          const SizedBox(height: 12),
          HackzInputDecoration.fieldLabel('Department administrator', required: true),
          const SizedBox(height: 6),
          if (_loadingAdmins)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_admins.isEmpty)
            const Text(
              ImportConstants.departmentAdminAssignRequiredMessage,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
            )
          else
            HackzSelectField<UserModel>(
              value: _selectedAdmin,
              options: _admins,
              enabled: !_saving,
              compact: true,
              hint: 'Select Department Admin or College Admin',
              labelBuilder: (UserModel user) =>
                  '${userDisplayName(user)} · ${UserRoleLabels.labelForCode(user.role)}',
              onChanged: (UserModel user) => setState(() => _selectedAdmin = user),
            ),
        ],
        if (widget.canSaveAlias) ...<Widget>[
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            value: _saveAlias,
            onChanged: _saving ? null : (bool? value) => setState(() => _saveAlias = value ?? false),
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
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _selected == null ||
                      _saving ||
                      (_needsAdmin && (!widget.canAssignAdmin || _selectedAdmin == null))
                  ? null
                  : _submit,
              child: Text(assignMode ? 'Assign' : 'Map'),
            ),
          ],
        ),
      ],
    );
  }
}
