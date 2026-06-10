import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';

/// Static innovation pipeline stages (no network / DB).
class LandingPipelineStage {
  const LandingPipelineStage({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;
}

abstract final class LandingPipelineData {
  static const List<LandingPipelineStage> stages = <LandingPipelineStage>[
    LandingPipelineStage(
      icon: AppIcons.ideas,
      label: 'Idea',
      accent: Color(0xFF6A38FF),
    ),
    LandingPipelineStage(
      icon: Icons.architecture_outlined,
      label: 'Prototype',
      accent: Color(0xFFEA580C),
    ),
    LandingPipelineStage(
      icon: Icons.verified_outlined,
      label: 'Patent',
      accent: Color(0xFF0EA5E9),
    ),
    LandingPipelineStage(
      icon: Icons.inventory_2_outlined,
      label: 'Product',
      accent: Color(0xFF16A34A),
    ),
    LandingPipelineStage(
      icon: Icons.menu_book_outlined,
      label: 'Publication',
      accent: Color(0xFF7C3AED),
    ),
    LandingPipelineStage(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Funding',
      accent: Color(0xFFD97706),
    ),
  ];
}

/// Innovation ecosystem role (positioned as participants, not admin labels).
class LandingRoleTile {
  const LandingRoleTile({
    required this.icon,
    required this.title,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final Color accent;
}

abstract final class LandingRoleData {
  static const List<LandingRoleTile> roles = <LandingRoleTile>[
    LandingRoleTile(
      icon: AppIcons.student,
      title: 'Student',
      accent: Color(0xFF6A38FF),
    ),
    LandingRoleTile(
      icon: AppIcons.faculty,
      title: 'Faculty',
      accent: Color(0xFF0EA5E9),
    ),
    LandingRoleTile(
      icon: AppIcons.judges,
      title: 'Judge',
      accent: Color(0xFFEA580C),
    ),
    LandingRoleTile(
      icon: AppIcons.coordinator,
      title: 'Coordinator',
      accent: Color(0xFF16A34A),
    ),
    LandingRoleTile(
      icon: AppIcons.departments,
      title: 'Department Admin',
      accent: Color(0xFF7C3AED),
    ),
    LandingRoleTile(
      icon: AppIcons.settings,
      title: 'SysAdmin',
      accent: Color(0xFF64748B),
    ),
  ];
}

/// Structured ecosystem capabilities.
class LandingCapability {
  const LandingCapability({
    required this.icon,
    required this.title,
    required this.caption,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color accent;
}

abstract final class LandingCapabilityData {
  static const List<LandingCapability> items = <LandingCapability>[
    LandingCapability(
      icon: AppIcons.teams,
      title: 'Team Collaboration',
      caption: 'Build and manage innovation teams',
      accent: Color(0xFF6A38FF),
    ),
    LandingCapability(
      icon: Icons.precision_manufacturing_outlined,
      title: 'Product Development',
      caption: 'Move from prototype to product',
      accent: Color(0xFFEA580C),
    ),
    LandingCapability(
      icon: Icons.science_outlined,
      title: 'Research & Publication',
      caption: 'Document and publish outcomes',
      accent: Color(0xFF0EA5E9),
    ),
    LandingCapability(
      icon: AppIcons.scoring,
      title: 'Evaluation & Feedback',
      caption: 'Structured rubrics and reviews',
      accent: Color(0xFF16A34A),
    ),
    LandingCapability(
      icon: AppIcons.insights,
      title: 'Innovation Tracking',
      caption: 'Track pipeline progress end-to-end',
      accent: Color(0xFF7C3AED),
    ),
    LandingCapability(
      icon: AppIcons.payments,
      title: 'Funding Readiness',
      caption: 'Prepare for grants and investment',
      accent: Color(0xFFD97706),
    ),
  ];
}
