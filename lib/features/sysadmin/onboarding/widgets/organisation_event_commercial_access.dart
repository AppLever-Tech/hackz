import 'package:flutter/material.dart';

import '../../../../core/firebase/hackz_provisioning_client.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/loading/hkz_async_loader.dart';
import '../../../../features/organization/models/enums/organization_commercial_plan.dart';
import '../../../../utils/common_helpers.dart';
import '../models/event_entitlement.dart';
import '../models/organisation_event_commercial_item.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';

/// SysAdmin commercial entitlement on the organisation card. Not event administration.
class OrganisationEventCommercialAccess extends StatefulWidget {
  const OrganisationEventCommercialAccess({
    super.key,
    required this.item,
  });

  final OrganisationOnboardingItem item;

  @override
  State<OrganisationEventCommercialAccess> createState() => _OrganisationEventCommercialAccessState();
}

class _OrganisationEventCommercialAccessState extends State<OrganisationEventCommercialAccess> {
  EventEntitlementDisplayState? _filter;
  List<OrganisationEventCommercialItem> _items = const <OrganisationEventCommercialItem>[];
  bool _loading = true;
  String? _error;
  String? _busyEventId;

  OrganizationCommercialPlan get _plan => widget.item.organization.commercialPlan;

  bool get _perEvent => _plan == OrganizationCommercialPlan.perEvent;

  String get _tenantId => (widget.item.tenant?.tenantId ?? '').trim();

  String get _caption => switch (_plan) {
        OrganizationCommercialPlan.perEvent =>
          'Events requiring commercial activation. Record payment, then activate. Event configuration is unchanged.',
        OrganizationCommercialPlan.annual =>
          'Events are automatically enabled by the annual contract while it is valid. Per-event approval is not required.',
        OrganizationCommercialPlan.perIdea =>
          'Events follow the organisation\'s Per idea commercial plan. Per-event activation is not required.',
      };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(OrganisationEventCommercialAccess oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.organization.id != widget.item.organization.id ||
        oldWidget.item.organization.commercialPlan != widget.item.organization.commercialPlan ||
        (oldWidget.item.tenant?.tenantId ?? '') != (widget.item.tenant?.tenantId ?? '')) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<OrganisationEventCommercialItem> items =
          await OrganisationOnboardingService.listEventCommercialAccess(
        organization: widget.item.organization,
        tenantId: _tenantId,
      );
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

  List<OrganisationEventCommercialItem> get _visible {
    final EventEntitlementDisplayState? filter = _filter;
    if (!_perEvent || filter == null) return _items;
    return _items.where((OrganisationEventCommercialItem item) => item.perEventFilterState == filter).toList();
  }

  int _count(EventEntitlementDisplayState state) =>
      _items.where((OrganisationEventCommercialItem item) => item.perEventFilterState == state).length;

  Future<void> _recordPayment(OrganisationEventCommercialItem item) async {
    final EventEntitlement? entitlement = item.entitlement;
    if (entitlement == null) return;
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Record event payment?',
      message:
          'Mark the agreed commercial payment for "${item.eventName}" as received. This does not copy tenant payment transactions and does not change event configuration.',
      confirmLabel: 'Record payment',
    );
    if (!ok) return;
    if (!mounted) return;
    if (_busyEventId != null) return;
    setState(() => _busyEventId = item.eventId);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Record payment',
        message: item.eventName,
        successMessage: 'Event payment recorded.',
        task: () async {
          await HackzProvisioningClient.recordEventEntitlementPayment(
            organisationId: entitlement.orgId,
            eventId: entitlement.eventId,
          );
        },
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Could not record event payment', message: '$e');
    } finally {
      if (mounted) setState(() => _busyEventId = null);
    }
  }

  Future<void> _activate(OrganisationEventCommercialItem item) async {
    final EventEntitlement? entitlement = item.entitlement;
    if (entitlement == null) return;
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Activate event access?',
      message:
          'This enables "${item.eventName}" for ${widget.item.name}. Event configuration is unchanged.',
      confirmLabel: 'Activate',
    );
    if (!ok) return;
    if (!mounted) return;
    await _setStatus(
      entitlement,
      EventEntitlementStatus.enabled,
      title: 'Activate event',
      success: 'Event access enabled for ${widget.item.name}.',
    );
  }

  Future<void> _disable(OrganisationEventCommercialItem item) async {
    final EventEntitlement? entitlement = item.entitlement;
    if (entitlement == null) return;
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Disable event access?',
      message:
          '"${item.eventName}" will no longer be commercially enabled for ${widget.item.name}. Event configuration is unchanged.',
      confirmLabel: 'Disable',
      dangerConfirm: true,
    );
    if (!ok) return;
    if (!mounted) return;
    await _setStatus(
      entitlement,
      EventEntitlementStatus.disabled,
      title: 'Disable event',
      success: 'Event access disabled.',
    );
  }

  Future<void> _setStatus(
    EventEntitlement entitlement,
    EventEntitlementStatus status, {
    required String title,
    required String success,
  }) async {
    if (_busyEventId != null) return;
    setState(() => _busyEventId = entitlement.eventId);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: title,
        message: entitlement.eventName,
        successMessage: success,
        task: () async {
          await HackzProvisioningClient.setEventEntitlementStatus(
            organisationId: entitlement.orgId,
            eventId: entitlement.eventId,
            status: status.wireValue,
          );
        },
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Could not update event access', message: '$e');
    } finally {
      if (mounted) setState(() => _busyEventId = null);
    }
  }

  String get _emptyMessage {
    if (_perEvent) return 'No events requiring commercial activation yet.';
    if (_tenantId.isEmpty) return 'Connect the organisation workspace to see events.';
    return 'No events yet.';
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
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
              const Icon(AppIcons.event, size: 16, color: Color(0xFF6A38FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Events / Commercial Access',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _caption,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              if (_loading || _busyEventId != null)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: _reload,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(AppIcons.refresh, size: 16, color: Color(0xFF6A38FF)),
                  ),
                ),
            ],
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
          ] else if (!_loading && _items.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _emptyMessage,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ] else if (_items.isNotEmpty) ...<Widget>[
            if (_perEvent) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _FilterChip(
                    label: 'All',
                    count: _items.length,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final EventEntitlementDisplayState state in EventEntitlementDisplayState.values)
                    _FilterChip(
                      label: state.label,
                      count: _count(state),
                      selected: _filter == state,
                      color: _toneColor(_toneForDisplay(state)),
                      onTap: () => setState(() => _filter = state),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (_visible.isEmpty)
              const Text(
                'No events in this filter.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              )
            else if (mobile)
              ...<Widget>[
                for (final OrganisationEventCommercialItem item in _visible) ...<Widget>[
                  _EventCommercialCard(
                    item: item,
                    busy: _busyEventId == item.eventId,
                    enabled: _busyEventId == null,
                    onRecordPayment: item.canRecordPayment ? () => _recordPayment(item) : null,
                    onActivate: item.canActivate ? () => _activate(item) : null,
                    onDisable: item.canDisable ? () => _disable(item) : null,
                  ),
                  const SizedBox(height: 8),
                ],
              ]
            else
              _EventCommercialTable(
                items: _visible,
                busyEventId: _busyEventId,
                onRecordPayment: _recordPayment,
                onActivate: _activate,
                onDisable: _disable,
              ),
          ],
        ],
      ),
    );
  }
}

class _EventCommercialTable extends StatelessWidget {
  const _EventCommercialTable({
    required this.items,
    required this.busyEventId,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onDisable,
  });

  final List<OrganisationEventCommercialItem> items;
  final String? busyEventId;
  final ValueChanged<OrganisationEventCommercialItem> onRecordPayment;
  final ValueChanged<OrganisationEventCommercialItem> onActivate;
  final ValueChanged<OrganisationEventCommercialItem> onDisable;

  static const double _minWidth = 920;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : _minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: width < _minWidth ? _minWidth : width),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: <Widget>[
                  const _TableHeader(),
                  for (int i = 0; i < items.length; i++)
                    _TableRow(
                      item: items[i],
                      striped: i.isOdd,
                      busy: busyEventId == items[i].eventId,
                      enabled: busyEventId == null,
                      onRecordPayment: items[i].canRecordPayment ? () => onRecordPayment(items[i]) : null,
                      onActivate: items[i].canActivate ? () => onActivate(items[i]) : null,
                      onDisable: items[i].canDisable ? () => onDisable(items[i]) : null,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8F4))),
      ),
      child: const Row(
        children: <Widget>[
          _HeaderCell('Event', flex: 3),
          _HeaderCell('Template', flex: 2),
          _HeaderCell('Commercial Plan', flex: 2),
          _HeaderCell('Payment', flex: 2),
          _HeaderCell('Commercial Access', flex: 3),
          _HeaderCell('Created', flex: 2),
          _HeaderCell('Action', flex: 3),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.item,
    required this.striped,
    required this.busy,
    required this.enabled,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onDisable,
  });

  final OrganisationEventCommercialItem item;
  final bool striped;
  final bool busy;
  final bool enabled;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onActivate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: striped ? const Color(0xFFFAFBFE) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE3E8F4))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _BodyCell(
            flex: 3,
            child: Text(
              item.eventName.isEmpty ? item.eventId : item.eventName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ),
          _BodyCell(flex: 2, child: Text(item.eventKind.label, style: _cellStyle)),
          _BodyCell(flex: 2, child: Text(item.commercialPlan.label, style: _cellStyle)),
          _BodyCell(flex: 2, child: Text(item.paymentLabel, style: _cellStyle)),
          _BodyCell(flex: 3, child: _AccessPill(item: item)),
          _BodyCell(
            flex: 2,
            child: Text(
              item.createdAt == null ? '—' : formatShortDate(item.createdAt!),
              style: _cellStyle,
            ),
          ),
          _BodyCell(
            flex: 3,
            child: item.isPerEvent
                ? _ActionRow(
                    busy: busy,
                    enabled: enabled,
                    onRecordPayment: onRecordPayment,
                    onActivate: onActivate,
                    onDisable: onDisable,
                  )
                : const Text('—', style: _cellStyle),
          ),
        ],
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: child,
      ),
    );
  }
}

const TextStyle _cellStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569));

class _EventCommercialCard extends StatelessWidget {
  const _EventCommercialCard({
    required this.item,
    required this.busy,
    required this.enabled,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onDisable,
  });

  final OrganisationEventCommercialItem item;
  final bool busy;
  final bool enabled;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onActivate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.eventName.isEmpty ? item.eventId : item.eventName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _MetaPill(label: item.eventKind.label),
              _MetaPill(label: item.commercialPlan.label),
              _AccessPill(item: item),
              _MetaPill(label: item.paymentLabel),
              if (item.createdAt != null) _MetaPill(label: formatShortDate(item.createdAt!)),
            ],
          ),
          if (item.isPerEvent) ...<Widget>[
            const SizedBox(height: 8),
            _ActionRow(
              busy: busy,
              enabled: enabled,
              onRecordPayment: onRecordPayment,
              onActivate: onActivate,
              onDisable: onDisable,
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.item});

  final OrganisationEventCommercialItem item;

  @override
  Widget build(BuildContext context) {
    final Color fg = _toneColor(item.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _toneFill(item.tone),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        item.accessLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.busy,
    required this.enabled,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onDisable,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onActivate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _ActionButton(
          label: 'Record payment',
          filled: false,
          enabled: enabled && onRecordPayment != null && !busy,
          onTap: onRecordPayment,
        ),
        _ActionButton(
          label: 'Activate',
          filled: true,
          enabled: enabled && onActivate != null && !busy,
          onTap: onActivate,
        ),
        _ActionButton(
          label: 'Disable',
          filled: false,
          enabled: enabled && onDisable != null && !busy,
          onTap: onDisable,
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? (color ?? const Color(0xFF5B21B6)) : const Color(0xFF64748B);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            count == 0 ? label : '$label ($count)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = filled
        ? FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6A38FF),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF94A3B8),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            disabledForegroundColor: const Color(0xFF94A3B8),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          );
    if (filled) {
      return FilledButton(onPressed: enabled ? onTap : null, style: style, child: Text(label));
    }
    return OutlinedButton(onPressed: enabled ? onTap : null, style: style, child: Text(label));
  }
}

EventCommercialAccessTone _toneForDisplay(EventEntitlementDisplayState state) {
  return switch (state) {
    EventEntitlementDisplayState.pending => EventCommercialAccessTone.paymentPending,
    EventEntitlementDisplayState.readyForActivation => EventCommercialAccessTone.readyForActivation,
    EventEntitlementDisplayState.enabled => EventCommercialAccessTone.enabled,
    EventEntitlementDisplayState.disabled => EventCommercialAccessTone.disabled,
  };
}

Color _toneColor(EventCommercialAccessTone tone) {
  return switch (tone) {
    EventCommercialAccessTone.paymentPending => const Color(0xFFC2410C),
    EventCommercialAccessTone.readyForActivation => const Color(0xFF6A38FF),
    EventCommercialAccessTone.enabled => const Color(0xFF047857),
    EventCommercialAccessTone.disabled => const Color(0xFF64748B),
    EventCommercialAccessTone.governed => const Color(0xFF1D4ED8),
  };
}

Color _toneFill(EventCommercialAccessTone tone) {
  return switch (tone) {
    EventCommercialAccessTone.paymentPending => const Color(0xFFFFF7ED),
    EventCommercialAccessTone.readyForActivation => const Color(0xFFF5F3FF),
    EventCommercialAccessTone.enabled => const Color(0xFFECFDF5),
    EventCommercialAccessTone.disabled => const Color(0xFFF1F5F9),
    EventCommercialAccessTone.governed => const Color(0xFFEFF6FF),
  };
}
