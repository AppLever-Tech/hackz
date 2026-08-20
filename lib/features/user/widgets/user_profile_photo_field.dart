import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/network_image_compat.dart';

/// Photo / icon picker with preview — used by user and organisation workflows.
class UserProfilePhotoField extends StatelessWidget {
  const UserProfilePhotoField({
    super.key,
    required this.displayName,
    required this.localFile,
    required this.remoteUrl,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
    this.title = 'Profile photo',
    this.subtitle = 'Used on user cards, workspace pills, and assignments.',
    this.buttonLabel = 'Upload photo',
    this.circular = true,
  });

  final String displayName;
  final PlatformFile? localFile;
  final String? remoteUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool circular;

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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: enabled ? onPick : null,
                    icon: const Icon(AppIcons.attachments, size: 16),
                    label: Text(buttonLabel),
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
      return _clip(
        Image.memory(
          file.bytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final String? url = _remoteUrl;
    if (url != null) {
      return _clip(
        NetworkImageCompat(
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

  Widget _clip(Widget child) {
    if (circular) return ClipOval(child: child);
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: child);
  }

  Widget _initialsAvatar(String initials) {
    final Text label = Text(
      initials,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF4F46E5)),
    );
    if (circular) {
      return CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: const Color(0xFFEEF2FF),
        foregroundColor: const Color(0xFF4F46E5),
        child: label,
      );
    }
    return Container(
      width: _avatarRadius * 2,
      height: _avatarRadius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: label,
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
