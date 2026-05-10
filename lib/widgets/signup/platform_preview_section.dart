import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';

/// Read-only preview tiles — builds anticipation; no navigation or actions.
class PlatformPreviewSection extends StatelessWidget {
  const PlatformPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Your workspace preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'A quick look at what opens after activation',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final tiles = <_PreviewSpec>[
              const _PreviewSpec(
                icon: AppIcons.leaderboard,
                title: 'Innovation leaderboard',
                caption: 'Rankings & momentum',
                tint: Color(0xFF7C3AED),
              ),
              const _PreviewSpec(
                icon: AppIcons.problems,
                title: 'Problems',
                caption: 'Challenge statements',
                tint: Color(0xFF0EA5E9),
              ),
              const _PreviewSpec(
                icon: AppIcons.insights,
                title: 'Analytics',
                caption: 'Insights & trends',
                tint: Color(0xFF059669),
              ),
              const _PreviewSpec(
                icon: AppIcons.ideas,
                title: 'Ideas',
                caption: 'Submissions & progress',
                tint: Color(0xFFEA580C),
              ),
            ];
            final cross = w < 520 ? 2 : 4;
            return AbsorbPointer(
              child: Opacity(
                opacity: 0.88,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tiles
                      .map(
                        (t) => SizedBox(
                          width: (w - 10 * (cross - 1)) / cross,
                          child: _PreviewTile(spec: t),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PreviewSpec {
  const _PreviewSpec({
    required this.icon,
    required this.title,
    required this.caption,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color tint;
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.spec});

  final _PreviewSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            spec.tint.withOpacity(0.12),
            Colors.white,
          ],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(spec.icon, color: spec.tint, size: 22),
          const SizedBox(height: 8),
          Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 2),
          Text(spec.caption, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: spec.tint.withOpacity(0.85),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
