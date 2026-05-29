import 'package:flutter/material.dart';

import '../../../core/theme/auth_theme.dart';
import 'landing_pipeline_data.dart';

/// Stacked capability pills: icon + title + caption per row.
class CapabilityPillList extends StatelessWidget {
  const CapabilityPillList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: LandingCapabilityData.items
          .map(
            (LandingCapability item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CapabilityPill(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _CapabilityPill extends StatefulWidget {
  const _CapabilityPill({required this.item});

  final LandingCapability item;

  @override
  State<_CapabilityPill> createState() => _CapabilityPillState();
}

class _CapabilityPillState extends State<_CapabilityPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hovered ? 0.78 : 0.66),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.item.accent.withValues(alpha: _hovered ? 0.45 : 0.28),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.item.accent.withValues(alpha: _hovered ? 0.18 : 0.08),
              blurRadius: _hovered ? 10 : 5,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.item.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.item.icon, size: 20, color: widget.item.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.item.title, style: AuthTheme.featureTitleStyle),
                  const SizedBox(height: 3),
                  Text(
                    widget.item.caption,
                    style: AuthTheme.cardCaptionStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
