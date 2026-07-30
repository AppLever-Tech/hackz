import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';

/// Soft status pill for documentation (Draft / Active / Inactive / Archived…).
class DocumentationStatusPill extends StatefulWidget {
  const DocumentationStatusPill({
    super.key,
    required this.label,
    this.kind = DocStatusKind.custom,
    this.color,
  });

  final String label;
  final DocStatusKind kind;
  final Color? color;

  @override
  State<DocumentationStatusPill> createState() => _DocumentationStatusPillState();
}

class _DocumentationStatusPillState extends State<DocumentationStatusPill> {
  bool _hover = false;

  Color _tone(ColorScheme cs) {
    if (widget.color != null) return widget.color!;
    return switch (widget.kind) {
      DocStatusKind.draft => cs.tertiary,
      DocStatusKind.active => cs.primary,
      DocStatusKind.inactive => cs.outline,
      DocStatusKind.archived => cs.outlineVariant,
      DocStatusKind.custom => cs.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color tone = _tone(cs);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: _hover ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tone.withValues(alpha: 0.35)),
          boxShadow: _hover
              ? <BoxShadow>[
                  BoxShadow(
                    color: tone.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tone,
          ),
        ),
      ),
    );
  }
}

/// Callout / info card.
class DocumentationInfoCard extends StatelessWidget {
  const DocumentationInfoCard({
    super.key,
    required this.title,
    required this.body,
    this.tone = DocInfoTone.information,
  });

  final String title;
  final String body;
  final DocInfoTone tone;

  (IconData, Color) _meta(ColorScheme cs) {
    return switch (tone) {
      DocInfoTone.information => (AppIcons.info, cs.primary),
      DocInfoTone.important => (Icons.priority_high_rounded, cs.error),
      DocInfoTone.success => (Icons.check_circle_outline_rounded, cs.tertiary),
      DocInfoTone.warning => (Icons.warning_amber_rounded, cs.secondary),
      DocInfoTone.note => (Icons.sticky_note_2_outlined, cs.outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = _meta(cs);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded content card.
class DocumentationCard extends StatelessWidget {
  const DocumentationCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Anchored documentation section (feeds TOC).
class DocumentationSection extends StatelessWidget {
  const DocumentationSection({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, height: 1.45, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// FAQ / notes accordion.
class DocumentationAccordion extends StatelessWidget {
  const DocumentationAccordion({
    super.key,
    required this.items,
  });

  final List<({String title, String body})> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Code / CSV / JSON / Mermaid source block with copy.
class DocumentationCodeBlock extends StatefulWidget {
  const DocumentationCodeBlock({
    super.key,
    required this.code,
    this.language = 'text',
    this.title,
  });

  final String code;
  final String language;
  final String? title;

  @override
  State<DocumentationCodeBlock> createState() => _DocumentationCodeBlockState();
}

class _DocumentationCodeBlockState extends State<DocumentationCodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title ?? widget.language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _copied ? 'Copied' : 'Copy',
                  onPressed: _copy,
                  icon: Icon(
                    _copied ? AppIcons.copied : AppIcons.copy,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontFamilyFallback: const <String>['Courier New', 'monospace'],
                fontSize: 12.5,
                height: 1.45,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
