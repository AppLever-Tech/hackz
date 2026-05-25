import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

/// Stable section ordering for the org settings dashboard.
const List<String> kOrgSettingsSectionOrder = <String>[
  'team',
  'idea',
  'problem',
  'payment',
  'userAuth',
  'leaderboard',
  'upload',
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
    default:
      return AppIcons.settings;
  }
}
