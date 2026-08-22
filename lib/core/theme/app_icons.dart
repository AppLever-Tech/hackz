import 'package:flutter/material.dart';

import '../../features/idea/models/enums/idea_status.dart';
import '../../features/organization/models/enums/organization_type.dart';
import '../../features/problems/models/problem_status.dart';
import '../../features/user/models/enums/user_role.dart';

/// Central icon registry for Hackz — prefer these over raw [Icons] in product UI.
class AppIcons {
  AppIcons._();

  // ── Common actions (toolbars, dialogs, inline controls) ──────────────────
  static const IconData add = Icons.add;
  static const IconData search = Icons.search;
  static const IconData refresh = Icons.refresh;
  static const IconData copy = Icons.copy;
  static const IconData copied = Icons.check;
  static const IconData key = Icons.key_outlined;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData more = Icons.more_vert;
  static const IconData edit = Icons.edit_outlined;
  static const IconData remove = Icons.close_rounded;
  static const IconData delete = Icons.delete_outline;
  static const IconData save = Icons.save_outlined;
  static const IconData download = Icons.download_rounded;
  static const IconData preview = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline_rounded;
  static const IconData moveUp = Icons.arrow_upward_rounded;
  static const IconData moveDown = Icons.arrow_downward_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData openInNew = Icons.open_in_new_rounded;
  static const IconData onboardingNext = Icons.arrow_forward_rounded;
  static const IconData clock = Icons.schedule_rounded;
  static const IconData event = Icons.event_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData checklist = Icons.checklist_rounded;
  static const IconData expandLess = Icons.expand_less_rounded;
  static const IconData expandMore = Icons.expand_more_rounded;
  static const IconData assignmentComplete = Icons.assignment_turned_in_outlined;

  // ── Navigation chrome (drawer toggle, collapsible side rail) ──────────────
  static const IconData menu = Icons.menu_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;

  // ── Domain entities (menus, cards, context pills, workspace headers) ─────
  static const IconData dashboard = Icons.grid_view_rounded;
  static const IconData organizations = Icons.apartment_outlined;
  static const IconData users = Icons.groups_outlined;
  static const IconData teams = Icons.groups_3_outlined;
  static const IconData departments = Icons.groups_2_outlined;
  static const IconData problems = Icons.assignment_outlined;
  static const IconData ideas = Icons.lightbulb_outline;
  static const IconData insights = Icons.insights_outlined;
  static const IconData judges = Icons.gavel_outlined;
  static const IconData pendingUsers = Icons.how_to_reg_outlined;
  static const IconData payments = Icons.payments_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData orgSettings = Icons.tune_rounded;
  static const IconData scoring = Icons.score_outlined;
  static const IconData leaderboard = Icons.leaderboard_outlined;
  static const IconData submissions = Icons.upload_file_outlined;
  static const IconData results = Icons.insights_outlined;
  static const IconData verification = Icons.verified_user_outlined;
  static const IconData faculty = Icons.person_outline;
  static const IconData coordinator = Icons.manage_accounts_outlined;
  static const IconData teamMember = Icons.school_outlined;
  static const IconData phone = Icons.phone_outlined;
  static const IconData email = Icons.email_outlined;
  static const IconData adminProfile = Icons.badge_outlined;
  static const IconData orgType = Icons.category_outlined;
  static const IconData address = Icons.location_on_outlined;
  static const IconData website = Icons.language_outlined;
  static const IconData helpSupport = Icons.support_agent_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData domains = Icons.hub_outlined;
  static const IconData docs = Icons.menu_book_outlined;
  static const IconData spreadsheet = Icons.table_chart_outlined;
  static const IconData link = Icons.link_rounded;
  static const IconData feedback = Icons.rate_review_outlined;

  // ── Attachments & media ──────────────────────────────────────────────────
  static const IconData attachments = Icons.attach_file_rounded;
  static const IconData attachmentImage = Icons.image_outlined;
  static const IconData attachmentVideo = Icons.videocam_outlined;
  static const IconData attachmentDocument = Icons.description_outlined;
  static const IconData attachmentPdf = Icons.picture_as_pdf_outlined;
  static const IconData attachmentPpt = Icons.slideshow_outlined;

  // ── Idea lifecycle ([IdeaStatus] — use [forIdeaStatus] / IdeaStatusHelpers) ─
  static const IconData statusDraft = Icons.edit_note_rounded;
  static const IconData statusSubmitted = Icons.send_rounded;
  static const IconData statusEvaluated = Icons.verified_rounded;
  static const IconData statusIdeathonAssigned = Icons.event_available_outlined;
  static const IconData ideathons = Icons.celebration_outlined;

  // ── Workflow / verification (payments, requests, imports, team readiness) ──
  // Not [IdeaStatus] — approval pipelines and completion checks outside ideas.
  static const IconData workflowPendingReview = Icons.pending_rounded;
  static const IconData workflowApproved = Icons.check_circle_rounded;
  static const IconData workflowRejected = Icons.cancel_rounded;
  static const IconData workflowInProgress = Icons.fact_check_outlined;
  static const IconData workflowArchived = Icons.inventory_2_outlined;

  // ── Generic milestone / achievement (docs, showcase content — not IdeaStatus) ─
  static const IconData milestone = Icons.precision_manufacturing_outlined;
  static const IconData achievement = Icons.emoji_events_outlined;

  // ── Team membership (active roster vs disabled team) ───────────────────────
  static const IconData statusActive = Icons.circle;
  static const IconData statusInactive = Icons.circle_outlined;

  // ── Problem statement lifecycle ([ProblemStatus]) ──────────────────────────
  static const IconData problemStatusDraft = Icons.edit_note_rounded;
  static const IconData problemStatusActive = Icons.check_circle_outline_rounded;
  static const IconData problemStatusInactive = Icons.pause_circle_outline_rounded;
  static const IconData problemStatusArchived = Icons.inventory_2_outlined;

  // ── Account onboarding timeline (signup workspace) ─────────────────────────
  static const IconData timelineRegistration = Icons.app_registration_outlined;
  static const IconData timelineAccessVerified = Icons.verified_outlined;
  static const IconData timelineApprovalPending = Icons.hourglass_top_rounded;
  static const IconData timelineWorkspace = Icons.dashboard_customize_outlined;

  // ── Account approval state (user access, not idea lifecycle) ───────────────
  static const IconData accountPending = Icons.hourglass_empty_rounded;
  static const IconData accountApproved = Icons.verified_rounded;
  static const IconData accountRejected = Icons.highlight_off_rounded;
  static const IconData accountInvalidCode = Icons.password_outlined;
  static const IconData accountSuspended = Icons.pause_circle_outline_rounded;

  static IconData forOrganizationType(OrganizationType? type) {
    switch (type) {
      case OrganizationType.college:
        return Icons.school_outlined;
      case OrganizationType.company:
        return Icons.business_outlined;
      case OrganizationType.researchInstitute:
        return Icons.science_outlined;
      case OrganizationType.trainingCenter:
        return Icons.cast_for_education_outlined;
      case null:
        return organizations;
    }
  }

  static IconData forUserRole(UserRole role) {
    switch (role) {
      case UserRole.sysAdmin:
        return settings;
      case UserRole.collegeAdmin:
        return organizations;
      case UserRole.departmentAdmin:
        return departments;
      case UserRole.judge:
        return judges;
      case UserRole.teamMember:
        return teamMember;
      case UserRole.coordinator:
        return coordinator;
    }
  }

  static IconData forUserRoleCode(String roleCode) {
    final normalized = roleCode.trim().toUpperCase();
    switch (normalized) {
      case 'FAC':
        return faculty;
      case 'COO':
        return coordinator;
      case 'TMEM':
        return teamMember;
      case 'SADM':
        return settings;
      case 'CADM':
        return organizations;
      case 'DADM':
        return departments;
      case 'JUD':
        return judges;
      default:
        return users;
    }
  }

  static IconData forProblemStatus(ProblemStatus status) {
    return switch (status) {
      ProblemStatus.draft => problemStatusDraft,
      ProblemStatus.active => problemStatusActive,
      ProblemStatus.inactive => problemStatusInactive,
      ProblemStatus.archived => problemStatusArchived,
    };
  }

  /// Icons for [IdeaStatus] lifecycle stages — the single source for idea status UI.
  static IconData forIdeaStatus(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.draft => statusDraft,
      IdeaStatus.submitted => statusSubmitted,
    };
  }
}
