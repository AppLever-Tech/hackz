import 'package:flutter/material.dart';

import 'package:hackz/features/idea/models/idea_model.dart';
import 'app_icons.dart';

class StatusStyles {
  StatusStyles._();

  static const Color submitted = Color(0xFF9E9E9E); // grey
  static const Color submittedChart = Color(0xFF5C6BC0); // indigo (chart segment)
  static const Color underReview = Color(0xFF1E88E5); // blue
  static const Color evaluated = Color(0xFF7B1FA2); // purple
  static const Color approved = Color(0xFF2E7D32); // green
  static const Color rejected = Color(0xFFC62828); // red

  static Color colorForIdeaStatus(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.underReview:
        return underReview;
      case IdeaStatus.evaluated:
        return evaluated;
      case IdeaStatus.approved:
        return approved;
      case IdeaStatus.rejected:
        return rejected;
      case IdeaStatus.pendingSubmission:
      case IdeaStatus.submitted:
        return submitted;
    }
  }

  static IconData iconForIdeaStatus(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return AppIcons.statusPendingSubmission;
      case IdeaStatus.submitted:
        return AppIcons.statusSubmitted;
      case IdeaStatus.underReview:
        return AppIcons.statusUnderReview;
      case IdeaStatus.evaluated:
        return AppIcons.statusEvaluated;
      case IdeaStatus.approved:
        return AppIcons.statusApproved;
      case IdeaStatus.rejected:
        return AppIcons.statusRejected;
    }
  }

  static String labelForIdeaStatus(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return 'Pending Submission';
      case IdeaStatus.submitted:
        return 'Submitted';
      case IdeaStatus.underReview:
        return 'Under Review';
      case IdeaStatus.evaluated:
        return 'Evaluated';
      case IdeaStatus.approved:
        return 'Approved';
      case IdeaStatus.rejected:
        return 'Rejected';
    }
  }

  /// Colored filled status icon with tinted background (tooltip optional).
  static Widget ideaStatusIcon(
    IdeaStatus status, {
    double size = 18,
    String? tooltip,
  }) {
    final color = colorForIdeaStatus(status);
    final badge = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconForIdeaStatus(status),
        size: size,
        color: color,
      ),
    );
    final message = tooltip ?? labelForIdeaStatus(status);
    return Tooltip(message: message, child: badge);
  }
}
