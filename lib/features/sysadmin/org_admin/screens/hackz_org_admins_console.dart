import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/email_field.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/phone_number_field.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../organization/models/organization_model.dart';
import '../../../user/widgets/user_form_section.dart';
import '../models/hkz_org_admin.dart';
import '../services/hkz_org_admin_service.dart';

class HackzOrgAdminsConsole extends StatefulWidget {
  const HackzOrgAdminsConsole({super.key});

  @override
  State<HackzOrgAdminsConsole> createState() => _HackzOrgAdminsConsoleState();
}

class _HackzOrgAdminsConsoleState extends State<HackzOrgAdminsConsole> {
  List<HkzOrgAdmin> _admins = const <HkzOrgAdmin>[];
  Map<String, String> _orgNames = const <String, String>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        HkzOrgAdminService.list(),
        FirestoreUtils.getOrganizations(database: HackzFirebase.controlPlane.firestore),
      ]);
      if (!mounted) return;
      final List<OrganizationModel> orgs = results[1] as List<OrganizationModel>;
      setState(() {
        _admins = results[0] as List<HkzOrgAdmin>;
        _orgNames = <String, String>{
          for (final OrganizationModel org in orgs) org.id: org.name,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final bool? saved = await showHackzOrgAdminEditorDialog(context: context, orgNames: _orgNames);
    if (saved == true && mounted) _reload();
  }

  Future<void> _toggleActive(HkzOrgAdmin admin) async {
    try {
      await HkzOrgAdminService.setActive(orgAdminId: admin.id, isActive: !admin.isActive);
      if (mounted) {
        FeedbackService.showSuccess(
          context,
          title: admin.isActive ? 'Deactivated' : 'Activated',
          message: admin.displayName,
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Update failed', message: '$e');
      }
    }
  }

  Future<void> _manageAssignments(HkzOrgAdmin admin) async {
    final bool? saved = await showHackzOrgAdminAssignmentsDialog(
      context: context,
      admin: admin,
      orgNames: _orgNames,
    );
    if (saved == true && mounted) _reload();
  }

  String _orgLabel(String orgId) {
    final String name = (_orgNames[orgId] ?? '').trim();
    if (name.isEmpty) return orgId;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _body(mobile)),
        if (mobile && !_loading) MobileCreateFab(onPressed: _add, tooltip: 'Add Hackz org admin'),
      ],
    );
  }

  Widget _body(bool mobile) {
    if (_loading) return const Center(child: HkzProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Unable to load Hackz org admins: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(mobile),
          const SizedBox(height: 14),
          if (_admins.isEmpty)
            _empty()
          else if (mobile)
            ..._admins.map(
              (HkzOrgAdmin admin) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _adminCard(admin),
              ),
            )
          else
            _table(),
        ],
      ),
    );
  }

  Widget _header(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'Hackz Organisation Admins',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'Hackz support users authorised to operate in assigned organisation tenants. '
                'This is not a college employee role.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
        if (!mobile) ...<Widget>[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Add Hackz org admin'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6A38FF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'No Hackz org admins yet. Add a support user and assign organisations.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _adminCard(HkzOrgAdmin admin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.helpSupport, color: admin.isActive ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(admin.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(admin.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _statusChip(admin.isActive),
            ],
          ),
          const SizedBox(height: 10),
          Text(admin.phone, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: admin.assignedOrganisationIds
                .map((String id) => Chip(label: Text(_orgLabel(id), style: const TextStyle(fontSize: 11))))
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              TextButton(onPressed: () => _manageAssignments(admin), child: const Text('Assignments')),
              TextButton(onPressed: () => _toggleActive(admin), child: Text(admin.isActive ? 'Deactivate' : 'Activate')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('Support user', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 3, child: Text('Organisations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                SizedBox(width: 180, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              ],
            ),
          ),
          for (int i = 0; i < _admins.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            _tableRow(_admins[i]),
          ],
        ],
      ),
    );
  }

  Widget _tableRow(HkzOrgAdmin admin) {
    final String orgSummary = admin.assignedOrganisationIds.map(_orgLabel).join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(admin.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Hackz Organisation Admin', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(admin.phone, style: const TextStyle(fontSize: 13)),
                Text(admin.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(orgSummary.isEmpty ? '—' : orgSummary, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusChip(admin.isActive))),
          SizedBox(
            width: 180,
            child: Wrap(
              spacing: 4,
              children: <Widget>[
                TextButton(onPressed: () => _manageAssignments(admin), child: const Text('Assign')),
                TextButton(onPressed: () => _toggleActive(admin), child: Text(admin.isActive ? 'Deactivate' : 'Activate')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? const Color(0xFF047857) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

Future<bool?> showHackzOrgAdminEditorDialog({
  required BuildContext context,
  required Map<String, String> orgNames,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext _) => _HackzOrgAdminEditorDialog(orgNames: orgNames),
  );
}

class _HackzOrgAdminEditorDialog extends StatefulWidget {
  const _HackzOrgAdminEditorDialog({required this.orgNames});

  final Map<String, String> orgNames;

  @override
  State<_HackzOrgAdminEditorDialog> createState() => _HackzOrgAdminEditorDialogState();
}

class _HackzOrgAdminEditorDialogState extends State<_HackzOrgAdminEditorDialog> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await HkzOrgAdminService.create(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        phone: normalizePhoneE164(_phone.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) FeedbackService.showError(context, title: 'Create failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Hackz Organisation Admin'),
      content: SizedBox(
        width: 420,
        child: UserFormSection(
          title: 'Support user',
          subtitle: 'Hackz operations identity — not a college employee',
          child: Column(
            children: <Widget>[
              TextField(
                controller: _firstName,
                decoration: HackzInputDecoration.decorate(hintText: 'First name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastName,
                decoration: HackzInputDecoration.decorate(hintText: 'Last name'),
              ),
              const SizedBox(height: 8),
              EmailField(
                controller: _email,
                decoration: HackzInputDecoration.decorate(hintText: 'Email'),
              ),
              const SizedBox(height: 8),
              PhoneNumberField(
                controller: _phone,
                decoration: HackzInputDecoration.decorate(hintText: 'Mobile'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? const HkzProgressIndicator(size: 18) : const Text('Create')),
      ],
    );
  }
}

Future<bool?> showHackzOrgAdminAssignmentsDialog({
  required BuildContext context,
  required HkzOrgAdmin admin,
  required Map<String, String> orgNames,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext _) => _HackzOrgAdminAssignmentsDialog(admin: admin, orgNames: orgNames),
  );
}

class _HackzOrgAdminAssignmentsDialog extends StatefulWidget {
  const _HackzOrgAdminAssignmentsDialog({required this.admin, required this.orgNames});

  final HkzOrgAdmin admin;
  final Map<String, String> orgNames;

  @override
  State<_HackzOrgAdminAssignmentsDialog> createState() => _HackzOrgAdminAssignmentsDialogState();
}

class _HackzOrgAdminAssignmentsDialogState extends State<_HackzOrgAdminAssignmentsDialog> {
  late Set<String> _assigned;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _assigned = widget.admin.assignedOrganisationIds.toSet();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final Set<String> original = widget.admin.assignedOrganisationIds.toSet();
      for (final String orgId in _assigned.difference(original)) {
        await HkzOrgAdminService.assignOrganisation(orgAdminId: widget.admin.id, organisationId: orgId);
      }
      for (final String orgId in original.difference(_assigned)) {
        await HkzOrgAdminService.removeOrganisationAssignment(orgAdminId: widget.admin.id, organisationId: orgId);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) FeedbackService.showError(context, title: 'Update failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> orgs = widget.orgNames.entries.toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) => a.value.compareTo(b.value));

    return AlertDialog(
      title: Text('Organisations — ${widget.admin.displayName}'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: orgs.isEmpty
            ? const Text('No organisations on the Control Plane yet.')
            : ListView.builder(
                itemCount: orgs.length,
                itemBuilder: (BuildContext context, int index) {
                  final MapEntry<String, String> entry = orgs[index];
                  final bool checked = _assigned.contains(entry.key);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: _busy
                        ? null
                        : (bool? value) {
                            setState(() {
                              if (value == true) {
                                _assigned.add(entry.key);
                              } else {
                                _assigned.remove(entry.key);
                              }
                            });
                          },
                    title: Text(entry.value),
                    subtitle: Text(entry.key, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? const HkzProgressIndicator(size: 18) : const Text('Save')),
      ],
    );
  }
}
