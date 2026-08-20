import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/hackz_select_field.dart';
import '../../../../features/org_settings/services/org_settings_service.dart';
import '../../../../features/organization/models/enums/organization_type.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../features/organization/services/org_photo_service.dart';
import '../../../../features/user/widgets/user_form_section.dart';
import '../../../../features/user/widgets/user_profile_photo_field.dart';
import '../../../../utils/firestore_utils.dart';

enum _OrgFormField { name, address, website, contact }

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _busy = false;
  late OrganizationType _selectedType;
  late final bool _isEdit;
  PlatformFile? _iconFile;
  String? _remotePhotoUrl;
  String? _remoteThumbUrl;
  bool _iconCleared = false;
  Map<_OrgFormField, String> _fieldErrors = <_OrgFormField, String>{};

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
    _remotePhotoUrl = widget.initialOrganization?.photoUrl;
    _remoteThumbUrl = widget.initialOrganization?.thumbnailUrl;
    _nameController.addListener(() {
      _clearFieldError(_OrgFormField.name);
      if (mounted) setState(() {});
    });
    _addressController.addListener(() => _clearFieldError(_OrgFormField.address));
    _websiteController.addListener(() => _clearFieldError(_OrgFormField.website));
    _contactController.addListener(() => _clearFieldError(_OrgFormField.contact));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _clearFieldError(_OrgFormField field) {
    if (_fieldErrors.remove(field) != null && mounted) {
      setState(() {});
    }
  }

  String? _errorFor(_OrgFormField field) => _fieldErrors[field];

  bool _validateForm() {
    final Map<_OrgFormField, String> errors = <_OrgFormField, String>{};
    if (_nameController.text.trim().isEmpty) {
      errors[_OrgFormField.name] = 'Organization name is required.';
    }
    if (_addressController.text.trim().isEmpty) {
      errors[_OrgFormField.address] = 'Address is required.';
    }
    if (_websiteController.text.trim().isEmpty) {
      errors[_OrgFormField.website] = 'Website is required.';
    }
    if (_contactController.text.trim().isEmpty) {
      errors[_OrgFormField.contact] = 'Contact is required.';
    }
    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  Future<void> _pickIcon() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _iconFile = result.files.first;
      _iconCleared = false;
    });
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;
    setState(() => _busy = true);
    try {
      final OrganizationModel base = widget.initialOrganization ??
          OrganizationModel(
            id: '',
            name: '',
            type: _effectiveType,
            address: '',
            website: '',
            contact: '',
            createdAt: DateTime.now(),
          );
      var org = base.copyWith(
        name: _nameController.text.trim(),
        type: _effectiveType,
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        contact: _contactController.text.trim(),
        clearPhoto: _iconCleared && _iconFile == null,
      );

      final String orgId = await FirestoreUtils.upsertOrganization(org);
      org = org.copyWith(id: orgId);

      if (!_isEdit) {
        await OrgSettingsService.seedFor(orgId);
      }

      if (_iconFile != null) {
        final uploaded = await OrgPhotoService.uploadLogo(orgId: orgId, file: _iconFile!);
        org = org.copyWith(photoUrl: uploaded.photoUrl, thumbnailUrl: uploaded.thumbnailUrl);
        await FirestoreUtils.upsertOrganization(org);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: _isEdit ? 'Unable to save organization' : 'Unable to create organization',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _fieldDecoration(String hint, {_OrgFormField? field, IconData? prefixIcon, int minLines = 1}) {
    return HackzInputDecoration.decorate(
      hintText: hint,
      errorText: field == null ? null : _errorFor(field),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 18, color: HackzInputDecoration.iconColor),
      contentPaddingOverride: minLines > 1
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asDialog) {
      return AppDialogTemplate(
        width: DialogWidthPreset.extraWide,
        maxWidth: 920,
        contentPadding: EdgeInsets.zero,
        footer: _buildFooter(context),
        child: _buildBody(context),
      );
    }
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: _buildBody(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  EdgeInsets get _contentPadding {
    if (ResponsiveHelper.isMobile(context)) {
      return const EdgeInsets.fromLTRB(16, 8, 16, 12);
    }
    return const EdgeInsets.fromLTRB(22, 16, 22, 12);
  }

  Widget _buildBody(BuildContext context) {
    final bool wide = ResponsiveHelper.isDesktopOrWider(context) || ResponsiveHelper.isTablet(context);
    return Padding(
      padding: _contentPadding,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHero(),
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: _buildIdentityCard()),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: _buildDetailsCard()),
                ],
              )
            else ...<Widget>[
              _buildIdentityCard(),
              const SizedBox(height: 10),
              _buildDetailsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final String title = _isEdit
        ? (_unifiedDialog ? 'Edit organization' : 'Edit ${_legacyDisplayType.toLowerCase()}')
        : (_unifiedDialog ? 'Create organization' : 'New ${_legacyDisplayType.toLowerCase()}');
    final String subtitle = _isEdit
        ? 'Update identity, icon, and contact details.'
        : 'Add a new Hackz organization with identity and contact details.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF8F5FF), Color(0xFFF1F5FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppIcons.organizations,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
    final String nameLabel = _unifiedDialog ? 'Organization name' : '$_legacyDisplayType name';
    return UserFormSection(
      title: 'Identity',
      subtitle: 'Icon, name, and type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          UserProfilePhotoField(
            displayName: _nameController.text,
            localFile: _iconFile,
            remoteUrl: _iconCleared ? null : (_remoteThumbUrl ?? _remotePhotoUrl),
            enabled: !_busy,
            title: 'Organization icon',
            subtitle: 'Shown next to the organization name in the organizations list.',
            buttonLabel: 'Upload icon',
            circular: false,
            onPick: _pickIcon,
            onClear: () => setState(() {
              _iconFile = null;
              _remotePhotoUrl = null;
              _remoteThumbUrl = null;
              _iconCleared = true;
            }),
          ),
          const SizedBox(height: 12),
          HackzInputDecoration.labeledField(
            label: nameLabel,
            required: true,
            field: TextField(
              controller: _nameController,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _fieldDecoration(
                'Enter $nameLabel',
                field: _OrgFormField.name,
                prefixIcon: AppIcons.organizations,
              ),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Type',
            required: true,
            field: _unifiedDialog
                ? HackzSelectField<OrganizationType>(
                    value: _selectedType,
                    hint: 'Select organization type',
                    enabled: !_busy,
                    prefixIcon: AppIcons.forOrganizationType(_selectedType),
                    options: OrganizationType.values,
                    labelBuilder: (OrganizationType t) => t.displayName,
                    iconBuilder: AppIcons.forOrganizationType,
                    onChanged: (OrganizationType t) => setState(() => _selectedType = t),
                  )
                : _readOnlyTypeField(),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyTypeField() {
    return InputDecorator(
      decoration: _fieldDecoration(_effectiveType.displayName, prefixIcon: AppIcons.forOrganizationType(_effectiveType)),
      child: Text(
        _effectiveType.displayName,
        style: HackzInputDecoration.fieldTextStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return UserFormSection(
      title: 'Details',
      subtitle: 'Address and how to reach this organization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HackzInputDecoration.labeledField(
            label: 'Address',
            required: true,
            field: TextField(
              controller: _addressController,
              enabled: !_busy,
              minLines: 3,
              maxLines: 3,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _fieldDecoration(
                'Street, city, state, PIN...',
                field: _OrgFormField.address,
                prefixIcon: AppIcons.address,
                minLines: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Website',
            required: true,
            field: TextField(
              controller: _websiteController,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _fieldDecoration(
                'https://example.com',
                field: _OrgFormField.website,
                prefixIcon: AppIcons.website,
              ),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Contact',
            required: true,
            field: TextField(
              controller: _contactController,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _fieldDecoration(
                'Phone or contact person',
                field: _OrgFormField.contact,
                prefixIcon: AppIcons.phone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Save organization' : 'Create organization'),
            ),
          ),
        ],
      ),
    );
  }
}
