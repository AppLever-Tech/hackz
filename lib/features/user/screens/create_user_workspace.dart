import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/organization_model.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../screens/common/app_dialog_template.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../shared/inputs/email_field.dart';
import '../../../shared/inputs/phone_number_field.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../models/enums/judge_type.dart';
import '../models/enums/user_role.dart';
import '../models/enums/user_status.dart';
import '../models/profiles/college_admin_profile.dart';
import '../models/profiles/department_admin_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/judge_profile.dart';
import '../models/profiles/professional_profile.dart';
import '../models/profiles/student_profile.dart';
import '../models/profiles/user_profile.dart';
import '../models/user_model.dart';
import '../services/user_photo_service.dart';
import '../services/user_profile_rules.dart';
import '../services/user_role_labels.dart';
import '../services/user_service.dart';
import '../widgets/user_form_section.dart';
import '../widgets/user_profile_photo_field.dart';
import '../../../shared/inputs/hackz_select_field.dart';
import '../widgets/user_tags_field.dart';

enum _UserFormField { firstName, lastName, email, phone, roles }

Future<bool> showCreateUserWorkspace({
  required BuildContext context,
  String? roleCode,
  List<String>? roleOptions,
  String? initialRoleCode,
  required OrganizationModel organization,
  String department = '',
  UserModel? initialUser,
  Future<void> Function(UserModel user)? onUserSaved,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return CreateUserWorkspace(
        roleCode: roleCode,
        roleOptions: roleOptions,
        initialRoleCode: initialRoleCode,
        organization: organization,
        department: department,
        initialUser: initialUser,
        onUserSaved: onUserSaved,
      );
    },
  ).then((bool? value) => value ?? false);
}

class CreateUserWorkspace extends StatefulWidget {
  const CreateUserWorkspace({
    super.key,
    this.roleCode,
    this.roleOptions,
    this.initialRoleCode,
    required this.organization,
    this.department = '',
    this.initialUser,
    this.onUserSaved,
  });

  final String? roleCode;
  final List<String>? roleOptions;
  final String? initialRoleCode;
  final OrganizationModel organization;
  final String department;
  final UserModel? initialUser;
  final Future<void> Function(UserModel user)? onUserSaved;

  bool get isEdit => initialUser != null;

  @override
  State<CreateUserWorkspace> createState() => _CreateUserWorkspaceState();
}

class _CreateUserWorkspaceState extends State<CreateUserWorkspace> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _yearOfStudyController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _deptAdminDesignationController = TextEditingController();
  final TextEditingController _collegeAdminDesignationController = TextEditingController();

  late final Set<String> _selectedRoles;
  late UserStatus _selectedStatus;
  PlatformFile? _photoFile;
  String? _remotePhotoUrl;
  String? _remoteThumbUrl;
  List<String> _expertiseAreas = <String>[];
  List<String> _skills = <String>[];
  List<String> _researchInterests = <String>[];
  List<String> _evaluationDomains = <String>[];
  JudgeType? _judgeType;
  bool _saving = false;
  String _deptDisplayName = '';
  Map<_UserFormField, String> _fieldErrors = <_UserFormField, String>{};

  static const Color _errorAccent = Color(0xFFBE123C);
  static const Color _errorBorder = Color(0xFFFECACA);
  static const Color _errorFill = Color(0xFFFFF7F7);

  bool get _roleLocked => widget.roleCode != null && widget.roleCode!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final UserModel? user = widget.initialUser;
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = (user?.phone ?? '').replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
    _remotePhotoUrl = user?.photoUrl;
    _remoteThumbUrl = user?.thumbnailUrl;
    _selectedStatus = user?.status ?? UserStatus.active;

    final String locked = (widget.roleCode ?? '').trim();
    final List<String> options = (widget.roleOptions ?? const <String>[])
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    if (locked.isNotEmpty) {
      _selectedRoles = <String>{locked};
    } else if (user != null && user.effectiveRoles.isNotEmpty) {
      _selectedRoles = user.effectiveRoles.toSet();
    } else {
      final String initial = (widget.initialRoleCode ?? 'STU').trim();
      _selectedRoles = <String>{options.contains(initial) ? initial : (options.isNotEmpty ? options.first : initial)};
    }

    final profile = user?.profile;
    final professional = profile?.professionalProfile;
    _companyController.text = professional?.company ?? '';
    _designationController.text = professional?.designation ?? '';
    _yearsController.text = professional != null && professional.yearsOfExperience > 0
        ? '${professional.yearsOfExperience}'
        : '';
    _expertiseAreas = List<String>.from(professional?.expertiseAreas ?? const <String>[]);
    _programController.text = profile?.studentProfile?.program ?? '';
    _yearOfStudyController.text = profile?.studentProfile?.yearOfStudy ?? '';
    _skills = List<String>.from(profile?.studentProfile?.skills ?? const <String>[]);
    _specializationController.text = profile?.facultyProfile?.specialization ?? '';
    _researchInterests = List<String>.from(profile?.facultyProfile?.researchInterests ?? const <String>[]);
    _evaluationDomains = List<String>.from(profile?.judgeProfile?.evaluationDomains ?? const <String>[]);
    _judgeType = profile?.judgeProfile?.judgeType;
    _deptAdminDesignationController.text = profile?.departmentAdminProfile?.officeDesignation ?? '';
    _collegeAdminDesignationController.text = profile?.collegeAdminProfile?.officeDesignation ?? '';

    _deptDisplayName = widget.department.trim().isNotEmpty
        ? widget.department.trim()
        : (user?.department.trim() ?? '');

    _firstNameController.addListener(() => _clearFieldError(_UserFormField.firstName));
    _lastNameController.addListener(() => _clearFieldError(_UserFormField.lastName));
    _emailController.addListener(() => _clearFieldError(_UserFormField.email));
    _phoneController.addListener(() => _clearFieldError(_UserFormField.phone));
  }

  void _clearFieldError(_UserFormField field) {
    if (_fieldErrors.remove(field) != null && mounted) {
      setState(() {});
    }
  }

  String? _errorFor(_UserFormField field) => _fieldErrors[field];

  Map<_UserFormField, String> _collectValidationErrors() {
    final Map<_UserFormField, String> errors = <_UserFormField, String>{};

    if (_firstNameController.text.trim().isEmpty) {
      errors[_UserFormField.firstName] = 'First name is required.';
    }
    if (_lastNameController.text.trim().isEmpty) {
      errors[_UserFormField.lastName] = 'Last name is required.';
    }

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      errors[_UserFormField.email] = 'Email is required.';
    } else if (!isValidEmailInput(email)) {
      errors[_UserFormField.email] = 'Enter a valid email address.';
    }

    if (!widget.isEdit) {
      final String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        errors[_UserFormField.phone] = 'Phone number is required.';
      } else if (!isValidPhoneInput(_phoneController.text)) {
        errors[_UserFormField.phone] = 'Enter a valid 10-digit phone number.';
      }
    }

    if (_selectedRoles.isEmpty) {
      errors[_UserFormField.roles] = 'Select at least one role.';
    }

    return errors;
  }

  bool _validateForm() {
    final Map<_UserFormField, String> errors = _collectValidationErrors();
    setState(() => _fieldErrors = errors);
    if (errors.isEmpty) return true;

    FeedbackService.showWarning(
      context,
      title: 'Check required fields',
      message: errors.values.join('\n'),
    );
    return false;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    _yearsController.dispose();
    _programController.dispose();
    _yearOfStudyController.dispose();
    _specializationController.dispose();
    _deptAdminDesignationController.dispose();
    _collegeAdminDesignationController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    String hint, {
    bool readOnly = false,
    IconData? prefixIcon,
    String? errorText,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final Color idleBorder = readOnly ? const Color(0xFFD2C8EC) : Colors.grey.shade300;
    final Color fillColor = hasError
        ? _errorFill
        : (readOnly ? const Color(0xFFF2F0F8) : Colors.white);

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: hasError ? _errorAccent.withValues(alpha: 0.75) : const Color(0xFF64748B)),
      errorText: hasError ? errorText : null,
      errorStyle: const TextStyle(fontSize: 11, color: _errorAccent, height: 1.25, fontWeight: FontWeight.w500),
      errorMaxLines: 2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? _errorBorder : idleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFF87171) : const Color(0xFF6A38FF),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.6),
      ),
    );
  }

  static IconData _judgeTypeIcon(JudgeType type) {
    switch (type) {
      case JudgeType.internal:
        return Icons.corporate_fare_outlined;
      case JudgeType.external:
        return Icons.public_outlined;
      case JudgeType.industry:
        return Icons.factory_outlined;
      case JudgeType.academic:
        return Icons.school_outlined;
    }
  }

  Future<void> _pickPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _photoFile = result.files.first);
  }

  UserProfile _buildProfile() {
    final int years = int.tryParse(_yearsController.text.trim()) ?? 0;
    return UserProfileRules.buildProfile(
      roleCodes: _selectedRoles,
      professional: ProfessionalProfile(
        company: _companyController.text,
        designation: _designationController.text,
        yearsOfExperience: years,
        expertiseAreas: _expertiseAreas,
      ),
      student: StudentProfile(
        program: _programController.text,
        yearOfStudy: _yearOfStudyController.text,
        skills: _skills,
      ),
      faculty: FacultyProfile(
        specialization: _specializationController.text,
        researchInterests: _researchInterests,
      ),
      judge: JudgeProfile(
        evaluationDomains: _evaluationDomains,
        judgeType: _judgeType,
      ),
      departmentAdmin: DepartmentAdminProfile(officeDesignation: _deptAdminDesignationController.text),
      collegeAdmin: CollegeAdminProfile(officeDesignation: _collegeAdminDesignationController.text),
    );
  }

  Future<void> _save() async {
    if (!_validateForm()) return;

    setState(() => _saving = true);
    try {
      final profile = _buildProfile();
      final List<String> roles = _selectedRoles.toList()..sort();
      final String primaryRole = roles.first;

      if (widget.isEdit) {
        final UserModel existing = widget.initialUser!;
        var updated = existing.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          role: primaryRole,
          roles: roles,
          status: _selectedStatus,
          profile: profile.isEmpty ? null : profile,
        );

        if (_photoFile != null) {
          final uploaded = await UserPhotoService.uploadProfilePhoto(
            orgId: existing.orgId,
            userId: existing.userId,
            file: _photoFile!,
          );
          updated = updated.copyWith(photoUrl: uploaded.photoUrl, thumbnailUrl: uploaded.thumbnailUrl);
        }

        await UserService.updateUser(
          existing.userId,
          <String, dynamic>{
            'firstName': updated.firstName,
            'lastName': updated.lastName,
            'email': updated.email,
            'role': primaryRole,
            'roles': roles,
            'status': _selectedStatus.value,
            if ((updated.photoUrl ?? '').isNotEmpty) 'photoUrl': updated.photoUrl,
            if ((updated.thumbnailUrl ?? '').isNotEmpty) 'thumbnailUrl': updated.thumbnailUrl,
          },
          profile: profile,
        );
        if (widget.onUserSaved != null) await widget.onUserSaved!(updated);
      } else {
        final normalizedPhone = normalizePhoneE164(_phoneController.text);
        final existing = await FirestoreUtils.fetchUserByPhone(normalizedPhone);
        if (existing != null) throw StateError('User already exists for this phone.');

        final departmentCode = UserService.resolveDepartmentCode(widget.department);
        final UserModel draft = UserModel(
          userId: '',
          phone: normalizedPhone,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          role: primaryRole,
          roles: roles,
          orgType: widget.organization.type,
          orgId: widget.organization.id,
          department: widget.department,
          departmentCode: departmentCode,
          status: _selectedStatus,
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          profile: profile.isEmpty ? null : profile,
        );

        final String createdId = await UserService.createUser(user: draft, profile: profile);
        var created = draft.copyWith(userId: createdId);

        if (_photoFile != null) {
          final uploaded = await UserPhotoService.uploadProfilePhoto(
            orgId: widget.organization.id,
            userId: createdId,
            file: _photoFile!,
          );
          created = created.copyWith(photoUrl: uploaded.photoUrl, thumbnailUrl: uploaded.thumbnailUrl);
          await UserService.updateUser(createdId, <String, dynamic>{
            'photoUrl': uploaded.photoUrl,
            'thumbnailUrl': uploaded.thumbnailUrl,
          });
        }

        if (widget.onUserSaved != null) await widget.onUserSaved!(created);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(
          context,
          title: 'Unable to save user',
          message: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.extraWide,
      maxWidth: 920,
      contentPadding: EdgeInsets.zero,
      footer: _buildFooter(context),
      child: _buildBody(context),
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
            _buildHero(context),
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: _buildLeftColumn(context)),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: _buildRightColumn(context)),
                ],
              )
            else ...<Widget>[
              _buildLeftColumn(context),
              const SizedBox(height: 10),
              _buildRightColumn(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return UserFormSection(
      title: 'Identity',
      subtitle: 'Profile photo and contact details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          UserProfilePhotoField(
            displayName: '${_firstNameController.text} ${_lastNameController.text}',
            localFile: _photoFile,
            remoteUrl: _remotePhotoUrl ?? _remoteThumbUrl,
            enabled: !_saving,
            onPick: _pickPhoto,
            onClear: () => setState(() {
              _photoFile = null;
              _remotePhotoUrl = null;
              _remoteThumbUrl = null;
            }),
          ),
          const SizedBox(height: 12),
          _labeledField(
            'First name',
            TextField(
              controller: _firstNameController,
              decoration: _fieldDecoration('First name', errorText: _errorFor(_UserFormField.firstName)),
            ),
            required: true,
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Last name',
            TextField(
              controller: _lastNameController,
              decoration: _fieldDecoration('Last name', errorText: _errorFor(_UserFormField.lastName)),
            ),
            required: true,
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Email',
            EmailField(
              controller: _emailController,
              decoration: _fieldDecoration('Email', prefixIcon: AppIcons.email, errorText: _errorFor(_UserFormField.email)),
            ),
            required: true,
          ),
          const SizedBox(height: 10),
          _labeledField(
            'Phone',
            widget.isEdit
                ? _readOnlyIconField(
                    value: normalizePhoneE164(_phoneController.text),
                    hint: 'Phone',
                    icon: AppIcons.phone,
                  )
                : PhoneNumberField(
                    controller: _phoneController,
                    decoration: _fieldDecoration(
                      'Phone number',
                      prefixIcon: AppIcons.phone,
                      errorText: _errorFor(_UserFormField.phone),
                    ),
                  ),
            required: !widget.isEdit,
          ),
          if (_deptDisplayName.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _labeledField(
              'Department',
              _readOnlyIconField(
                value: _deptDisplayName,
                hint: 'Department',
                icon: AppIcons.departments,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    return _buildRolesCard(context);
  }

  Widget _buildRolesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!_roleLocked) _buildRolePicker() else _roleReadOnlyChip(),
          ..._buildRoleProfileSections(),
        ],
      ),
    );
  }

  List<Widget> _buildRoleProfileSections() {
    final List<Widget> sections = <Widget>[];

    if (UserProfileRules.needsProfessional(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.adminProfile,
          title: 'Professional information',
          subtitle: 'Applicable for faculty and judges',
          children: <Widget>[
            _labeledField('Company', TextField(controller: _companyController, decoration: _fieldDecoration('Company'))),
            const SizedBox(height: 10),
            _labeledField('Designation', TextField(controller: _designationController, decoration: _fieldDecoration('Designation'))),
            const SizedBox(height: 10),
            _labeledField(
              'Years of experience',
              TextField(controller: _yearsController, keyboardType: TextInputType.number, decoration: _fieldDecoration('Years')),
            ),
            const SizedBox(height: 10),
            UserTagsField(
              label: 'Expertise areas',
              values: _expertiseAreas,
              enabled: !_saving,
              onChanged: (List<String> v) => setState(() => _expertiseAreas = v),
            ),
          ],
        ),
      );
    }

    if (UserProfileRules.needsStudent(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.student,
          title: 'Student information',
          children: <Widget>[
            _labeledField('Program', TextField(controller: _programController, decoration: _fieldDecoration('Program'))),
            const SizedBox(height: 10),
            _labeledField('Year of study', TextField(controller: _yearOfStudyController, decoration: _fieldDecoration('Year'))),
            const SizedBox(height: 10),
            UserTagsField(label: 'Skills', values: _skills, enabled: !_saving, onChanged: (List<String> v) => setState(() => _skills = v)),
          ],
        ),
      );
    }

    if (UserProfileRules.needsFaculty(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.faculty,
          title: 'Faculty information',
          children: <Widget>[
            _labeledField('Specialization', TextField(controller: _specializationController, decoration: _fieldDecoration('Specialization'))),
            const SizedBox(height: 10),
            UserTagsField(
              label: 'Research interests',
              values: _researchInterests,
              enabled: !_saving,
              onChanged: (List<String> v) => setState(() => _researchInterests = v),
            ),
          ],
        ),
      );
    }

    if (UserProfileRules.needsJudge(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.judges,
          title: 'Judge information',
          children: <Widget>[
            _labeledField(
              'Judge type',
              HackzSelectField<JudgeType>(
                value: _judgeType,
                hint: 'Select judge type',
                prefixIcon: AppIcons.judges,
                options: JudgeType.values,
                labelBuilder: (JudgeType type) => type.label,
                iconBuilder: _judgeTypeIcon,
                enabled: !_saving,
                onChanged: (JudgeType type) => setState(() => _judgeType = type),
              ),
            ),
            const SizedBox(height: 10),
            UserTagsField(
              label: 'Evaluation domains',
              values: _evaluationDomains,
              enabled: !_saving,
              onChanged: (List<String> v) => setState(() => _evaluationDomains = v),
            ),
          ],
        ),
      );
    }

    if (UserProfileRules.needsDepartmentAdmin(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.departments,
          title: 'Department admin information',
          children: <Widget>[
            _labeledField(
              'Office designation',
              TextField(controller: _deptAdminDesignationController, decoration: _fieldDecoration('HOD, Professor, etc.')),
            ),
          ],
        ),
      );
    }

    if (UserProfileRules.needsCollegeAdmin(_selectedRoles)) {
      sections.add(
        _profileBlock(
          icon: AppIcons.organizations,
          title: 'College admin information',
          children: <Widget>[
            _labeledField(
              'Office designation',
              TextField(controller: _collegeAdminDesignationController, decoration: _fieldDecoration('Principal, Dean, etc.')),
            ),
          ],
        ),
      );
    }

    return sections;
  }

  Widget _profileBlock({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18, color: const Color(0xFF4B5AA9)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _roleChipLabel(String code) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(AppIcons.forUserRoleCode(code), size: 16, color: const Color(0xFF475569)),
        const SizedBox(width: 6),
        Text(UserRoleLabels.labelForCode(code)),
      ],
    );
  }

  Widget _buildRolePicker() {
    final List<String> options = (widget.roleOptions ?? UserRole.values.map((UserRole r) => r.code).toList())
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    final String? rolesError = _errorFor(_UserFormField.roles);
    final bool hasRolesError = rolesError != null;

    return Container(
      width: double.infinity,
      padding: hasRolesError ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: hasRolesError
          ? BoxDecoration(
              color: _errorFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _errorBorder),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _fieldLabel('Roles', required: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((String code) {
              final bool selected = _selectedRoles.contains(code);
              return FilterChip(
                label: _roleChipLabel(code),
                selected: selected,
                showCheckmark: false,
                selectedColor: const Color(0xFFEEF2FF),
                side: BorderSide(
                  color: hasRolesError
                      ? _errorBorder
                      : (selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0)),
                ),
                onSelected: _saving
                    ? null
                    : (bool value) => setState(() {
                          _clearFieldError(_UserFormField.roles);
                          if (value) {
                            _selectedRoles.add(code);
                          } else if (_selectedRoles.length > 1) {
                            _selectedRoles.remove(code);
                          }
                        }),
              );
            }).toList(growable: false),
          ),
          if (hasRolesError) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              rolesError,
              style: const TextStyle(fontSize: 11, color: _errorAccent, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleReadOnlyChip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedRoles.map((String code) {
        return Chip(
          label: _roleChipLabel(code),
          backgroundColor: const Color(0xFFF5F3FF),
          side: const BorderSide(color: Color(0xFFE9D5FF)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(growable: false),
    );
  }

  Widget _readOnlyIconField({
    required String value,
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecorator(
      decoration: _fieldDecoration(hint, readOnly: true, prefixIcon: icon, errorText: errorText),
      child: Text(
        value.isEmpty ? hint : value,
        style: TextStyle(
          color: value.isEmpty ? const Color(0xFF7A7FA3) : const Color(0xFF202658),
          fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
        children: required
            ? const <TextSpan>[
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: _errorAccent, fontWeight: FontWeight.w700),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _labeledField(String label, Widget field, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel(label, required: required),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
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
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.isEdit ? 'Edit user' : 'Create user',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Text(
                  widget.isEdit ? 'Update identity, roles, and role-specific profile.' : 'Add a new Hackz user with role-aware profile sections.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
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
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6A38FF), foregroundColor: Colors.white),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEdit ? 'Save user' : 'Create user'),
            ),
          ),
        ],
      ),
    );
  }
}
