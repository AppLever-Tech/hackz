import 'package:flutter/material.dart';

import '../../widgets/common/context_pill.dart';
import '../../widgets/common/context_pill_theme.dart';

/// Related-entity preview for workspace panels (category + context pill + detail).
class EntityReferenceTile extends StatelessWidget {
  const EntityReferenceTile({
    super.key,
    required this.category,
    required this.headline,
    required this.detail,
    this.onOpenWorkspace,
    this.workspaceEntityLabel,
    this.semantic,
  });

  final String category;
  final String headline;
  final String detail;
  final VoidCallback? onOpenWorkspace;
  final String? workspaceEntityLabel;
  final ContextPillSemantic? semantic;

  @override
  Widget build(BuildContext context) {
    final ContextPillSemantic resolved =
        semantic ?? ContextPillTheme.semanticFromEntityLabel(workspaceEntityLabel ?? category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            category,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          if (onOpenWorkspace != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ContextPill(
                label: headline,
                onTap: onOpenWorkspace!,
                semantic: resolved,
              ),
            )
          else
            Text(
              headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
            ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
