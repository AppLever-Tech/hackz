import 'package:flutter/material.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/models/event_payment_entry.dart';
import 'package:hackz/features/events/services/event_payments_service.dart';
import 'package:hackz/features/events/widgets/event_payments_section.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonPaymentsTab extends StatefulWidget {
  const IdeathonPaymentsTab({
    super.key,
    required this.ideathonId,
    this.actor,
    this.loadFuture,
    this.onChanged,
  });

  final String ideathonId;
  final UserModel? actor;

  /// When set (e.g. details pane prefetch), reuse the in-flight load.
  final Future<EventPaymentsViewModel>? loadFuture;
  final VoidCallback? onChanged;

  @override
  State<IdeathonPaymentsTab> createState() => _IdeathonPaymentsTabState();
}

class _IdeathonPaymentsTabState extends State<IdeathonPaymentsTab> {
  late Future<EventPaymentsViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadFuture ?? _load();
  }

  @override
  void didUpdateWidget(covariant IdeathonPaymentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadFuture != null && widget.loadFuture != oldWidget.loadFuture) {
      setState(() => _future = widget.loadFuture!);
    } else if (widget.ideathonId != oldWidget.ideathonId) {
      setState(() => _future = _load());
    }
  }

  Future<EventPaymentsViewModel> _load() {
    return EventPaymentsService.load(
      kind: EventKind.ideathon,
      eventId: widget.ideathonId,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _confirm(EventPaymentEntry entry) async {
    try {
      await EventPaymentsService.confirm(
        kind: EventKind.ideathon,
        eventId: widget.ideathonId,
        entry: entry,
        actor: widget.actor!,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Could not confirm payment',
        message: '$e',
      );
      return;
    }
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: 'Payment confirmed',
      message: 'Event payment confirmed.',
    );
    _reload();
    widget.onChanged?.call();
  }

  Future<void> _markException(EventPaymentEntry entry, String? remarks) async {
    try {
      await EventPaymentsService.markException(
        kind: EventKind.ideathon,
        eventId: widget.ideathonId,
        entry: entry,
        actor: widget.actor!,
        remarks: remarks,
      );
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Could not mark exception',
        message: '$e',
      );
      return;
    }
    if (!mounted) return;
    FeedbackService.showInfo(
      context,
      title: 'Payment exception',
      message: 'Event payment marked as exception.',
    );
    _reload();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = EventPaymentsService.actorCanManage(widget.actor);
    return FutureBuilder<EventPaymentsViewModel>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<EventPaymentsViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 32));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              snapshot.hasError ? 'Unable to load payments: ${snapshot.error}' : 'Payments not found',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        final EventPaymentsViewModel vm = snapshot.data!;
        return EventPaymentsSection(
          kind: EventKind.ideathon,
          eventId: widget.ideathonId,
          entries: vm.entries,
          metrics: vm.metrics,
          embedded: true,
          onConfirm: canManage ? _confirm : null,
          onMarkException: canManage ? _markException : null,
        );
      },
    );
  }
}
