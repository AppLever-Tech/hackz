import 'package:flutter/material.dart';

import '../models/idea_model.dart';
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
      case IdeaStatus.underReview:
        return AppIcons.statusUnderReview;
      case IdeaStatus.evaluated:
        return AppIcons.statusEvaluated;
      case IdeaStatus.approved:
        return AppIcons.statusApproved;
      case IdeaStatus.rejected:
        return AppIcons.statusRejected;
      case IdeaStatus.pendingSubmission:
      case IdeaStatus.submitted:
        return AppIcons.statusSubmitted;
    }
  }
}
