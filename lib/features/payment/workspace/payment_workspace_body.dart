import 'package:flutter/material.dart';

import 'package:hackz/core/responsive/responsive_helper.dart';
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
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    return ListView(
      padding: pad,
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
