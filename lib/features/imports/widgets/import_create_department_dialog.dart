import 'package:flutter/material.dart';

import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../domain/services/domain_service.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/screens/create_user_dialog.dart';
import '../../user/services/user_role_labels.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../constants/import_constants.dart';
import '../services/import_department_lookup.dart';

/// College Admin: create a department from an unresolved CSV value, with a required administrator.
Future<ImportDepartmentInfo?> showImportCreateDepartmentDialog({
  required BuildContext context,
  required UserModel actor,
  required String csvValue,
  required ImportDepartmentLookup lookup,
}) {
  return showAppDialog<ImportDepartmentInfo>(
    context: context,
    width: DialogWidthPreset.standard,
    child: _ImportCreateDepartmentDialog(
      actor: actor,
      csvValue: csvValue,
      lookup: lookup,
    ),
  );
}

class _ImportCreateDepartmentDialog extends StatefulWidget {
  const _ImportCreateDepartmentDialog({
    required this.actor,
    required this.csvValue,
    required this.lookup,
  });

  final UserModel actor;
  final String csvValue;
  final ImportDepartmentLookup lookup;

  @override
  State<_ImportCreateDepartmentDialog> createState() => _ImportCreateDepartmentDialogState();
}

class _ImportCreateDepartmentDialogState extends State<_ImportCreateDepartmentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  List<UserModel> _admins = const <UserModel>[];
  UserModel? _selectedAdmin;
  OrganizationModel? _organization;
  final Set<String> _createdAdminIds = <String>{};
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  Set<String> get _existingCodes => widget.lookup.codes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.csvValue.trim());
    _codeController = TextEditingController(
      text: DepartmentModel.uniqueSuggestedCode(widget.csvValue, _existingCodes),
    );
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final OrganizationModel? org = await FirestoreUtils.fetchOrganization(widget.actor.orgId);
      final List<UserModel> admins =
          await FirestoreUtils.listEligibleDepartmentAdministrators(orgId: widget.actor.orgId);
      if (!mounted) return;
      setState(() {
        _organization = org ??
            OrganizationModel(
              id: widget.actor.orgId,
              name: widget.actor.orgId,
              type: widget.actor.orgType ?? OrganizationType.college,
              address: '',
              website: '',
              contact: '',
              createdAt: DateTime.now(),
            );
        _admins = admins;
        _selectedAdmin = admins.isEmpty ? null : admins.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _createDepartmentAdmin() async {
    final OrganizationModel? organization = _organization;
    if (organization == null) return;
    UserModel? created;
    final bool saved = await showCreateUserDialog(
      context: context,
      roleCode: UserRole.departmentAdmin.code,
      organization: organization,
      department: _nameController.text.trim().isEmpty ? widget.csvValue.trim() : _nameController.text.trim(),
      onUserSaved: (UserModel user) async {
        created = user;
      },
    );
    if (!mounted || !saved || created == null) return;
    if (!UserRole.isEligibleDepartmentAdministrator(created!.role)) {
      FeedbackService.showWarning(
        context,
        title: 'Administrator not eligible',
        message: 'Only a Department Admin or College Admin can administer a department.',
      );
      return;
    }
    setState(() {
      final List<UserModel> next = <UserModel>[created!, ..._admins.where((UserModel u) => u.userId != created!.userId)];
      _admins = next;
      _selectedAdmin = created;
      _createdAdminIds.add(created!.userId);
    });
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    final String code = _codeController.text.trim().toUpperCase();
    final UserModel? admin = _selectedAdmin;
    if (name.isEmpty) {
      FeedbackService.showWarning(context, title: 'Department required', message: 'Enter a department name.');
      return;
    }
    if (code.isEmpty) {
      FeedbackService.showWarning(context, title: 'Department code required', message: 'Enter a department code.');
      return;
    }
    if (_existingCodes.contains(code)) {
      FeedbackService.showWarning(
        context,
        title: 'Code already used',
        message: 'Department code "$code" already exists. Choose a different code.',
      );
      return;
    }
    if (admin == null || !UserRole.isEligibleDepartmentAdministrator(admin.role)) {
      FeedbackService.showWarning(
        context,
        title: 'Administrator required',
        message: ImportConstants.departmentAdminRequiredMessage,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final List<String> aliases = DepartmentModel.aliasMatchesDepartment(
        alias: widget.csvValue,
        name: name,
        code: code,
      )
          ? const <String>[]
          : <String>[widget.csvValue.trim()];
      final String departmentId = await FirestoreUtils.addDepartment(
        orgId: widget.actor.orgId,
        name: name,
        code: code,
        adminUserId: admin.userId,
        aliases: aliases,
      );
      await FirestoreUtils.setDepartmentAdmin(
        departmentId: departmentId,
        adminUserId: admin.userId,
      );
      await DomainService.ensureGeneralProblem(
        orgId: widget.actor.orgId,
        departmentId: departmentId,
      );
      if (_createdAdminIds.contains(admin.userId) &&
          UserRole.fromCode(admin.role) == UserRole.departmentAdmin) {
        await FirestoreUtils.updateUser(admin.userId, <String, dynamic>{
          'role': UserRole.departmentAdmin.code,
          'department': name,
          'departmentCode': code,
          'orgId': widget.actor.orgId,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        ImportDepartmentInfo(id: departmentId, code: code, name: name, aliases: aliases),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Could not create department', message: '$e');
      setState(() => _saving = false);
    }
  }

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
                'Create Department',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'CSV value: ${widget.csvValue}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Text(_loadError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13))
        else ...<Widget>[
          _labeledValueField(
            label: 'Department name',
            controller: _nameController,
            hint: 'Department name',
          ),
          _labeledValueField(
            label: 'Department code',
            controller: _codeController,
            hint: 'Department code',
            capitalize: true,
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: HackzInputDecoration.fieldLabel('Department administrator', required: true),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _createDepartmentAdmin,
                icon: const Icon(AppIcons.add, size: MobileToolbarButtonStyles.toolbarIconSize),
                label: const Text('Create Department Admin'),
                style: MobileToolbarButtonStyles.filled(compact: true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_admins.isEmpty)
            Text(
              ImportConstants.departmentAdminRequiredMessage,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
            )
          else
            HackzSelectField<UserModel>(
              value: _selectedAdmin,
              options: _admins,
              enabled: !_saving,
              compact: true,
              hint: 'Select administrator',
              labelBuilder: (UserModel user) =>
                  '${userDisplayName(user)} · ${UserRoleLabels.labelForCode(user.role)}',
              onChanged: (UserModel user) => setState(() => _selectedAdmin = user),
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
              onPressed: _saving || _loading || _admins.isEmpty ? null : _submit,
              child: const Text('Create'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _labeledValueField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool capitalize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: HackzInputDecoration.fieldLabel(label),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !_saving,
              textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.none,
              style: HackzInputDecoration.compactFieldTextStyle,
              decoration: HackzInputDecoration.decorate(hintText: hint, compact: true),
            ),
          ),
        ],
      ),
    );
  }
}
