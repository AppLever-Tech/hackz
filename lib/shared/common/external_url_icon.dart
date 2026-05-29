import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_icons.dart';

/// Compact external-launch icon with tooltip.
class ExternalUrlIcon extends StatelessWidget {
  const ExternalUrlIcon({
    super.key,
    required this.url,
    this.tooltip = 'Open link externally',
    this.icon = AppIcons.openInNew,
    this.iconSize = 15,
    this.color = const Color(0xFF57629A),
    this.onLaunchFailed,
  });

  final String url;
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback? onLaunchFailed;

  Future<void> _open() async {
    final raw = url.trim();
    if (raw.isEmpty) {
      onLaunchFailed?.call();
      return;
    }
    final normalized = raw.startsWith('http://') || raw.startsWith('https://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      onLaunchFailed?.call();
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) onLaunchFailed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
