import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../../core/ui/inputs/filter_pill.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';
import '../widgets/organisation_onboarding_card.dart';
import 'add_organisation_wizard.dart';

class OrganisationsOnboardingConsole extends StatefulWidget {
  const OrganisationsOnboardingConsole({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<OrganisationsOnboardingConsole> createState() => _OrganisationsOnboardingConsoleState();
}

enum _OnboardingFilter { all, setup, active }

class _OrganisationsOnboardingConsoleState extends State<OrganisationsOnboardingConsole> {
  _OnboardingFilter _filter = _OnboardingFilter.all;
  List<OrganisationOnboardingItem> _items = const <OrganisationOnboardingItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant OrganisationsOnboardingConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<OrganisationOnboardingItem> items = await OrganisationOnboardingService.load();
      if (!mounted) return;
      setState(() {
        _items = items;
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
    final bool changed = await showAddOrganisationWizard(context: context);
    if (changed && mounted) _reload();
  }

  List<OrganisationOnboardingItem> get _visible {
    switch (_filter) {
      case _OnboardingFilter.all:
        return _items;
      case _OnboardingFilter.setup:
        return _items.where((OrganisationOnboardingItem item) => item.status == TenantStatus.setup || !item.isComplete).toList(growable: false);
      case _OnboardingFilter.active:
        return _items.where((OrganisationOnboardingItem item) => item.isComplete).toList(growable: false);
    }
  }

  int get _setupCount =>
      _items.where((OrganisationOnboardingItem item) => !item.isComplete).length;

  int get _activeCount =>
      _items.where((OrganisationOnboardingItem item) => item.isComplete).length;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _body(mobile)),
        if (mobile && !_loading)
          MobileCreateFab(onPressed: _add, tooltip: 'Add organisation'),
      ],
    );
  }

  Widget _body(bool mobile) {
    if (_loading) {
      return const Center(child: HkzProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Unable to load organisations: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final List<OrganisationOnboardingItem> visible = _visible;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _toolbar(mobile),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            _empty()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return OrganisationOnboardingCard(
                  item: visible[index],
                  onChanged: _reload,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _toolbar(bool mobile) {
    final Widget filters = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterPill(
            selected: _filter == _OnboardingFilter.all,
            icon: AppIcons.organizations,
            label: 'All',
            count: _items.length,
            onTap: () => setState(() => _filter = _OnboardingFilter.all),
          ),
          const SizedBox(width: 8),
          FilterPill(
            selected: _filter == _OnboardingFilter.setup,
            icon: AppIcons.clock,
            label: 'Setup',
            count: _setupCount,
            onTap: () => setState(() => _filter = _OnboardingFilter.setup),
          ),
          const SizedBox(width: 8),
          FilterPill(
            selected: _filter == _OnboardingFilter.active,
            icon: AppIcons.workflowApproved,
            label: 'Active',
            count: _activeCount,
            onTap: () => setState(() => _filter = _OnboardingFilter.active),
          ),
        ],
      ),
    );
    if (mobile) return filters;
    return Row(
      children: <Widget>[
        Expanded(child: filters),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(AppIcons.add, size: 18),
          label: const Text('Add Organisation'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6A38FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: <Color>[Color(0xFFF8F5FF), Color(0xFFEEF2FF)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(AppIcons.organizations, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'No organisations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Register a college and make it ready to use Hackz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Add Organisation'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6A38FF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
