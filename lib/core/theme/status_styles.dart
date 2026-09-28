import 'package:flutter/material.dart';

import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/idea/services/idea_status_helpers.dart';

class StatusStyles {
  StatusStyles._();

  static const Color submitted = Color(0xFF9E9E9E);
  static const Color submittedChart = Color(0xFF5C6BC0);
  static const Color underReview = Color(0xFF1E88E5);
  static const Color evaluated = Color(0xFF7B1FA2);
  static const Color approved = Color(0xFF2E7D32);
  static const Color rejected = Color(0xFFC62828);

  static Color colorForIdeaStatus(IdeaStatus status) => IdeaStatusHelpers.color(status);

  static IconData iconForIdeaStatus(IdeaStatus status) => IdeaStatusHelpers.icon(status);

  static String labelForIdeaStatus(IdeaStatus status) => IdeaStatusHelpers.label(status);

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
