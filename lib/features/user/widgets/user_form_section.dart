import 'package:flutter/material.dart';

import '../../../screens/common/dashboard_components.dart';

/// Premium section card for user create/edit workflows.
class UserFormSection extends StatelessWidget {
  const UserFormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          SizedBox(height: compact ? 6 : 8),
          child,
        ],
      ),
    );
  }
}
