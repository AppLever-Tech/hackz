import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../features/organization/models/enums/organization_access_status.dart';
import '../../../../features/organization/models/enums/organization_commercial_plan.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../features/organization/services/organisation_access.dart';
import '../services/organisation_onboarding_service.dart';

/// Organisation status and commercial plan on the SysAdmin listing card.
class OrganisationAccessControl extends StatefulWidget {
  const OrganisationAccessControl({
    super.key,
    required this.organization,
    required this.onChanged,
  });

  final OrganizationModel organization;
  final VoidCallback onChanged;

  @override
  State<OrganisationAccessControl> createState() => _OrganisationAccessControlState();
}

class _OrganisationAccessControlState extends State<OrganisationAccessControl> {
  bool _busy = false;

  OrganizationModel get _org => widget.organization;

  bool get _statusActive => _org.status == OrganizationAccessStatus.active;

  bool get _usable => OrganisationAccess.isGranted(_org);

  String get _statusCaption {
    if (!_statusActive) {
      return 'Organisation is inactive. Users cannot use Hackz.';
    }
    if (_org.commercialPlan.isTimeBound && !_usable) {
      return 'Organisation is active, but the annual validity window is missing or expired.';
    }
    return 'Organisation is commercially usable.';
  }

  Future<void> _save(OrganizationModel next) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await OrganisationOnboardingService.updateCommercialAccess(next);
      if (!mounted) return;
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Could not update organisation', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setActive(bool active) async {
    if (active) {
      if (_org.commercialPlan.isTimeBound &&
          !OrganisationAccess.isGranted(_org.copyWith(status: OrganizationAccessStatus.active))) {
        await FeedbackService.showWarning(
          context,
          title: 'Validity required',
          message: 'Set a valid From / Until window before activating an annual commercial plan.',
        );
        return;
      }
      final bool ok = await FeedbackService.showConfirmation(
        context,
        title: 'Activate organisation?',
        message:
            '"${_org.name}" will be commercially usable according to its commercial plan.',
        confirmLabel: 'Activate',
      );
      if (!ok) return;
      await _save(_org.copyWith(status: OrganizationAccessStatus.active));
      return;
    }
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Deactivate organisation?',
      message:
          '"${_org.name}" will be treated as inactive. Users will not be able to use Hackz until the organisation is activated again.',
      confirmLabel: 'Deactivate',
      dangerConfirm: true,
    );
    if (!ok) return;
    await _save(_org.copyWith(status: OrganizationAccessStatus.inactive));
  }

  Future<void> _setPlan(OrganizationCommercialPlan plan) async {
    if (plan == _org.commercialPlan) return;
    await _save(_org.copyWith(commercialPlan: plan));
  }

  Future<void> _pickDate({required bool from}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = from
        ? (_org.validFrom ?? now)
        : (_org.validUntil ?? now.add(const Duration(days: 365)));
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 10, 12, 31);
    DateTime safeInitial = initial;
    if (safeInitial.isBefore(firstDate)) safeInitial = firstDate;
    if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    DateTime? nextFrom = from ? picked : _org.validFrom;
    DateTime? nextUntil = from ? _org.validUntil : picked;
    if (nextFrom != null && nextUntil != null && nextUntil.isBefore(nextFrom)) {
      if (from) {
        nextUntil = nextFrom;
      } else {
        nextFrom = nextUntil;
      }
    }
    await _save(_org.copyWith(validFrom: nextFrom, validUntil: nextUntil));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF8FAFF), Color(0xFFF4F1FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _statusActive ? AppIcons.workflowApproved : AppIcons.lock,
                size: 16,
                color: _statusActive ? const Color(0xFF047857) : const Color(0xFF6A38FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Organisation status',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _statusCaption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _StatusToggle(
                  active: _statusActive,
                  onActive: () => _setActive(true),
                  onInactive: () => _setActive(false),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Commercial plan',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final OrganizationCommercialPlan plan in OrganizationCommercialPlan.values)
                _PlanChip(
                  label: plan.label,
                  selected: _org.commercialPlan == plan,
                  enabled: !_busy,
                  onTap: () => _setPlan(plan),
                ),
            ],
          ),
          if (_org.commercialPlan.isTimeBound) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'Validity period',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _DateChip(
                  label: 'From',
                  value: _org.validFrom,
                  enabled: !_busy,
                  onTap: () => _pickDate(from: true),
                ),
                _DateChip(
                  label: 'Until',
                  value: _org.validUntil,
                  enabled: !_busy,
                  onTap: () => _pickDate(from: false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.active,
    required this.onActive,
    required this.onInactive,
  });

  final bool active;
  final VoidCallback onActive;
  final VoidCallback onInactive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StatusPart(
            label: OrganizationAccessStatus.active.label,
            selected: active,
            selectedColor: const Color(0xFF047857),
            selectedFill: const Color(0xFFECFDF5),
            onTap: onActive,
          ),
          _StatusPart(
            label: OrganizationAccessStatus.inactive.label,
            selected: !active,
            selectedColor: const Color(0xFF64748B),
            selectedFill: const Color(0xFFF1F5F9),
            onTap: onInactive,
          ),
        ],
      ),
    );
  }
}

class _StatusPart extends StatelessWidget {
  const _StatusPart({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedFill,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedFill : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? selectedColor : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? const Color(0xFF5B21B6) : const Color(0xFF64748B);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(AppIcons.event, size: 14, color: Color(0xFF6A38FF)),
              const SizedBox(width: 6),
              Text(
                '$label ${_format(value)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _format(DateTime? value) {
    if (value == null) return '—';
    final String dd = value.day.toString().padLeft(2, '0');
    final String mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}';
  }
}
