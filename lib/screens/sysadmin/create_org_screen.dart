import 'package:flutter/material.dart';

import '../../features/org_settings/services/org_settings_service.dart';
import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../shared/feedback/feedback.dart';
import '../../utils/firestore_utils.dart';

class CreateOrganizationDialogForm extends StatefulWidget {
  const CreateOrganizationDialogForm({
    super.key,
    this.organizationType,
    this.asDialog = false,
    this.initialOrganization,
  });

  /// When `null` and [asDialog] is true, the form shows a type selector (unified labels).
  /// When non-null, legacy labels and no type dropdown.
  final OrganizationType? organizationType;
  final bool asDialog;
  final OrganizationModel? initialOrganization;

  @override
  State<CreateOrganizationDialogForm> createState() => _CreateOrganizationDialogFormState();
}

class _CreateOrganizationDialogFormState extends State<CreateOrganizationDialogForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactController = TextEditingController();
  bool _busy = false;
  late OrganizationType _selectedType;
  late final bool _isEdit;

  bool get _unifiedDialog => widget.asDialog && widget.organizationType == null;

  String get _legacyDisplayType => (widget.organizationType ?? OrganizationType.college).displayName;

  OrganizationType get _effectiveType => widget.organizationType ?? _selectedType;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialOrganization != null;
    _selectedType = widget.initialOrganization?.type ?? widget.organizationType ?? OrganizationType.college;
    _nameController.text = widget.initialOrganization?.name ?? '';
    _addressController.text = widget.initialOrganization?.address ?? '';
    _websiteController.text = widget.initialOrganization?.website ?? '';
    _contactController.text = widget.initialOrganization?.contact ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final website = _websiteController.text.trim();
    final contact = _contactController.text.trim();
    if (name.isEmpty || address.isEmpty || website.isEmpty || contact.isEmpty) {
      _toast(_unifiedDialog ? 'Please fill all organization details' : 'Please fill all $_legacyDisplayType details');
      return;
    }
    setState(() => _busy = true);
    try {
      final String orgId = await FirestoreUtils.upsertOrganization(
        (widget.initialOrganization ??
                OrganizationModel(
                  id: '',
                  name: '',
                  type: _effectiveType,
                  address: '',
                  website: '',
                  contact: '',
                  createdAt: DateTime.now(),
                ))
            .copyWith(
          name: name,
          type: _effectiveType,
          address: address,
          website: website,
          contact: contact,
        ),
      );
      if (!_isEdit) {
        await OrgSettingsService.seedFor(orgId);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    FeedbackService.showInfo(
      context,
      title: 'Organization',
      message: msg,
    );
  }

  InputDecoration _fieldDecoration(
    String hint, {
    bool readOnly = false,
    String? helperText,
    bool dense = false,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      isDense: dense,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF2F0F8) : Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 12 : 14,
      ),
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

  ButtonStyle _compactButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(88, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  ButtonStyle _compactOutlineButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(88, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _typeDropdown({required double width}) {
    return DropdownMenu<OrganizationType>(
      key: ValueKey<OrganizationType>(_selectedType),
      initialSelection: _selectedType,
      enableFilter: false,
      requestFocusOnTap: true,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
        ),
      ),
      width: width,
      dropdownMenuEntries: OrganizationType.values
          .map(
            (OrganizationType t) => DropdownMenuEntry<OrganizationType>(
              value: t,
              label: t.displayName,
            ),
          )
          .toList(growable: false),
      onSelected: (OrganizationType? t) {
        if (t == null) return;
        setState(() => _selectedType = t);
      },
    );
  }

  Widget _formBody() {
    final bool unified = _unifiedDialog;
    final String title = _isEdit
        ? (unified ? 'Edit Organization' : 'Edit ${_legacyDisplayType.toLowerCase()}')
        : (unified ? 'New Organization' : 'New ${_legacyDisplayType.toLowerCase()}');
    final String nameLabel = unified ? 'Organization name' : '$_legacyDisplayType name';
    final String nameHint = unified ? 'Enter organization name' : 'Enter $_legacyDisplayType name';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.asDialog ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.apartment_rounded, color: Color(0xFF6A38FF), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(nameLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: _fieldDecoration(nameHint),
        ),
        const SizedBox(height: 16),
        if (unified) ...<Widget>[
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              return _typeDropdown(width: c.maxWidth);
            },
          ),
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _effectiveType.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          maxLines: 3,
          minLines: 3,
          decoration: _fieldDecoration('Street, city, state, PIN...'),
        ),
        const SizedBox(height: 16),
        const Text('Website', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _websiteController,
          decoration: _fieldDecoration('https://example.com'),
        ),
        const SizedBox(height: 16),
        const Text('Contact', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _contactController,
          decoration: _fieldDecoration('Phone or contact person'),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              style: _compactOutlineButtonStyle(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: _compactButtonStyle(),
              child: Text(_busy ? (_isEdit ? 'Saving...' : 'Creating...') : (_isEdit ? 'Save' : 'Create')),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _formBody();
    if (widget.asDialog) return body;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }
}
