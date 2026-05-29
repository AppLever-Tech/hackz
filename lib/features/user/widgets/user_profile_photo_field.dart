import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

/// Profile photo picker with avatar preview for user workflows.
class UserProfilePhotoField extends StatelessWidget {
  const UserProfilePhotoField({
    super.key,
    required this.displayName,
    required this.localFile,
    required this.remoteUrl,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
  });

  final String displayName;
  final PlatformFile? localFile;
  final String? remoteUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(displayName);
    final String? url = (remoteUrl ?? '').trim().isNotEmpty ? remoteUrl!.trim() : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFFEEF2FF),
          foregroundColor: const Color(0xFF4F46E5),
          backgroundImage: _avatarImage(localFile, url),
          child: _avatarImage(localFile, url) == null
              ? Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Profile photo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Used on user cards, workspace pills, and assignments.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: enabled ? onPick : null,
                    icon: const Icon(AppIcons.attachments, size: 16),
                    label: const Text('Upload photo'),
                  ),
                  if (localFile != null || url != null)
                    TextButton(
                      onPressed: enabled ? onClear : null,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static ImageProvider? _avatarImage(PlatformFile? localFile, String? url) {
    if (localFile?.bytes != null && localFile!.bytes!.isNotEmpty) {
      return MemoryImage(localFile.bytes!);
    }
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
