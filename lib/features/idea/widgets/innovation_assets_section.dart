import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../shared/feedback/feedback.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

/// Compact actionable innovation assets (git, demo video, presentation).
class InnovationAssetsSection extends StatelessWidget {
  const InnovationAssetsSection({
    super.key,
    required this.idea,
    this.attachments = const <AttachmentModel>[],
    this.onOpenAttachment,
    this.emptyMessage = 'No innovation assets added.',
  });

  final IdeaModel idea;
  final List<AttachmentModel> attachments;
  final void Function(AttachmentModel attachment)? onOpenAttachment;
  final String emptyMessage;

  static Future<void> _launchUrl(BuildContext context, String raw) async {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final String normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://') ? trimmed : 'https://$trimmed';
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null) return;
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      FeedbackService.showWarning(
        context,
        title: 'Could not open link',
        message: 'Check the URL and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];

    if (idea.hasGitRepository) {
      items.add(
        EntityCardPills.workspace(
          'Git Repository',
          ContextPillSemantic.generic,
          () => _launchUrl(context, idea.gitRepositoryUrl),
          icon: Icons.code_rounded,
        ),
      );
    }
    if (idea.hasYoutubeDemo) {
      items.add(
        EntityCardPills.workspace(
          'Demo Video',
          ContextPillSemantic.generic,
          () => _launchUrl(context, idea.youtubeDemoUrl),
          icon: Icons.play_circle_outline_rounded,
        ),
      );
    }

    final List<AttachmentModel> presentationAttachments = attachments
        .where((AttachmentModel a) => a.entityType == AttachmentEntityType.idea && a.entityId == idea.ideaId)
        .toList(growable: false);

    if (presentationAttachments.isNotEmpty) {
      for (final AttachmentModel attachment in presentationAttachments) {
        final String label = attachment.fileName.trim().isEmpty ? 'Presentation' : attachment.fileName.trim();
        items.add(
          EntityCardPills.workspace(
            label,
            ContextPillSemantic.generic,
            () {
              if (onOpenAttachment != null) {
                onOpenAttachment!(attachment);
              } else {
                WorkspaceNavigator.openAttachment(context, attachment.attachmentId);
              }
            },
            icon: AppIcons.attachments,
          ),
        );
      }
    } else if (idea.hasPresentationFiles) {
      items.add(
        EntityCardPills.meta(
          '${idea.files.length} presentation file${idea.files.length == 1 ? '' : 's'}',
          icon: AppIcons.attachments,
        ),
      );
    }

    if (items.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}
