import 'package:flutter/material.dart';

import '../../features/user/models/user_model.dart';
import '../../utils/firestore_utils.dart';

class RoleDashboardDataView extends StatefulWidget {
  const RoleDashboardDataView({
    super.key,
    required this.user,
    required this.refreshToken,
    this.footer,
  });

  final UserModel user;
  final int refreshToken;
  final Widget? footer;

  @override
  State<RoleDashboardDataView> createState() => _RoleDashboardDataViewState();
}

class _RoleDashboardDataViewState extends State<RoleDashboardDataView> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = FirestoreUtils.fetchDashboardStats(widget.user);
  }

  @override
  void didUpdateWidget(covariant RoleDashboardDataView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _statsFuture = FirestoreUtils.fetchDashboardStats(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (BuildContext context, AsyncSnapshot<Map<String, int>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load dashboard stats: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data ?? <String, int>{};
        final total = stats['total'] ?? 0;
        final active = stats['active'] ?? 0;
        final pending = stats['pending'] ?? 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _StatChip(title: 'Total Users', value: total),
                _StatChip(title: 'Active Users', value: active),
                _StatChip(title: 'Pending Users', value: pending),
              ],
            ),
            if (widget.footer != null) ...<Widget>[
              const SizedBox(height: 12),
              widget.footer!,
            ],
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
  });

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
