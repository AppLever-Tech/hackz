import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/ideathons/services/ideathon_payment_service.dart';
import 'package:hackz/features/ideathons/workspace/ideathon_payment_workspace_body.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonPaymentsTab extends StatefulWidget {
  const IdeathonPaymentsTab({
    super.key,
    required this.ideathonId,
    this.actor,
    this.loadFuture,
  });

  final String ideathonId;
  final UserModel? actor;

  /// When set (e.g. details pane prefetch), reuse the in-flight load.
  final Future<IdeathonPaymentWorkspaceViewModel>? loadFuture;

  @override
  State<IdeathonPaymentsTab> createState() => _IdeathonPaymentsTabState();
}

class _IdeathonPaymentsTabState extends State<IdeathonPaymentsTab> {
  late Future<IdeathonPaymentWorkspaceViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadFuture ?? IdeathonPaymentService.load(widget.ideathonId);
  }

  @override
  void didUpdateWidget(covariant IdeathonPaymentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadFuture != null && widget.loadFuture != oldWidget.loadFuture) {
      setState(() => _future = widget.loadFuture!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdeathonPaymentWorkspaceViewModel>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<IdeathonPaymentWorkspaceViewModel> snapshot) {
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
        return IdeathonPaymentWorkspaceBody(
          vm: snapshot.data!,
          actor: widget.actor,
          embedded: true,
        );
      },
    );
  }
}
