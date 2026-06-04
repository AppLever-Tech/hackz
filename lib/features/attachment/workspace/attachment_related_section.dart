import 'package:flutter/material.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';
import 'package:hackz/workspace/shared/entity_reference_tile.dart';
import 'attachment_workspace.dart';
import 'attachment_workspace_loader.dart';

class AttachmentRelatedSection extends StatelessWidget {
  const AttachmentRelatedSection({super.key, required this.vm});

  final AttachmentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final AttachmentRelatedEntity? related = vm.related;
    if (related == null || !related.canOpenWorkspace) {
      return const SizedBox.shrink();
    }

    final ContextPillSemantic semantic = switch (related.entityType) {
      AttachmentEntityType.idea => ContextPillSemantic.idea,
      AttachmentEntityType.problem => ContextPillSemantic.problem,
      AttachmentEntityType.payment => ContextPillSemantic.payment,
      AttachmentEntityType.organization => ContextPillSemantic.generic,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Related context',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        EntityReferenceTile(
          category: _categoryLabel(related.entityType),
          headline: related.headline,
          detail: related.detail,
          semantic: semantic,
          onOpenWorkspace: () => AttachmentWorkspace.openRelated(context, related),
        ),
      ],
    );
  }

  static String _categoryLabel(AttachmentEntityType type) {
    return switch (type) {
      AttachmentEntityType.idea => 'Idea',
      AttachmentEntityType.problem => 'Problem',
      AttachmentEntityType.payment => 'Payment',
      AttachmentEntityType.organization => 'Organization',
    };
  }
}
