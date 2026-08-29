import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'dashboard_components.dart';

/// Shared empty list card used by problem, idea, user, and team search tables.
class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    super.key,
    required this.title,
    required this.icon,
    this.onClearSearch,
    this.message = 'Try adjusting your search or check back later.',
    this.clearLabel = 'Clear search',
  });

  final String title;
  final IconData icon;
  final String message;
  final String clearLabel;
  final VoidCallback? onClearSearch;

  factory EmptySearchState.problems({Key? key, required VoidCallback onClearSearch}) {
    return EmptySearchState(
      key: key,
      title: 'No problem statements found',
      icon: AppIcons.problems,
      onClearSearch: onClearSearch,
    );
  }

  factory EmptySearchState.ideas({Key? key, required VoidCallback onClearSearch}) {
    return EmptySearchState(
      key: key,
      title: 'No ideas found',
      icon: AppIcons.ideas,
      onClearSearch: onClearSearch,
    );
  }

  factory EmptySearchState.users({Key? key, required VoidCallback onClearSearch}) {
    return EmptySearchState(
      key: key,
      title: 'No users found',
      icon: AppIcons.users,
      onClearSearch: onClearSearch,
    );
  }

  factory EmptySearchState.judges({Key? key, required VoidCallback onClearSearch}) {
    return EmptySearchState(
      key: key,
      title: 'No judges found',
      icon: AppIcons.judges,
      onClearSearch: onClearSearch,
    );
  }

  factory EmptySearchState.payments({
    Key? key,
    String title = 'No payments found',
    String message = 'Try adjusting your search or check back later.',
    String clearLabel = 'Clear search',
    VoidCallback? onClearSearch,
  }) {
    return EmptySearchState(
      key: key,
      title: title,
      icon: AppIcons.payments,
      message: message,
      clearLabel: clearLabel,
      onClearSearch: onClearSearch,
    );
  }

  factory EmptySearchState.teams({
    Key? key,
    required VoidCallback onClearSearch,
    String title = 'No teams found',
    String message = 'Try adjusting your search or check back later.',
    String clearLabel = 'Clear search',
  }) {
    return EmptySearchState(
      key: key,
      title: title,
      icon: AppIcons.teams,
      message: message,
      clearLabel: clearLabel,
      onClearSearch: onClearSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(28),
        decoration: kDashboardCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            if (onClearSearch != null) ...<Widget>[
              const SizedBox(height: 14),
              TextButton(onPressed: onClearSearch, child: Text(clearLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
