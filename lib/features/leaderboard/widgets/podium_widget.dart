import 'package:flutter/material.dart';

import '../services/leaderboard_showcase_service.dart';

/// Premium podium for ranks #2, #1, #3 (left → center → right).
class PodiumWidget extends StatelessWidget {
  const PodiumWidget({
    super.key,
    required this.rows,
  });

  /// Expect up to 3 entries ordered by rank (caller passes sorted rank 1..3 slice).
  final List<TeamShowcaseRow> rows;

  @override
  Widget build(BuildContext context) {
    final second = rows.length > 1 ? rows[1] : null;
    final first = rows.isNotEmpty ? rows.first : null;
    final third = rows.length > 2 ? rows[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth / 3 - 8;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: _PodiumSlot(rankLabel: '2', row: second, heightFactor: 0.72, widthCap: w)),
            Expanded(child: _PodiumSlot(rankLabel: '1', row: first, heightFactor: 1.0, widthCap: w)),
            Expanded(child: _PodiumSlot(rankLabel: '3', row: third, heightFactor: 0.62, widthCap: w)),
          ],
        );
      },
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.rankLabel,
    required this.row,
    required this.heightFactor,
    required this.widthCap,
  });

  final String rankLabel;
  final TeamShowcaseRow? row;
  final double heightFactor;
  final double widthCap;

  @override
  Widget build(BuildContext context) {
    final baseHeight = 120.0;
    final h = baseHeight * heightFactor;
    final gradient = switch (rankLabel) {
      '1' => const <Color>[Color(0xFF7C3AED), Color(0xFFA855F7)],
      '2' => const <Color>[Color(0xFF2563EB), Color(0xFF38BDF8)],
      _ => const <Color>[Color(0xFFEA580C), Color(0xFFF97316)],
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '#$rankLabel',
            style: TextStyle(
              fontSize: rankLabel == '1' ? 28 : 22,
              fontWeight: FontWeight.w800,
              color: gradient.first,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: widthCap.clamp(72, 160),
            height: h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10)),
                ],
              ),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              child: Text(
                row == null
                    ? '—'
                    : row!.teamName,
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
