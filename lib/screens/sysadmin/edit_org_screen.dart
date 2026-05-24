import 'package:flutter/material.dart';

import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../common/app_dialog_template.dart';
import '../common/create_user_dialog.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';

class EditOrgScreen extends StatefulWidget {
  const EditOrgScreen({
    super.key,
    required this.organization,
    this.embedded = false,
    this.onBack,
    this.onOrganizationsChanged,
  });

  final OrganizationModel organization;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onOrganizationsChanged;

  @override
  State<EditOrgScreen> createState() => _EditOrgScreenState();
}

class _EditOrgScreenState extends State<EditOrgScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _contactController;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organization.name);
    _addressController = TextEditingController(text: widget.organization.address);
    _websiteController = TextEditingController(text: widget.organization.website);
    _contactController = TextEditingController(text: widget.organization.contact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, {bool readOnly = false}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF2F0F8) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: readOnly ? const Color(0xFFD2C8EC) : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
      ),
    );
  }

  Future<void> _saveOrganization() async {
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _websiteController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill organization details')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirestoreUtils.upsertOrganization(
        widget.organization.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          website: _websiteController.text.trim(),
          contact: _contactController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization updated successfully')),
      );
      if (widget.embedded) {
        widget.onOrganizationsChanged?.call();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteOrganization() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveAlertDialog(
          title: const Text('Delete organization?'),
          widthPreset: DialogWidthPreset.compact,
          content: Text('This will remove "${widget.organization.name}".'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    setState(() => _isDeleting = true);
    try {
      await FirestoreUtils.deleteOrganization(widget.organization.id);
      if (!mounted) return;
      if (widget.embedded) {
        widget.onOrganizationsChanged?.call();
        widget.onBack?.call();
      } else {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _removeCollegeAdmin(UserModel admin) async {
    final adminId = admin.userId.trim();
    if (adminId.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveAlertDialog(
          title: const Text('Remove college admin?'),
          widthPreset: DialogWidthPreset.compact,
          content: Text('Remove ${admin.firstName} ${admin.lastName} from this organization?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await FirestoreUtils.deleteUser(adminId);
  }

  Widget _buildFormBody() {
    final type = widget.organization.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Organization Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text('${type.displayName} Name', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _fieldDecoration('Enter ${type.displayName} name'),
              ),
              const SizedBox(height: 12),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                maxLines: 3,
                minLines: 3,
                decoration: _fieldDecoration('Street, city, state, PIN...'),
              ),
              const SizedBox(height: 12),
              const Text('Website', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _websiteController,
                decoration: _fieldDecoration('https://example.com'),
              ),
              const SizedBox(height: 12),
              const Text('Contact', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _contactController,
                decoration: _fieldDecoration('Phone or contact person'),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  FilledButton(
                    onPressed: _isSaving || _isDeleting ? null : _saveOrganization,
                    child: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isSaving || _isDeleting ? null : _deleteOrganization,
                    child: Text(_isDeleting ? 'Deleting...' : 'Delete ${type.displayName}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'College Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (type != OrganizationType.college) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'College admins are only applicable for College organizations.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 10),
                StreamBuilder<List<UserModel>>(
                  stream: FirestoreUtils.watchUsersByOrgAndRole(
                    orgId: widget.organization.id,
                    roleCode: 'CADM',
                  ),
                  builder: (BuildContext context, AsyncSnapshot<List<UserModel>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Unable to load college admins: ${snapshot.error}');
                    }
                    final admins = snapshot.data ?? <UserModel>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 10),
                        if (admins.isEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => showCreateUserDialog(
                                context: context,
                                roleCode: 'CADM',
                                organization: widget.organization,
                              ),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Add Admin'),
                            ),
                          )
                        else
                          const Text(
                            'Only one College Admin is allowed per college.',
                            style: TextStyle(color: Color(0xFF595E80)),
                          ),
                        const SizedBox(height: 10),
                        if (admins.isEmpty)
                          const Text('No college admins found for this organization.')
                        else
                          ...admins.map(
                            (admin) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${admin.firstName} ${admin.lastName}\n${admin.email}\n${admin.phone}',
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => showCreateUserDialog(
                                      context: context,
                                      roleCode: 'CADM',
                                      organization: widget.organization,
                                      initialUser: admin,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: () => _removeCollegeAdmin(admin),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.organization.type;
    final scrollBody = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildFormBody(),
    );
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF5F7FB),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Organizations'),
                ),
              ),
            ),
            Expanded(child: scrollBody),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${type.displayName}'),
      ),
      backgroundColor: const Color(0xFFF5F7FB),
      body: scrollBody,
    );
  }
}
