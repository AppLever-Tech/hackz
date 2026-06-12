import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Section key for the evaluation templates editor. Unlike the others, this
/// section is not backed by `OrgSettingDefinition` entries — the dashboard
/// special-cases it to render the templates editor pane.
const String kOrgSettingsEvaluationTemplatesSectionKey = 'evaluationTemplates';

/// Display title for the evaluation templates pseudo-section.
const String kOrgSettingsEvaluationTemplatesSectionTitle = 'Evaluation templates';

/// Pseudo-section for ideathon evaluation template picker.
const String kOrgSettingsIdeathonTemplateSectionKey = 'ideathonTemplate';

const String kOrgSettingsIdeathonTemplateSectionTitle = 'Ideathon evaluation template';

/// Stable section ordering for the org settings dashboard.
const List<String> kOrgSettingsSectionOrder = <String>[
  'team',
  'idea',
  'problem',
  'payment',
  'userAuth',
  'leaderboard',
  'upload',
  'evaluationSettings',
  'ideathon',
  kOrgSettingsIdeathonTemplateSectionKey,
  kOrgSettingsEvaluationTemplatesSectionKey,
];

IconData orgSettingsSectionIcon(String sectionKey) {
  switch (sectionKey) {
    case 'team':
      return AppIcons.teams;
    case 'idea':
      return AppIcons.ideas;
    case 'problem':
      return AppIcons.problems;
    case 'payment':
      return AppIcons.payments;
    case 'userAuth':
      return AppIcons.verification;
    case 'leaderboard':
      return AppIcons.leaderboard;
    case 'upload':
      return AppIcons.attachments;
    case 'evaluationSettings':
      return AppIcons.scoring;
    case 'ideathon':
      return AppIcons.ideathons;
    case kOrgSettingsIdeathonTemplateSectionKey:
      return AppIcons.scoring;
    case kOrgSettingsEvaluationTemplatesSectionKey:
      return AppIcons.scoring;
    default:
      return AppIcons.settings;
  }
}
