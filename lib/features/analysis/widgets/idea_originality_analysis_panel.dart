import 'package:flutter/material.dart';

import '../../idea/models/enums/idea_status.dart';
import '../../user/models/user_model.dart';
import 'idea_originality_analysis_view.dart';

/// Admin Idea Details panel — run/refresh/retry via [IdeaOriginalityAnalysisView].
class IdeaOriginalityAnalysisPanel extends StatelessWidget {
  const IdeaOriginalityAnalysisPanel({
    super.key,
    required this.ideaId,
    required this.ideaStatus,
    required this.organisationId,
    required this.user,
  });

  final String ideaId;
  final IdeaStatus ideaStatus;
  final String organisationId;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return IdeaOriginalityAnalysisView(
      ideaId: ideaId,
      organisationId: organisationId,
      ideaStatus: ideaStatus,
      user: user,
      presentation: IdeaOriginalityAnalysisPresentation.admin,
    );
  }
}
