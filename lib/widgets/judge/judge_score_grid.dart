import 'package:flutter/material.dart';

/// Discrete 1–10 score grid (red → green). Reused by evaluation flows.
class JudgeScoreGrid extends StatelessWidget {
  const JudgeScoreGrid({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.label = 'Score',
    this.compact = false,
    this.hint,
  });

  final int selectedValue;
  final ValueChanged<int> onChanged;
  final String label;
  final bool compact;
  final String? hint;

  static Color hueForScore(int value) {
    final t = (value.clamp(1, 10) - 1) / 9.0;
    return Color.lerp(const Color(0xFFDC2626), const Color(0xFF16A34A), t)!;
  }

  static Color tileSurface(int value) {
    final c = hueForScore(value);
    return Color.alphaBlend(c.withValues(alpha: 0.22), const Color(0xFFFFFFFF));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = compact
        ? theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: const Color(0xFF475569))
        : theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: const Color(0xFF475569));
    final big = (theme.textTheme.headlineLarge?.fontSize ?? 32) + (compact ? 0 : 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(label, style: labelStyle),
            const Spacer(),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final Color c = hueForScore(selectedValue);
                return LinearGradient(
                  colors: <Color>[Color.lerp(c, Colors.black, 0.12)!, c],
                ).createShader(bounds);
              },
              child: Text(
                '$selectedValue',
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
                '/ 10',
                style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleLarge)?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useWrap = constraints.maxWidth < (compact ? 320 : 400);
            final chips = List<Widget>.generate(10, (int i) {
              final int v = i + 1;
              final bool selected = v == selectedValue;
              final Color accent = hueForScore(v);
              final Color fg = Color.lerp(accent, Colors.black, 0.52)!;

              Widget tile = AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 8 : 12),
                  color: tileSurface(v),
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
                      onTap: () => onChanged(v),
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
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  scale: compact ? 1.04 : 1.06,
                  child: tile,
                );
              }

              final Widget padded = Padding(
                padding: EdgeInsets.all(compact ? 2 : 4),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '$label $v out of 10',
                  child: tile,
                ),
              );

              if (!useWrap) {
                return Expanded(child: padded);
              }
              final double w = constraints.maxWidth / 5;
              return SizedBox(width: w, child: padded);
            });

            if (useWrap) {
              return Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 4, children: chips);
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
