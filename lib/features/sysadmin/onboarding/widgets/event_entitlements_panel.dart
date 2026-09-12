import 'package:flutter/material.dart';

import '../../../../core/firebase/hackz_provisioning_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/loading/hkz_async_loader.dart';
import '../../../../features/events/models/event_kind.dart';
import '../../../../features/organization/models/enums/organization_commercial_plan.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../models/event_entitlement.dart';
import '../services/organisation_onboarding_service.dart';

/// SysAdmin per-event licensing on the organisation card. Control Plane metadata only.
class EventEntitlementsPanel extends StatefulWidget {
  const EventEntitlementsPanel({
    super.key,
    required this.organization,
  });

  final OrganizationModel organization;

  @override
  State<EventEntitlementsPanel> createState() => _EventEntitlementsPanelState();
}

class _EventEntitlementsPanelState extends State<EventEntitlementsPanel> {
  EventEntitlementDisplayState? _filter;
  List<EventEntitlement> _items = const <EventEntitlement>[];
  bool _loading = true;
  String? _error;
  String? _busyEventId;

  bool get _perEvent => widget.organization.commercialPlan == OrganizationCommercialPlan.perEvent;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(EventEntitlementsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organization.id != widget.organization.id ||
        oldWidget.organization.commercialPlan != widget.organization.commercialPlan) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (!_perEvent) {
      setState(() {
        _items = const <EventEntitlement>[];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<EventEntitlement> items =
          await OrganisationOnboardingService.listEventEntitlements(widget.organization.id);
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

  List<EventEntitlement> get _visible {
    final EventEntitlementDisplayState? filter = _filter;
    if (filter == null) return _items;
    return _items.where((EventEntitlement item) => item.displayState == filter).toList();
  }

  int _count(EventEntitlementDisplayState state) =>
      _items.where((EventEntitlement item) => item.displayState == state).length;

  Future<void> _recordPayment(EventEntitlement item) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Record event payment?',
      message:
          'Mark the agreed commercial payment for "${item.eventName}" as received. This does not copy tenant payment transactions and does not change event lifecycle.',
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
            organisationId: item.orgId,
            eventId: item.eventId,
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

  Future<void> _activate(EventEntitlement item) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Activate event access?',
      message:
          '"${item.eventName}" will be commercially enabled on the tenant event. Event lifecycle is unchanged.',
      confirmLabel: 'Activate',
    );
    if (!ok) return;
    await _setStatus(item, EventEntitlementStatus.enabled, title: 'Activate event', success: 'Event access enabled.');
  }

  Future<void> _disable(EventEntitlement item) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Disable event access?',
      message:
          '"${item.eventName}" will be commercially disabled. Event lifecycle and configuration are unchanged.',
      confirmLabel: 'Disable',
      dangerConfirm: true,
    );
    if (!ok) return;
    await _setStatus(item, EventEntitlementStatus.disabled, title: 'Disable event', success: 'Event access disabled.');
  }

  Future<void> _setStatus(
    EventEntitlement item,
    EventEntitlementStatus status, {
    required String title,
    required String success,
  }) async {
    if (_busyEventId != null) return;
    setState(() => _busyEventId = item.eventId);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: title,
        message: item.eventName,
        successMessage: success,
        task: () async {
          await HackzProvisioningClient.setEventEntitlementStatus(
            organisationId: item.orgId,
            eventId: item.eventId,
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

  @override
  Widget build(BuildContext context) {
    if (!_perEvent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Event entitlement',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Per-event commercial access. Record the agreed event payment, then activate. Separate from event lifecycle.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
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
            const Text(
              'No event activation requests yet.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ] else if (_items.isNotEmpty) ...<Widget>[
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
                    color: _displayColor(state),
                    onTap: () => setState(() => _filter = state),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_visible.isEmpty)
              const Text(
                'No events in this filter.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              )
            else ...<Widget>[
              for (final EventEntitlement item in _visible) ...<Widget>[
                _EventEntitlementRow(
                  item: item,
                  busy: _busyEventId == item.eventId,
                  enabled: _busyEventId == null,
                  onRecordPayment: item.canRecordPayment ? () => _recordPayment(item) : null,
                  onActivate: item.canActivate ? () => _activate(item) : null,
                  onDisable: item.canDisable ? () => _disable(item) : null,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _EventEntitlementRow extends StatelessWidget {
  const _EventEntitlementRow({
    required this.item,
    required this.busy,
    required this.enabled,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onDisable,
  });

  final EventEntitlement item;
  final bool busy;
  final bool enabled;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onActivate;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    final EventKind kind = EventKind.fromWire(item.eventType);
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
              _MetaPill(label: kind.label),
              _MetaPill(label: item.commercialPlan.label),
              _DisplayStatePill(state: item.displayState),
              _MetaPill(label: item.paymentSummary),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
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
          ),
        ],
      ),
    );
  }
}

class _DisplayStatePill extends StatelessWidget {
  const _DisplayStatePill({required this.state});

  final EventEntitlementDisplayState state;

  @override
  Widget build(BuildContext context) {
    final Color fg = _displayColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _displayFill(state),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        state.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            disabledForegroundColor: const Color(0xFF94A3B8),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          );
    if (filled) {
      return FilledButton(onPressed: enabled ? onTap : null, style: style, child: Text(label));
    }
    return OutlinedButton(onPressed: enabled ? onTap : null, style: style, child: Text(label));
  }
}

Color _displayColor(EventEntitlementDisplayState state) {
  return switch (state) {
    EventEntitlementDisplayState.pending => const Color(0xFFC2410C),
    EventEntitlementDisplayState.readyForActivation => const Color(0xFF6A38FF),
    EventEntitlementDisplayState.enabled => const Color(0xFF047857),
    EventEntitlementDisplayState.disabled => const Color(0xFF64748B),
  };
}

Color _displayFill(EventEntitlementDisplayState state) {
  return switch (state) {
    EventEntitlementDisplayState.pending => const Color(0xFFFFF7ED),
    EventEntitlementDisplayState.readyForActivation => const Color(0xFFF5F3FF),
    EventEntitlementDisplayState.enabled => const Color(0xFFECFDF5),
    EventEntitlementDisplayState.disabled => const Color(0xFFF1F5F9),
  };
}
