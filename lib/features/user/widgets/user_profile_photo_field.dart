import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../shared/inputs/network_image_compat.dart';

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

  static const double _avatarRadius = 36;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _buildPreview(),
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
                  if (localFile != null || _remoteUrl != null)
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

  String? get _remoteUrl {
    final String trimmed = (remoteUrl ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildPreview() {
    final String initials = _initials(displayName);
    final double size = _avatarRadius * 2;

    final PlatformFile? file = localFile;
    if (file?.bytes != null && file!.bytes!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          file.bytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final String? url = _remoteUrl;
    if (url != null) {
      return ClipOval(
        child: NetworkImageCompat(
          url: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          logTag: 'UserProfilePhotoField',
          errorBuilder: (_) => _initialsAvatar(initials),
        ),
      );
    }

    return _initialsAvatar(initials);
  }

  Widget _initialsAvatar(String initials) {
    return CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
    );
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
