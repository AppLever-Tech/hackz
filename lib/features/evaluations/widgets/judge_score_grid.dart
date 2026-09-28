import 'package:flutter/material.dart';

/// Discrete `min`..`max` score grid (red → green). Originally hardcoded to
/// 1–10; now parameterized so template-driven evaluation criteria with any
/// scale can reuse it.
class JudgeScoreGrid extends StatelessWidget {
  const JudgeScoreGrid({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.label = 'Score',
    this.compact = false,
    this.hint,
    this.readOnly = false,
    this.minValue = 1,
    this.maxValue = 10,
    this.showLabel = true,
    this.showHeaderValue = true,
  });

  final int selectedValue;
  final ValueChanged<int> onChanged;
  final String label;
  final bool compact;
  final String? hint;
  final bool readOnly;
  final int minValue;
  final int maxValue;

  /// When false, the title row is not rendered (caller supplies its own
  /// header — e.g. inside [CriterionScoreCard]).
  final bool showLabel;

  /// When false, the large number on the right of the header is suppressed.
  /// Has no effect when [showLabel] is false.
  final bool showHeaderValue;

  int get _count => (maxValue - minValue + 1).clamp(2, 20);

  static Color _hueFor(int value, int min, int max) {
    if (max <= min) return const Color(0xFF6366F1);
    final double t = ((value.clamp(min, max) - min) / (max - min)).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFDC2626), const Color(0xFF16A34A), t)!;
  }

  static Color tileSurface(int value, {int min = 1, int max = 10}) {
    final Color c = _hueFor(value, min, max);
    return Color.alphaBlend(c.withValues(alpha: 0.22), const Color(0xFFFFFFFF));
  }

  /// Backwards-compatible 1–10 hue lookup retained for callers that haven't
  /// migrated to the parameterized form yet.
  static Color hueForScore(int value) => _hueFor(value, 1, 10);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = compact
        ? theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: const Color(0xFF475569))
        : theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: const Color(0xFF475569));
    final double big = (theme.textTheme.headlineLarge?.fontSize ?? 32) + (compact ? 0 : 4);
    final int min = minValue;
    final int max = maxValue;
    final int safeSelected = selectedValue.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showLabel)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (showHeaderValue) ...<Widget>[
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) {
                    final Color c = _hueFor(safeSelected, min, max);
                    return LinearGradient(
                      colors: <Color>[Color.lerp(c, Colors.black, 0.12)!, c],
                    ).createShader(bounds);
                  },
                  child: Text(
                    '$safeSelected',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1,
                      fontSize: big,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: compact ? 2 : 4, bottom: compact ? 2 : 6),
                  child: Text(
                    '/ $max',
                    style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (showLabel) SizedBox(height: compact ? 8 : 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int n = _count;
            // Wrap when the row would force each tile under ~22px wide.
            final double minTileWidth = compact ? 26 : 32;
            final bool useWrap = constraints.maxWidth / n < minTileWidth;
            final List<Widget> chips = List<Widget>.generate(n, (int i) {
              final int v = min + i;
              final bool selected = v == safeSelected;
              final Color accent = _hueFor(v, min, max);
              final Color fg = Color.lerp(accent, Colors.black, 0.52)!;

              Widget tile = AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 8 : 12),
                  color: tileSurface(v, min: min, max: max),
                  border: Border.all(
                    color: selected ? Color.lerp(accent, Colors.black, 0.18)! : const Color(0xFFCBD5E1),
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: compact ? 8 : 12, offset: const Offset(0, 3)),
                        ]
                      : <BoxShadow>[
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                        ],
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: readOnly ? null : () => onChanged(v),
                      borderRadius: BorderRadius.circular(compact ? 7 : 11),
                      splashColor: accent.withValues(alpha: 0.25),
                      child: Center(
                        child: Text(
                          '$v',
                          style: (compact ? theme.textTheme.labelLarge : theme.textTheme.titleMedium)?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: fg,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              if (selected) {
                tile = AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: compact ? 1.04 : 1.06,
                  child: tile,
                );
              }

              final Widget padded = Padding(
                padding: EdgeInsets.all(compact ? 2 : 4),
                child: Semantics(
                  button: !readOnly,
                  selected: selected,
                  label: '$label $v out of $max',
                  child: tile,
                ),
              );

              if (!useWrap) {
                return Expanded(child: padded);
              }
              final int perRow = (constraints.maxWidth / (minTileWidth + 4)).floor().clamp(2, n);
              final double w = constraints.maxWidth / perRow;
              return SizedBox(width: w, child: padded);
            });

            if (useWrap) {
              return Wrap(alignment: WrapAlignment.start, runSpacing: 4, children: chips);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: chips);
          },
        ),
        if (hint != null && hint!.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: compact ? 4 : 8),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
