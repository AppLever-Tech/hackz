import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_icons.dart';
import '../services/docs_print.dart';
import 'documentation_image_viewer.dart';

/// Premium documentation hero with metadata actions and optional image.
class DocumentationHero extends StatelessWidget {
  const DocumentationHero({
    super.key,
    required this.title,
    required this.description,
    this.lastUpdated,
    this.readingMinutes = 5,
    this.imageAsset,
    this.onShare,
    this.onPrint,
  });

  final String title;
  final String description;
  final DateTime? lastUpdated;
  final int readingMinutes;
  final String? imageAsset;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String updated = lastUpdated == null
        ? 'Recently updated'
        : 'Updated ${_fmt(lastUpdated!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            cs.primary.withValues(alpha: 0.92),
            cs.secondary.withValues(alpha: 0.88),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: cs.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: cs.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _MetaChip(icon: AppIcons.clock, label: updated, onPrimary: cs.onPrimary),
              _MetaChip(
                icon: Icons.menu_book_outlined,
                label: '$readingMinutes min read',
                onPrimary: cs.onPrimary,
              ),
              _HeroAction(
                icon: Icons.print_outlined,
                label: 'Print',
                onPrimary: cs.onPrimary,
                onTap: onPrint ?? () => docsPrintPage(),
              ),
              _HeroAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onPrimary: cs.onPrimary,
                onTap: onShare ??
                    () async {
                      await Clipboard.setData(ClipboardData(text: title));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Page title copied')),
                        );
                      }
                    },
              ),
            ],
          ),
          if (imageAsset != null && imageAsset!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            DocumentationImageViewer(
              assetPath: imageAsset!,
              borderRadius: 14,
              maxHeight: 280,
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.onPrimary,
  });

  final IconData icon;
  final String label;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color onPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: onPrimary),
      label: Text(label, style: TextStyle(color: onPrimary, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
