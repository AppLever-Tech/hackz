import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';

/// Responsive docs image with tap-to-enlarge fullscreen viewer.
class DocumentationImageViewer extends StatelessWidget {
  const DocumentationImageViewer({
    super.key,
    required this.assetPath,
    this.borderRadius = 12,
    this.maxHeight = 360,
    this.semanticLabel,
  });

  final String assetPath;
  final double borderRadius;
  final double maxHeight;
  final String? semanticLabel;

  Future<void> _openFullscreen(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: <Widget>[
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel ?? 'Documentation image',
      button: true,
      child: InkWell(
        onTap: () => _openFullscreen(context),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            color: cs.surface.withValues(alpha: 0.25),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  Image.asset(
                    assetPath,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: cs.surfaceContainerHighest,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(AppIcons.attachmentImage, color: cs.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Image coming soon',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: cs.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.fullscreen_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
