import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// One labeled count inside a [DashboardMetricChip] (e.g. submitted / approved / rejected).
class DashboardMetricChipSegment {
  const DashboardMetricChipSegment({
    required this.value,
    required this.icon,
    required this.tooltip,
    this.color,
  });

  final String value;
  final IconData icon;
  final String tooltip;
  final Color? color;
}

/// Data for a gradient metric chip (shared across role dashboards).
class DashboardMetricChipData {
  DashboardMetricChipData({
    required this.label,
    required this.color,
    required this.icon,
    this.subtitle,
    this.values = const <String>[],
    this.segments = const <DashboardMetricChipSegment>[],
    this.tooltip,
  }) : assert(
          values.isNotEmpty || segments.isNotEmpty,
          'Provide at least one value or segment',
        );

  final String label;
  final Color color;
  final IconData icon;
  final String? subtitle;
  final List<String> values;
  final List<DashboardMetricChipSegment> segments;
  final String? tooltip;

  factory DashboardMetricChipData.single({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    String? subtitle,
    String? tooltip,
  }) {
    return DashboardMetricChipData(
      label: label,
      color: color,
      icon: icon,
      subtitle: subtitle,
      tooltip: tooltip,
      values: <String>[value],
    );
  }

  factory DashboardMetricChipData.ratio({
    required String label,
    required String primary,
    required String secondary,
    required Color color,
    required IconData icon,
    String? subtitle,
    String? tooltip,
  }) {
    return DashboardMetricChipData(
      label: label,
      color: color,
      icon: icon,
      subtitle: subtitle,
      tooltip: tooltip,
      values: <String>[primary, secondary],
    );
  }

  factory DashboardMetricChipData.withSegments({
    required String label,
    required Color color,
    required IconData icon,
    required List<DashboardMetricChipSegment> segments,
    String? subtitle,
    String? tooltip,
  }) {
    return DashboardMetricChipData(
      label: label,
      color: color,
      icon: icon,
      subtitle: subtitle,
      tooltip: tooltip,
      segments: segments,
    );
  }

  String get displayValue {
    if (segments.isNotEmpty) return '';
    if (values.isEmpty) return '—';
    if (values.length == 1) return values.first;
    return values.join(' / ');
  }
}

/// Single gradient metric chip.
class DashboardMetricChip extends StatelessWidget {
  const DashboardMetricChip({super.key, required this.data});

  final DashboardMetricChipData data;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            data.color.withValues(alpha: 0.08),
            data.color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 2),
                _buildValueArea(),
                if (data.subtitle != null && data.subtitle!.trim().isNotEmpty)
                  Text(
                    data.subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final message = data.tooltip;
    if (message == null || message.trim().isEmpty) return chip;
    return Tooltip(message: message, child: chip);
  }

  Widget _buildValueArea() {
    if (data.segments.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < data.segments.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _SegmentCount(segment: data.segments[i], fallbackColor: data.color),
              ),
            ],
          ],
        ),
      );
    }

    return Text(
      data.displayValue,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        height: 1.1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SegmentCount extends StatelessWidget {
  const _SegmentCount({required this.segment, required this.fallbackColor});

  final DashboardMetricChipSegment segment;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final tint = segment.color ?? fallbackColor;
    return Tooltip(
      message: segment.tooltip,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(segment.icon, size: 16, color: tint),
            const SizedBox(width: 4),
            Text(
              segment.value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tint, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive row of metric chips: 4 per row on desktop, 2 on mobile/tablet.
class DashboardMetricChipGrid extends StatelessWidget {
  const DashboardMetricChipGrid({
    super.key,
    required this.chips,
    this.spacing,
    this.runSpacing,
  });

  final List<DashboardMetricChipData> chips;
  final double? spacing;
  final double? runSpacing;

  int _columnCount(BuildContext context) {
    if (chips.isEmpty) return 1;
    if (ResponsiveHelper.isDesktopOrWider(context)) {
      return chips.length < 4 ? chips.length : 4;
    }
    return chips.length < 2 ? chips.length : 2;
  }

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final gap = spacing ?? ResponsiveHelper.metricGridSpacing(context);
        final runGap = runSpacing ?? gap;
        final columns = _columnCount(context);
        final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: runGap,
          children: chips
              .map(
                (DashboardMetricChipData data) => SizedBox(
                  width: tileWidth,
                  child: DashboardMetricChip(data: data),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

/// Maps legacy pale icon bubble colors to saturated chip accents.
Color dashboardMetricAccentFromIconBg(Color iconBgColor) {
  if (iconBgColor == const Color(0xFFEAF2FF)) return const Color(0xFF4A67FF);
  if (iconBgColor == const Color(0xFFE9FAF0)) return const Color(0xFF16A34A);
  if (iconBgColor == const Color(0xFFE8FAF1)) return const Color(0xFF059669);
  if (iconBgColor == const Color(0xFFFFF4E8)) return const Color(0xFFEA580C);
  if (iconBgColor == const Color(0xFFFFF7ED)) return const Color(0xFFEA580C);
  if (iconBgColor == const Color(0xFFF2EDFF)) return const Color(0xFF7C3AED);
  if (iconBgColor == const Color(0xFFEFF6FF)) return const Color(0xFF0EA5E9);
  if (iconBgColor == const Color(0xFFFDECEC)) return const Color(0xFFDC2626);
  return Color.lerp(iconBgColor, const Color(0xFF334155), 0.55) ?? const Color(0xFF6366F1);
}
