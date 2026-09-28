import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

enum PageHeaderContextKind {
  organization,
  department,
}

/// One labeled context chip under a dashboard page title (org, department, …).
class PageHeaderContextItem {
  const PageHeaderContextItem({
    required this.icon,
    required this.label,
    required this.kind,
  });

  factory PageHeaderContextItem.organization(String name) {
    return PageHeaderContextItem(
      icon: AppIcons.organizations,
      label: name,
      kind: PageHeaderContextKind.organization,
    );
  }

  factory PageHeaderContextItem.department(String name) {
    return PageHeaderContextItem(
      icon: AppIcons.departments,
      label: name,
      kind: PageHeaderContextKind.department,
    );
  }

  final IconData icon;
  final String label;
  final PageHeaderContextKind kind;

  @override
  bool operator ==(Object other) {
    return other is PageHeaderContextItem &&
        other.icon == icon &&
        other.label == label &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(icon, label, kind);
}

/// Subtitle typography and tint for header context pills.
abstract final class PageHeaderContextPillStyle {
  PageHeaderContextPillStyle._();

  static const double iconSize = 14;
  static const double iconGap = 6;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  static const TextStyle textStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static Color fillFor(PageHeaderContextKind kind) {
    return switch (kind) {
      PageHeaderContextKind.organization => const Color(0xFFEEF2FF),
      PageHeaderContextKind.department => const Color(0xFFF3E8FF),
    };
  }

  static Color borderFor(PageHeaderContextKind kind) {
    return switch (kind) {
      PageHeaderContextKind.organization => const Color(0xFFC7D2FE),
      PageHeaderContextKind.department => const Color(0xFFE9D5FF),
    };
  }

  static Color foregroundFor(PageHeaderContextKind kind) {
    return switch (kind) {
      PageHeaderContextKind.organization => const Color(0xFF4338CA),
      PageHeaderContextKind.department => const Color(0xFF7C3AED),
    };
  }
}

/// Icon + label pill shown as page-title subtext.
class PageHeaderContextPill extends StatelessWidget {
  const PageHeaderContextPill({
    super.key,
    required this.icon,
    required this.label,
    required this.kind,
  });

  factory PageHeaderContextPill.fromItem(PageHeaderContextItem item) {
    return PageHeaderContextPill(
      icon: item.icon,
      label: item.label,
      kind: item.kind,
    );
  }

  final IconData icon;
  final String label;
  final PageHeaderContextKind kind;

  @override
  Widget build(BuildContext context) {
    final Color fill = PageHeaderContextPillStyle.fillFor(kind);
    final Color border = PageHeaderContextPillStyle.borderFor(kind);
    final Color foreground = PageHeaderContextPillStyle.foregroundFor(kind);

    return Container(
      padding: PageHeaderContextPillStyle.padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: PageHeaderContextPillStyle.iconSize,
            color: foreground,
          ),
          const SizedBox(width: PageHeaderContextPillStyle.iconGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PageHeaderContextPillStyle.textStyle.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of [PageHeaderContextPill]s under a page title.
class PageHeaderContextPills extends StatelessWidget {
  const PageHeaderContextPills({
    super.key,
    required this.items,
  });

  final List<PageHeaderContextItem> items;

  @override
  Widget build(BuildContext context) {
    final List<PageHeaderContextItem> visible = items
        .where((PageHeaderContextItem item) => item.label.trim().isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: visible
          .map((PageHeaderContextItem item) => PageHeaderContextPill.fromItem(item))
          .toList(growable: false),
    );
  }
}
