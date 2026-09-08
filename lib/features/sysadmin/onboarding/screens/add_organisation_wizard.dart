import 'package:flutter/material.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/hackz_provisioning_client.dart';
import '../../../../core/firebase/hackz_provisioning_identity.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/email_field.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/hackz_select_field.dart';
import '../../../../core/ui/inputs/phone_number_field.dart';
import '../../../../core/ui/loading/loading.dart';
import '../../../../utils/common_helpers.dart';
import '../../../auth/widgets/signup/approval_timeline_vm.dart';
import '../../../auth/widgets/signup/approval_timeline_widget.dart';
import '../../../organization/models/enums/organization_type.dart';
import '../../../organization/models/organization_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/enums/user_status.dart';
import '../../../user/models/user_model.dart';
import '../../../user/widgets/user_form_section.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';
import '../services/provisioning_authorization_validator.dart';
import '../services/tenant_workspace_validator.dart';
import '../widgets/college_authorization_panel.dart';
import '../widgets/copy_organisation_code_button.dart';
import '../widgets/onboarding_readiness_checklist.dart';
import '../widgets/workspace_check_row.dart';
import 'register_workspace_dialog.dart';

Future<bool> showAddOrganisationWizard({
  required BuildContext context,
  OrganisationOnboardingItem? item,
}) async {
  final bool? done = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) => AddOrganisationWizard(item: item),
  );
  return done ?? false;
}

class AddOrganisationWizard extends StatefulWidget {
  const AddOrganisationWizard({super.key, this.item});

  final OrganisationOnboardingItem? item;

  @override
  State<AddOrganisationWizard> createState() => _AddOrganisationWizardState();
}

class _AddOrganisationWizardState extends State<AddOrganisationWizard> {
  late OrganisationOnboardingStep _step;
  OrganizationModel? _organization;
  TenantRecord? _tenant;
  UserModel? _admin;
  String _workspaceId = '';
  List<TenantWorkspaceCheck> _checks = const <TenantWorkspaceCheck>[];
  bool _checksRan = false;
  List<TenantWorkspaceCheck> _authorizationChecks = const <TenantWorkspaceCheck>[];
  bool _authorizationRan = false;
  HackzProvisioningIdentity? _provisioningIdentity;
  bool _busy = false;
  bool _changed = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _adminFirstName = TextEditingController();
  final TextEditingController _adminLastName = TextEditingController();
  final TextEditingController _adminEmail = TextEditingController();
  final TextEditingController _adminPhone = TextEditingController();
  OrganizationType _type = OrganizationType.college;
  String? _nameError;
  String? _addressError;
  String? _websiteError;
  String? _contactError;
  String? _adminFirstNameError;
  String? _adminLastNameError;
  String? _adminEmailError;
  String? _adminPhoneError;

  @override
  void initState() {
    super.initState();
    final OrganisationOnboardingItem? item = widget.item;
    if (item != null) {
      _organization = item.organization;
      _tenant = item.tenant;
      _admin = item.collegeAdmin;
      _workspaceId = (item.tenant?.firebaseProjectId ?? '').trim();
      _name.text = item.organization.name;
      _address.text = item.organization.address;
      _website.text = item.organization.website;
      _contact.text = item.organization.contact;
      _type = item.organization.type;
      _hydrateAdminForm(item.collegeAdmin);
      _step = item.isComplete ? OrganisationOnboardingStep.activate : item.nextStep;
      if (_workspaceId.isEmpty) {
        _workspaceId = OrganisationOnboardingService.defaultWorkspaceId;
      }
    } else {
      _step = OrganisationOnboardingStep.organisation;
      _workspaceId = OrganisationOnboardingService.defaultWorkspaceId;
    }
    ApprovedTenantFirebase.refresh().then((_) {
      if (mounted) setState(() {});
    });
    HackzProvisioningIdentity.load().then((HackzProvisioningIdentity identity) {
      if (mounted) setState(() => _provisioningIdentity = identity);
    });
    _adminEmail.addListener(() {
      if (_adminEmailError != null && mounted) setState(() => _adminEmailError = null);
    });
    _adminPhone.addListener(() {
      if (_adminPhoneError != null && mounted) setState(() => _adminPhoneError = null);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _website.dispose();
    _contact.dispose();
    _adminFirstName.dispose();
    _adminLastName.dispose();
    _adminEmail.dispose();
    _adminPhone.dispose();
    super.dispose();
  }

  void _hydrateAdminForm(UserModel? admin) {
    if (admin == null) return;
    _adminFirstName.text = admin.firstName;
    _adminLastName.text = admin.lastName;
    _adminEmail.text = admin.email;
    _adminPhone.text = admin.phone.replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
  }

  int get _stepIndex => OrganisationOnboardingStep.values.indexOf(_step);

  List<ApprovalTimelineStepVm> get _timeline {
    return OrganisationOnboardingStep.values.map((OrganisationOnboardingStep step) {
      final int i = OrganisationOnboardingStep.values.indexOf(step);
      final ApprovalTimelineNodeState state;
      if (i < _stepIndex) {
        state = ApprovalTimelineNodeState.completed;
      } else if (i == _stepIndex) {
        state = ApprovalTimelineNodeState.current;
      } else {
        state = ApprovalTimelineNodeState.upcoming;
      }
      return ApprovalTimelineStepVm(icon: _iconFor(step), title: step.label, state: state);
    }).toList(growable: false);
  }

  IconData _iconFor(OrganisationOnboardingStep step) {
    switch (step) {
      case OrganisationOnboardingStep.organisation:
        return AppIcons.organizations;
      case OrganisationOnboardingStep.firebase:
        return AppIcons.verification;
      case OrganisationOnboardingStep.validate:
        return AppIcons.checklist;
      case OrganisationOnboardingStep.authorization:
        return AppIcons.lock;
      case OrganisationOnboardingStep.initialAdmin:
        return AppIcons.adminProfile;
      case OrganisationOnboardingStep.activate:
        return AppIcons.key;
    }
  }

  void _close() => Navigator.of(context).pop(_changed);

  Future<void> _fail(Object error) async {
    if (!mounted) return;
    await FeedbackService.showError(
      context,
      title: 'Unable to continue',
      message: '$error',
    );
  }

  bool _validateOrganisation() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Organisation name is required.' : null;
      _addressError = _address.text.trim().isEmpty ? 'Address is required.' : null;
      _websiteError = _website.text.trim().isEmpty ? 'Website is required.' : null;
      _contactError = _contact.text.trim().isEmpty ? 'Contact is required.' : null;
    });
    return _nameError == null && _addressError == null && _websiteError == null && _contactError == null;
  }

  bool get _adminAlreadyProvisioned =>
      (_tenant?.initialAdminConfigured ?? false) || _admin != null;

  bool _validateAdmin() {
    setState(() {
      _adminFirstNameError = _adminFirstName.text.trim().isEmpty ? 'First name is required.' : null;
      _adminLastNameError = _adminLastName.text.trim().isEmpty ? 'Last name is required.' : null;
      final String email = _adminEmail.text.trim();
      if (email.isEmpty) {
        _adminEmailError = 'Email is required.';
      } else if (!isValidEmailInput(email)) {
        _adminEmailError = 'Enter a valid email address.';
      } else {
        _adminEmailError = null;
      }
      if (_adminPhone.text.replaceAll(RegExp(r'\D'), '').isEmpty) {
        _adminPhoneError = 'Mobile is required.';
      } else if (!isValidPhoneInput(_adminPhone.text)) {
        _adminPhoneError = 'Enter a valid 10-digit mobile number.';
      } else {
        _adminPhoneError = null;
      }
    });
    return _adminFirstNameError == null &&
        _adminLastNameError == null &&
        _adminEmailError == null &&
        _adminPhoneError == null;
  }

  UserModel _collegeAdminFromProvision({
    required HackzProvisioningResult result,
    required TenantRecord tenant,
  }) {
    return UserModel(
      userId: result.userId,
      phone: result.phone,
      firstName: _adminFirstName.text.trim(),
      lastName: _adminLastName.text.trim(),
      email: result.email,
      role: UserRole.collegeAdmin.code,
      roles: <String>[UserRole.collegeAdmin.code],
      orgType: OrganizationType.college,
      orgId: tenant.organisationId,
      department: '',
      departmentCode: '',
      status: UserStatus.active,
      createdAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );
  }

  Future<void> _goNext() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (_step) {
        case OrganisationOnboardingStep.organisation:
          if (!_validateOrganisation()) return;
          final OrganizationModel draft = (_organization ??
                  OrganizationModel(
                    id: '',
                    name: '',
                    type: _type,
                    address: '',
                    website: '',
                    contact: '',
                    createdAt: DateTime.now(),
                  ))
              .copyWith(
            name: _name.text.trim(),
            type: _type,
            address: _address.text.trim(),
            website: _website.text.trim(),
            contact: _contact.text.trim(),
          );
          final OrganisationOnboardingItem saved = await OrganisationOnboardingService.saveOrganisation(
            draft: draft,
            existingTenant: _tenant,
          );
          _organization = saved.organization;
          _tenant = saved.tenant;
          _changed = true;
          _step = OrganisationOnboardingStep.firebase;
        case OrganisationOnboardingStep.firebase:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Save the organisation first.');
          }
          if (!ApprovedTenantFirebase.isApproved(_workspaceId)) {
            throw const OrganisationOnboardingException('Choose an approved Hackz workspace.');
          }
          _tenant = await OrganisationOnboardingService.connectWorkspace(
            tenantId: tenant.tenantId,
            firebaseProjectId: _workspaceId,
          );
          _changed = true;
          _checks = const <TenantWorkspaceCheck>[];
          _checksRan = false;
          _authorizationChecks = const <TenantWorkspaceCheck>[];
          _authorizationRan = false;
          _step = OrganisationOnboardingStep.validate;
        case OrganisationOnboardingStep.validate:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Connect a workspace first.');
          }
          if (!_checksRan || !TenantWorkspaceValidator.allPassed(_checks)) {
            final List<TenantWorkspaceCheck> checks = await HkzAsyncLoader.run<List<TenantWorkspaceCheck>>(
              context,
              title: 'Checking workspace',
              message: 'Preparing workspace checks...',
              successMessage: 'All checks completed',
              successHold: const Duration(milliseconds: 900),
              task: () {
                return OrganisationOnboardingService.validateWorkspace(
                  _workspaceId,
                  onProgress: (String message, double progress) {
                    HkzAsyncLoader.update(message: message, progress: progress);
                  },
                );
              },
            );
            _checks = checks;
            _checksRan = true;
            return;
          }
          _tenant = await OrganisationOnboardingService.completeValidation(
            tenantId: tenant.tenantId,
            checks: _checks,
          );
          _changed = true;
          _step = OrganisationOnboardingStep.authorization;
        case OrganisationOnboardingStep.authorization:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Connect a workspace first.');
          }
          if (tenant.provisioningAuthorization == ProvisioningAuthorizationStatus.required) {
            _tenant = await OrganisationOnboardingService.markAuthorizationPending(tenant.tenantId);
          }
          if (!mounted) return;
          if (!_authorizationRan ||
              !ProvisioningAuthorizationValidator.allPassed(_authorizationChecks)) {
            final List<TenantWorkspaceCheck> checks =
                await HkzAsyncLoader.run<List<TenantWorkspaceCheck>>(
              context,
              title: 'Validate authorization',
              message: 'Checking provisioning access...',
              successMessage: 'Authorization checks completed',
              successHold: const Duration(milliseconds: 900),
              task: () {
                return OrganisationOnboardingService.validateProvisioningAuthorization(_workspaceId);
              },
            );
            _authorizationChecks = checks;
            _authorizationRan = true;
            _tenant = await OrganisationOnboardingService.completeProvisioningAuthorization(
              tenantId: tenant.tenantId,
              checks: checks,
              previous: (_tenant ?? tenant).provisioningAuthorization,
            );
            _changed = true;
            return;
          }
          if (_tenant?.provisioningAuthorization.isAuthorized != true) {
            throw const OrganisationOnboardingException(
              'The college must authorize Hackz provisioning before continuing.',
            );
          }
          _changed = true;
          _step = OrganisationOnboardingStep.initialAdmin;
        case OrganisationOnboardingStep.initialAdmin:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Connect a workspace first.');
          }
          if (!tenant.provisioningAuthorization.isAuthorized) {
            throw const OrganisationOnboardingException(
              'The college must authorize Hackz provisioning before creating the College Admin.',
            );
          }
          if (!_adminAlreadyProvisioned) {
            if (!_validateAdmin()) return;
            final HackzProvisioningResult result = await HkzAsyncLoader.run<HackzProvisioningResult>(
              context,
              title: 'Create College Admin',
              message: 'Provisioning the administrator on the college Firebase project...',
              successMessage: 'College Admin created',
              successHold: const Duration(milliseconds: 900),
              task: () {
                return OrganisationOnboardingService.provisionInitialCollegeAdmin(
                  tenant: tenant,
                  firstName: _adminFirstName.text.trim(),
                  lastName: _adminLastName.text.trim(),
                  email: _adminEmail.text.trim(),
                  phone: normalizePhoneE164(_adminPhone.text),
                );
              },
            );
            _admin = _collegeAdminFromProvision(result: result, tenant: tenant);
            _tenant = tenant.copyWith(initialAdminConfigured: true);
          } else if (!(tenant.initialAdminConfigured)) {
            _tenant = await OrganisationOnboardingService.markAdministratorReady(tenant.tenantId);
          }
          final TenantRecord ready = _tenant ?? tenant;
          if (ready.status != TenantStatus.active) {
            try {
              _tenant = await OrganisationOnboardingService.activate(ready.tenantId);
            } catch (error) {
              _changed = true;
              _step = OrganisationOnboardingStep.activate;
              rethrow;
            }
          }
          _changed = true;
          _step = OrganisationOnboardingStep.activate;
        case OrganisationOnboardingStep.activate:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Complete earlier steps first.');
          }
          _tenant = await OrganisationOnboardingService.activate(tenant.tenantId);
          _changed = true;
      }
    } catch (e) {
      await _fail(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerWorkspace() async {
    final bool saved = await showRegisterWorkspaceDialog(context: context);
    if (!saved) return;
    await ApprovedTenantFirebase.refresh();
    if (mounted) setState(() {});
  }

  String get _primaryLabel {
    switch (_step) {
      case OrganisationOnboardingStep.organisation:
        return 'Continue';
      case OrganisationOnboardingStep.firebase:
        return 'Connect workspace';
      case OrganisationOnboardingStep.validate:
        return _checksRan && TenantWorkspaceValidator.allPassed(_checks) ? 'Continue' : 'Run checks';
      case OrganisationOnboardingStep.authorization:
        return _authorizationRan &&
                ProvisioningAuthorizationValidator.allPassed(_authorizationChecks)
            ? 'Continue'
            : 'Validate authorization';
      case OrganisationOnboardingStep.initialAdmin:
        return _adminAlreadyProvisioned ? 'Continue' : 'Create College Admin';
      case OrganisationOnboardingStep.activate:
        return _tenant != null && _tenant!.status == TenantStatus.active ? 'Done' : 'Activate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.extraWide,
      maxWidth: 920,
      contentPadding: EdgeInsets.zero,
      footer: _footer(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveHelper.isMobile(context) ? 16 : 22,
          ResponsiveHelper.isMobile(context) ? 10 : 16,
          ResponsiveHelper.isMobile(context) ? 16 : 22,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _hero(),
            const SizedBox(height: 14),
            ApprovalTimelineWidget(steps: _timeline),
            const SizedBox(height: 16),
            _stepBody(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(AppIcons.organizations, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add organisation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Text(
                'Register a college and make it ready to use Hackz.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case OrganisationOnboardingStep.organisation:
        return _organisationStep();
      case OrganisationOnboardingStep.firebase:
        return _workspaceStep();
      case OrganisationOnboardingStep.validate:
        return _validateStep();
      case OrganisationOnboardingStep.authorization:
        return _authorizationStep();
      case OrganisationOnboardingStep.initialAdmin:
        return _adminStep();
      case OrganisationOnboardingStep.activate:
        return _activateStep();
    }
  }

  InputDecoration _decoration(String hint, {String? error, IconData? icon, int minLines = 1}) {
    return HackzInputDecoration.decorate(
      hintText: hint,
      errorText: error,
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: HackzInputDecoration.iconColor),
      contentPaddingOverride: minLines > 1 ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12) : null,
    );
  }

  Widget _organisationStep() {
    final bool wide = !ResponsiveHelper.isMobile(context);
    final Widget identity = UserFormSection(
      title: 'Identity',
      subtitle: 'Name and type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HackzInputDecoration.labeledField(
            label: 'Organisation name',
            required: true,
            field: TextField(
              controller: _name,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration('Enter organisation name', error: _nameError, icon: AppIcons.organizations),
              onChanged: (_) => setState(() => _nameError = null),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Type',
            required: true,
            field: HackzSelectField<OrganizationType>(
              value: _type,
              hint: 'Select organisation type',
              enabled: !_busy,
              prefixIcon: AppIcons.forOrganizationType(_type),
              options: OrganizationType.values,
              labelBuilder: (OrganizationType t) => t.displayName,
              iconBuilder: AppIcons.forOrganizationType,
              onChanged: (OrganizationType t) => setState(() => _type = t),
            ),
          ),
        ],
      ),
    );
    final Widget details = UserFormSection(
      title: 'Details',
      subtitle: 'Address and how to reach this organisation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HackzInputDecoration.labeledField(
            label: 'Address',
            required: true,
            field: TextField(
              controller: _address,
              enabled: !_busy,
              minLines: 3,
              maxLines: 3,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration('Street, city, state, PIN...', error: _addressError, icon: AppIcons.address, minLines: 3),
              onChanged: (_) => setState(() => _addressError = null),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Website',
            required: true,
            field: TextField(
              controller: _website,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration('https://example.com', error: _websiteError, icon: AppIcons.website),
              onChanged: (_) => setState(() => _websiteError = null),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Contact',
            required: true,
            field: TextField(
              controller: _contact,
              enabled: !_busy,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration('Phone or contact person', error: _contactError, icon: AppIcons.phone),
              onChanged: (_) => setState(() => _contactError = null),
            ),
          ),
        ],
      ),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 5, child: identity),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: details),
        ],
      );
    }
    return Column(
      children: <Widget>[identity, const SizedBox(height: 10), details],
    );
  }

  Widget _workspaceStep() {
    final List<ApprovedTenantWorkspace> workspaces = ApprovedTenantFirebase.workspaces;
    return UserFormSection(
      title: 'Workspace connection',
      subtitle: 'Connect this college to an approved Hackz workspace. Colleges do not configure platform internals.',
      trailing: TextButton.icon(
        onPressed: _busy ? null : _registerWorkspace,
        icon: const Icon(AppIcons.add, size: 16),
        label: const Text('Register another workspace'),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < workspaces.length; i++) ...<Widget>[
            _workspaceTile(workspaces[i]),
            if (i != workspaces.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _workspaceTile(ApprovedTenantWorkspace workspace) {
    final bool selected = _workspaceId == workspace.projectId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : () => setState(() => _workspaceId = workspace.projectId),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? AppIcons.workflowApproved : AppIcons.verification,
                color: selected ? const Color(0xFF6A38FF) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      workspace.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workspace.subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _validateStep() {
    final List<TenantWorkspaceCheck> pending = _checksRan
        ? _checks
        : const <TenantWorkspaceCheck>[
            TenantWorkspaceCheck(id: 'connection', label: 'Platform connection', ok: false, detail: 'Not checked yet.'),
            TenantWorkspaceCheck(id: 'auth', label: 'Sign-in ready', ok: false, detail: 'Not checked yet.'),
            TenantWorkspaceCheck(id: 'data', label: 'Workspace data ready', ok: false, detail: 'Not checked yet.'),
            TenantWorkspaceCheck(id: 'files', label: 'File storage ready', ok: false, detail: 'Not checked yet.'),
            TenantWorkspaceCheck(id: 'access', label: 'Administrator access', ok: false, detail: 'Not checked yet.'),
          ];
    return UserFormSection(
      title: 'Workspace checks',
      subtitle: 'Confirm the workspace is ready before this organisation is activated.',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < pending.length; i++) ...<Widget>[
            WorkspaceCheckRow(check: pending[i], pending: !_checksRan),
            if (i != pending.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _authorizationStep() {
    final List<TenantWorkspaceCheck> pending = _authorizationRan
        ? _authorizationChecks
        : const <TenantWorkspaceCheck>[
            TenantWorkspaceCheck(
              id: 'project',
              label: 'Tenant Firebase project',
              ok: false,
              detail: 'Not checked yet.',
            ),
            TenantWorkspaceCheck(
              id: 'identity',
              label: 'Hackz provisioning identity',
              ok: false,
              detail: 'Not checked yet.',
            ),
            TenantWorkspaceCheck(
              id: 'auth',
              label: 'Firebase Authentication',
              ok: false,
              detail: 'Not checked yet.',
            ),
            TenantWorkspaceCheck(
              id: 'firestore',
              label: 'Firestore',
              ok: false,
              detail: 'Not checked yet.',
            ),
          ];
    return UserFormSection(
      title: 'College Controls Authorization',
      subtitle: 'The college grants Hackz limited provisioning access on its own Firebase project.',
      child: CollegeAuthorizationPanel(
        projectId: _workspaceId,
        identity: _provisioningIdentity ??
            const HackzProvisioningIdentity(
              serviceAccountEmail: 'hackz-provisioning@pending.iam.gserviceaccount.com',
              iamRoles: HackzProvisioningIdentity.minimumIamRoles,
            ),
        status: _tenant?.provisioningAuthorization ?? ProvisioningAuthorizationStatus.required,
        lastValidatedAt: _tenant?.provisioningAuthorizationValidatedAt,
        checks: pending,
        checksRan: _authorizationRan,
      ),
    );
  }

  Widget _adminStep() {
    final bool locked = _adminAlreadyProvisioned;
    final bool invokeMissing = (_provisioningIdentity?.invokeUrl ?? '').trim().isEmpty;
    return UserFormSection(
      title: 'Initial College Admin',
      subtitle: locked
          ? 'This College Admin is provisioned on the college Firebase project.'
          : 'Hackz will create this College Admin on the college Firebase project. No photo is collected.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (invokeMissing && !locked) ...<Widget>[
            const Text(
              'Set hkzProvisioningConfig/hackz.invokeUrl to the Cloud Run provisioner (or http://localhost:8787 for local development).',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 12),
          ],
          HackzInputDecoration.labeledField(
            label: 'First name',
            required: true,
            field: TextField(
              controller: _adminFirstName,
              enabled: !_busy && !locked,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration(
                'First name',
                error: _adminFirstNameError,
                icon: AppIcons.faculty,
              ),
              onChanged: (_) => setState(() => _adminFirstNameError = null),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Last name',
            required: true,
            field: TextField(
              controller: _adminLastName,
              enabled: !_busy && !locked,
              style: HackzInputDecoration.fieldTextStyle,
              decoration: _decoration(
                'Last name',
                error: _adminLastNameError,
                icon: AppIcons.faculty,
              ),
              onChanged: (_) => setState(() => _adminLastNameError = null),
            ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Email',
            required: true,
            field: locked
                ? TextField(
                    controller: _adminEmail,
                    enabled: false,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('Email', icon: AppIcons.email),
                  )
                : EmailField(
                    controller: _adminEmail,
                    decoration: _decoration(
                      'Email',
                      error: _adminEmailError,
                      icon: AppIcons.email,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Mobile',
            required: true,
            field: locked
                ? TextField(
                    controller: _adminPhone,
                    enabled: false,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('Mobile', icon: AppIcons.phone),
                  )
                : PhoneNumberField(
                    controller: _adminPhone,
                    decoration: _decoration(
                      '10-digit mobile number',
                      error: _adminPhoneError,
                      icon: AppIcons.phone,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.labeledField(
            label: 'Role / type',
            required: true,
            field: InputDecorator(
              decoration: _decoration('College Admin', icon: AppIcons.adminProfile),
              child: const Text(
                'collegeAdmin',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activateStep() {
    final TenantRecord? tenant = _tenant;
    final bool active = tenant != null && tenant.status == TenantStatus.active;
    final String code = tenant?.organisationCode ?? '';
    return UserFormSection(
      title: active ? 'Organisation is ready' : 'Activate organisation',
      subtitle: active
          ? 'Share this code with the college. It is the routing key for this organisation.'
          : 'Hackz will assign a unique organisation code. It cannot be changed later.',
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFFF8F5FF), Color(0xFFEEF2FF)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  'Organisation code',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        active && code.isNotEmpty ? code : 'HKZ-••••••',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: active ? const Color(0xFF4C1D95) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    if (active && code.isNotEmpty) CopyOrganisationCodeButton(code: code),
                  ],
                ),
                if (active) ...<Widget>[
                  const SizedBox(height: 10),
                  const Text(
                    'Onboarding complete. This organisation is active in the Hackz registry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                  ),
                ],
              ],
            ),
          ),
          if (_organization != null) ...<Widget>[
            const SizedBox(height: 14),
            OnboardingReadinessChecklist(
              item: OrganisationOnboardingItem(
                organization: _organization!,
                tenant: _tenant,
                collegeAdmin: _admin,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    final bool done = _step == OrganisationOnboardingStep.activate &&
        _tenant != null &&
        _tenant!.status == TenantStatus.active;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
      ),
      child: Row(
        children: <Widget>[
          OutlinedButton(
            onPressed: _busy ? null : _close,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Close'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _busy ? null : (done ? _close : _goNext),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6A38FF),
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: HkzProgressIndicator(size: 18, strokeWidth: 2.4))
                : Text(done ? 'Done' : _primaryLabel),
          ),
        ],
      ),
    );
  }
}
