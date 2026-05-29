import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/enums/account_workspace_phase.dart';
import '../features/user/models/enums/user_status.dart';

/// Central visuals for account onboarding workspace and user-status chips (e.g. dept admin).
abstract final class AccountWorkspaceVisuals {
  AccountWorkspaceVisuals._();

  /// Accent for list rows / pills by backend [UserStatus].
  static Color userStatusAccent(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return const Color(0xFF15803D);
      case UserStatus.pendingApproval:
        return const Color(0xFFD97706);
      case UserStatus.rejected:
        return const Color(0xFFB91C1C);
      case UserStatus.suspended:
        return const Color(0xFF475569);
    }
  }

  /// Display label for tables (title case).
  static String userStatusDisplayLabel(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.pendingApproval:
        return 'Pending Approval';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }

  static Color chipBackgroundForUserStatus(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return const Color(0xFFE8F8EE);
      case UserStatus.pendingApproval:
        return const Color(0xFFFFF4E6);
      case UserStatus.rejected:
        return const Color(0xFFFEF2F2);
      case UserStatus.suspended:
        return const Color(0xFFF1F5F9);
    }
  }

  static IconData heroIcon(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return AppIcons.accountPending;
      case AccountWorkspacePhase.approved:
        return AppIcons.accountApproved;
      case AccountWorkspacePhase.rejected:
        return AppIcons.accountRejected;
      case AccountWorkspacePhase.invalidAccessCode:
        return AppIcons.accountInvalidCode;
      case AccountWorkspacePhase.suspended:
        return AppIcons.accountSuspended;
    }
  }

  static String heroTitle(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return 'Registration submitted successfully';
      case AccountWorkspacePhase.approved:
        return 'Your workspace is ready';
      case AccountWorkspacePhase.rejected:
        return 'Registration could not be approved';
      case AccountWorkspacePhase.invalidAccessCode:
        return 'Access verification needs attention';
      case AccountWorkspacePhase.suspended:
        return 'Your account is temporarily paused';
    }
  }

  static String heroSubtitle(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return 'Awaiting department administrator approval';
      case AccountWorkspacePhase.approved:
        return 'You can continue to the full Hackz experience';
      case AccountWorkspacePhase.rejected:
        return 'Please review the message below or reach out for support';
      case AccountWorkspacePhase.invalidAccessCode:
        return 'Confirm your organization access code and sign in again';
      case AccountWorkspacePhase.suspended:
        return 'Workspace access is on hold — contact your administrator';
    }
  }

  static String pillLabel(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return 'Approval pending';
      case AccountWorkspacePhase.approved:
        return 'Active';
      case AccountWorkspacePhase.rejected:
        return 'Not approved';
      case AccountWorkspacePhase.invalidAccessCode:
        return 'Access issue';
      case AccountWorkspacePhase.suspended:
        return 'Suspended';
    }
  }

  static Color pillForeground(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const Color(0xFFB45309);
      case AccountWorkspacePhase.approved:
        return const Color(0xFF15803D);
      case AccountWorkspacePhase.rejected:
        return const Color(0xFFB91C1C);
      case AccountWorkspacePhase.invalidAccessCode:
        return const Color(0xFF7C3AED);
      case AccountWorkspacePhase.suspended:
        return const Color(0xFF475569);
    }
  }

  static Color pillBackground(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const Color(0xFFFFF7ED);
      case AccountWorkspacePhase.approved:
        return const Color(0xFFE8F8EE);
      case AccountWorkspacePhase.rejected:
        return const Color(0xFFFEF2F2);
      case AccountWorkspacePhase.invalidAccessCode:
        return const Color(0xFFF3E8FF);
      case AccountWorkspacePhase.suspended:
        return const Color(0xFFF8FAFC);
    }
  }

  static LinearGradient heroGradient(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const LinearGradient(colors: <Color>[Color(0xFFFFF7ED), Color(0xFFEFF6FF)]);
      case AccountWorkspacePhase.approved:
        return const LinearGradient(colors: <Color>[Color(0xFFE8F8EE), Color(0xFFE0F2FE)]);
      case AccountWorkspacePhase.rejected:
        return const LinearGradient(colors: <Color>[Color(0xFFFEF2F2), Color(0xFFF5F3FF)]);
      case AccountWorkspacePhase.invalidAccessCode:
        return const LinearGradient(colors: <Color>[Color(0xFFF3E8FF), Color(0xFFEFF6FF)]);
      case AccountWorkspacePhase.suspended:
        return const LinearGradient(colors: <Color>[Color(0xFFF1F5F9), Color(0xFFE2E8F0)]);
    }
  }

  static Color heroBorder(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const Color(0xFFFDBA74);
      case AccountWorkspacePhase.approved:
        return const Color(0xFF86EFAC);
      case AccountWorkspacePhase.rejected:
        return const Color(0xFFFECACA);
      case AccountWorkspacePhase.invalidAccessCode:
        return const Color(0xFFD8B4FE);
      case AccountWorkspacePhase.suspended:
        return const Color(0xFFCBD5E1);
    }
  }

  static List<String> whatHappensNextBullets(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const <String>[
          'A department administrator reviews your registration.',
          'After approval, you can open the full workspace with your role.',
          'You may receive email or SMS updates if your organization enables them.',
        ];
      case AccountWorkspacePhase.approved:
        return const <String>[
          'Your profile is active — continue to the dashboard.',
        ];
      case AccountWorkspacePhase.rejected:
        return const <String>[
          'Your organization may provide a different access path or updated details.',
          'Contact your department admin or coordinator for the next step.',
        ];
      case AccountWorkspacePhase.invalidAccessCode:
        return const <String>[
          'Return to sign-in and confirm your organization access code.',
          'If the problem continues, ask your department admin for a new code.',
        ];
      case AccountWorkspacePhase.suspended:
        return const <String>[
          'An administrator can restore access when appropriate.',
          'Use the support section to reach your department or coordinator.',
        ];
    }
  }
}
