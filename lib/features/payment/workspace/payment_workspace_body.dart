import 'package:flutter/material.dart';

import 'package:hackz/core/workspace/workspace_theme.dart';
import 'payment_proof_section.dart';
import 'payment_status_section.dart';
import 'payment_summary_section.dart';
import 'payment_timeline_section.dart';
import 'payment_workspace_loader.dart';

class PaymentWorkspaceBody extends StatelessWidget {
  const PaymentWorkspaceBody({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        PaymentSummarySection(vm: vm),
        const SizedBox(height: 14),
        PaymentStatusSection(vm: vm),
        const SizedBox(height: 14),
        PaymentProofSection(vm: vm),
        const SizedBox(height: 14),
        PaymentTimelineSection(vm: vm),
      ],
    );
  }
}
