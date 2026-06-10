import 'package:flutter/widgets.dart';

import '../../../../constants/app_icons.dart';
import '../../../../models/enums/account_workspace_phase.dart';

enum ApprovalTimelineNodeState {
  completed,
  current,
  upcoming,
  error,
}

class ApprovalTimelineStepVm {
  const ApprovalTimelineStepVm({
    required this.icon,
    required this.title,
    required this.state,
  });

  final IconData icon;
  final String title;
  final ApprovalTimelineNodeState state;
}

/// Builds the four onboarding steps from workspace phase (config-driven).
abstract final class ApprovalTimelineConfig {
  ApprovalTimelineConfig._();

  static List<ApprovalTimelineStepVm> stepsFor(AccountWorkspacePhase phase) {
    switch (phase) {
      case AccountWorkspacePhase.pendingApproval:
        return const <ApprovalTimelineStepVm>[
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineRegistration,
            title: 'Registration submitted',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineAccessVerified,
            title: 'Access code verified',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineApprovalPending,
            title: 'Administrator approval',
            state: ApprovalTimelineNodeState.current,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineWorkspace,
            title: 'Workspace activation',
            state: ApprovalTimelineNodeState.upcoming,
          ),
        ];
      case AccountWorkspacePhase.approved:
        return const <ApprovalTimelineStepVm>[
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineRegistration,
            title: 'Registration submitted',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineAccessVerified,
            title: 'Access code verified',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineApprovalPending,
            title: 'Administrator approval',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineWorkspace,
            title: 'Workspace activation',
            state: ApprovalTimelineNodeState.completed,
          ),
        ];
      case AccountWorkspacePhase.rejected:
        return const <ApprovalTimelineStepVm>[
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineRegistration,
            title: 'Registration submitted',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineAccessVerified,
            title: 'Access code verified',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.accountRejected,
            title: 'Approval outcome',
            state: ApprovalTimelineNodeState.error,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineWorkspace,
            title: 'Workspace activation',
            state: ApprovalTimelineNodeState.upcoming,
          ),
        ];
      case AccountWorkspacePhase.invalidAccessCode:
        return const <ApprovalTimelineStepVm>[
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineRegistration,
            title: 'Registration submitted',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.accountInvalidCode,
            title: 'Access code verification',
            state: ApprovalTimelineNodeState.error,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineApprovalPending,
            title: 'Administrator approval',
            state: ApprovalTimelineNodeState.upcoming,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineWorkspace,
            title: 'Workspace activation',
            state: ApprovalTimelineNodeState.upcoming,
          ),
        ];
      case AccountWorkspacePhase.suspended:
        return const <ApprovalTimelineStepVm>[
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineRegistration,
            title: 'Registration submitted',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineAccessVerified,
            title: 'Access code verified',
            state: ApprovalTimelineNodeState.completed,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.accountSuspended,
            title: 'Account status',
            state: ApprovalTimelineNodeState.current,
          ),
          ApprovalTimelineStepVm(
            icon: AppIcons.timelineWorkspace,
            title: 'Workspace activation',
            state: ApprovalTimelineNodeState.upcoming,
          ),
        ];
    }
  }
}
