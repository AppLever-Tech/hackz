import 'package:flutter/material.dart';

import 'capability_pill_list.dart';
import 'landing_section_header.dart';
import 'role_constellation_grid.dart';

/// Section header + child for landing ecosystem blocks.
class LandingEcosystemColumn extends StatelessWidget {
  const LandingEcosystemColumn({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LandingSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Ecosystem participants — role orbit (left column, below hero).
class EcosystemParticipantsSection extends StatelessWidget {
  const EcosystemParticipantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingEcosystemColumn(
      title: 'Ecosystem Participants',
      subtitle: 'Roles connected across the innovation pipeline.',
      child: RoleConstellationGrid(),
    );
  }
}

/// Innovation capabilities — stacked pills (right column, below journey).
class InnovationCapabilitiesSection extends StatelessWidget {
  const InnovationCapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const LandingEcosystemColumn(
      title: 'Innovation Capabilities',
      subtitle: 'Infrastructure layers powering the lifecycle.',
      child: CapabilityPillList(),
    );
  }
}
