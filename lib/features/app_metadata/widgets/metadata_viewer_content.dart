import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/app_metadata_document.dart';
import '../constants/app_metadata_keys.dart';

/// Renders any [AppMetadataDocument] payload.
class MetadataViewerContent extends StatelessWidget {
  const MetadataViewerContent({super.key, required this.document});

  final AppMetadataDocument document;

  @override
  Widget build(BuildContext context) {
    return switch (document.type) {
      AppMetadataType.text => _TextBody(body: document.body),
      AppMetadataType.projectTeam => _TeamList(members: document.members),
      AppMetadataType.appInfo => _AppInfoBody(info: document.appInfo),
    };
  }
}

class MetadataViewerShell extends StatelessWidget {
  const MetadataViewerShell({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF6A38FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(AppIcons.info, color: Color(0xFF6A38FF), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final String text = body.trim().isEmpty ? 'No content available.' : body.trim();
    return SelectableText(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList({required this.members});

  final List<ProjectTeamMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'No team members listed.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      );
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < members.length; i++) ...<Widget>[
          if (i > 0) const Divider(height: 1, color: Color(0xFFE9ECF6)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    members[i].name.trim().isEmpty ? '—' : members[i].name.trim(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    members[i].designation.trim().isEmpty ? '—' : members[i].designation.trim(),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AppInfoBody extends StatelessWidget {
  const _AppInfoBody({required this.info});

  final AppInfoPayload info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoRow(label: 'Version', value: info.version.isEmpty ? '—' : info.version),
        _InfoRow(label: 'Build', value: info.buildNumber.isEmpty ? '—' : info.buildNumber),
        if (info.releaseNotes.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text('Release notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          SelectableText(
            info.releaseNotes.trim(),
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
          ),
        ],
        if (info.additionalInfo.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          SelectableText(
            info.additionalInfo.trim(),
            style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
