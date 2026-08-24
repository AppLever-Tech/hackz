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
  });

  final String ideathonId;
  final UserModel? actor;

  @override
  State<IdeathonPaymentsTab> createState() => _IdeathonPaymentsTabState();
}

class _IdeathonPaymentsTabState extends State<IdeathonPaymentsTab> {
  late Future<IdeathonPaymentWorkspaceViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = IdeathonPaymentService.load(widget.ideathonId);
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
