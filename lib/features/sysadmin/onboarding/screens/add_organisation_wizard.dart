import 'package:flutter/material.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/hackz_select_field.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../auth/widgets/signup/approval_timeline_vm.dart';
import '../../../auth/widgets/signup/approval_timeline_widget.dart';
import '../../../organization/models/enums/organization_type.dart';
import '../../../organization/models/organization_model.dart';
import '../../services/org_management_service.dart';
import '../../../user/models/user_model.dart';
import '../../../user/screens/create_user_dialog.dart';
import '../../../user/widgets/user_form_section.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';
import '../services/tenant_workspace_validator.dart';
import '../widgets/copy_organisation_code_button.dart';
import '../widgets/workspace_check_row.dart';

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
  bool _busy = false;
  bool _changed = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  OrganizationType _type = OrganizationType.college;
  String? _nameError;
  String? _addressError;
  String? _websiteError;
  String? _contactError;

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
      _step = item.isComplete ? OrganisationOnboardingStep.activate : item.nextStep;
      if (_workspaceId.isEmpty) {
        _workspaceId = OrganisationOnboardingService.defaultWorkspaceId;
      }
    } else {
      _step = OrganisationOnboardingStep.organisation;
      _workspaceId = OrganisationOnboardingService.defaultWorkspaceId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _website.dispose();
    _contact.dispose();
    super.dispose();
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
      case OrganisationOnboardingStep.hackzSetup:
        return AppIcons.orgSettings;
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
          _step = OrganisationOnboardingStep.validate;
        case OrganisationOnboardingStep.validate:
          final TenantRecord? tenant = _tenant;
          if (tenant == null) {
            throw const OrganisationOnboardingException('Connect a workspace first.');
          }
          if (!_checksRan || !TenantWorkspaceValidator.allPassed(_checks)) {
            final List<TenantWorkspaceCheck> checks =
                await OrganisationOnboardingService.validateWorkspace(_workspaceId);
            _checks = checks;
            _checksRan = true;
            return;
          }
          _tenant = await OrganisationOnboardingService.completeValidation(
            tenantId: tenant.tenantId,
            checks: _checks,
          );
          _changed = true;
          _step = OrganisationOnboardingStep.hackzSetup;
        case OrganisationOnboardingStep.hackzSetup:
          final TenantRecord? tenant = _tenant;
          final OrganizationModel? org = _organization;
          if (tenant == null || org == null) {
            throw const OrganisationOnboardingException('Complete earlier steps first.');
          }
          _tenant = await OrganisationOnboardingService.initialiseHackz(
            tenantId: tenant.tenantId,
            organisationId: org.id,
          );
          _changed = true;
          _step = OrganisationOnboardingStep.initialAdmin;
        case OrganisationOnboardingStep.initialAdmin:
          if (_admin == null) {
            throw const OrganisationOnboardingException('Add the initial administrator to continue.');
          }
          final TenantRecord? tenant = _tenant;
          if (tenant != null) {
            _tenant = await OrganisationOnboardingService.markAdministratorReady(tenant.tenantId);
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

  Future<void> _addAdmin() async {
    final OrganizationModel? org = _organization;
    if (org == null) return;
    final bool assigned = await showCreateUserDialog(
      context: context,
      roleCode: 'CADM',
      organization: org,
      initialUser: _admin,
    );
    if (!assigned) return;
    final UserModel? admin = await OrgManagementService.fetchCollegeAdmin(org.id);
    if (!mounted) return;
    setState(() {
      _admin = admin ?? _admin;
      _changed = true;
    });
    final String? tenantId = _tenant?.tenantId;
    if (tenantId != null && _admin != null) {
      _tenant = await OrganisationOnboardingService.markAdministratorReady(tenantId);
    }
  }

  void _back() {
    if (_busy || _stepIndex == 0) return;
    setState(() => _step = OrganisationOnboardingStep.values[_stepIndex - 1]);
  }

  String get _primaryLabel {
    switch (_step) {
      case OrganisationOnboardingStep.organisation:
        return 'Continue';
      case OrganisationOnboardingStep.firebase:
        return 'Connect workspace';
      case OrganisationOnboardingStep.validate:
        return _checksRan && TenantWorkspaceValidator.allPassed(_checks) ? 'Continue' : 'Run checks';
      case OrganisationOnboardingStep.hackzSetup:
        return 'Initialise Hackz';
      case OrganisationOnboardingStep.initialAdmin:
        return 'Continue';
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
      case OrganisationOnboardingStep.hackzSetup:
        return _setupStep();
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
      title: 'Organisation',
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
          Expanded(child: identity),
          const SizedBox(width: 12),
          Expanded(child: details),
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
      child: Column(
        children: workspaces.map((ApprovedTenantWorkspace workspace) {
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
        }).toList(growable: false),
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
      subtitle: 'Confirm the workspace is ready before Hackz is initialised.',
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

  Widget _setupStep() {
    return UserFormSection(
      title: 'Hackz setup',
      subtitle: 'Apply the minimum organisation settings this college needs to start.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Hackz will create default organisation settings only. Empty data collections are not created in advance.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
          ),
          SizedBox(height: 10),
          Text(
            'You can refine rules later from the college admin workspace.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _adminStep() {
    final UserModel? admin = _admin;
    return UserFormSection(
      title: 'Initial administrator',
      subtitle: 'This person will manage the college in Hackz.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (admin == null)
            const Text(
              'Add a college administrator using the standard Hackz user flow.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
            )
          else
            Text(
              '${admin.firstName} ${admin.lastName}'.trim().isEmpty ? admin.email : '${admin.firstName} ${admin.lastName}'.trim(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _addAdmin,
              icon: Icon(admin == null ? AppIcons.add : AppIcons.edit, size: 16),
              label: Text(admin == null ? 'Add administrator' : 'Edit administrator'),
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
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : (done || _stepIndex == 0 ? _close : _back),
              child: Text(done || _stepIndex == 0 ? 'Close' : 'Back'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _busy ? null : (done ? _close : _goNext),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
              ),
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: HkzProgressIndicator(size: 22, strokeWidth: 2.6))
                  : Text(done ? 'Done' : _primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
