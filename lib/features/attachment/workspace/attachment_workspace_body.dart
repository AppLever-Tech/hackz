import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/responsive/responsive_helper.dart';
import 'package:hackz/widgets/responsive/responsive_filter_bar.dart';
import 'attachment_metadata_section.dart';
import 'attachment_preview_section.dart';
import 'attachment_related_section.dart';
import 'attachment_workspace_loader.dart';

class AttachmentWorkspaceBody extends StatelessWidget {
  const AttachmentWorkspaceBody({super.key, required this.vm});

  final AttachmentWorkspaceViewModel vm;

  Future<void> _openExternal(BuildContext context) async {
    final uri = Uri.tryParse(vm.resolvedUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    return ListView(
      padding: pad,
      children: <Widget>[
        AttachmentPreviewSection(vm: vm),
        const SizedBox(height: 14),
        AttachmentMetadataSection(vm: vm),
        const SizedBox(height: 14),
        AttachmentRelatedSection(vm: vm),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ResponsiveWrapToolbar(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: vm.resolvedUrl.trim().isEmpty ? null : () => _openExternal(context),
                icon: const Icon(AppIcons.openInNew, size: 16),
                label: const Text('Open externally'),
              ),
              OutlinedButton.icon(
                onPressed: vm.resolvedUrl.trim().isEmpty ? null : () => _openExternal(context),
                icon: const Icon(AppIcons.download, size: 16),
                label: const Text('Download'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
