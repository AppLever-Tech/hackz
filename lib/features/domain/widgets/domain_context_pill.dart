import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../models/domain_model.dart';

/// Compact domain context pill — reuses [ContextPill].
class DomainContextPill extends StatelessWidget {
  const DomainContextPill({
    super.key,
    required this.domain,
    this.onTap,
  });

  final DomainModel domain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ContextPill(
      label: domain.name.trim().isEmpty ? domain.code : domain.name.trim(),
      icon: AppIcons.domains,
      semantic: ContextPillSemantic.problem,
      onTap: onTap ?? () {},
      enabled: onTap != null,
      tooltip: domain.displayLabel,
    );
  }
}
