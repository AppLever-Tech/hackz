import 'package:flutter/material.dart';

import '../../../responsive/responsive_helper.dart';
import 'innovation_milestone_node.dart';
import 'landing_section_header.dart';
import 'journey_connector_painter.dart';
import 'landing_pipeline_data.dart';

/// Structured 2-row sequential innovation grid (strict linear progression).
class InnovationJourneyGrid extends StatefulWidget {
  const InnovationJourneyGrid({super.key});

  /// Top: Idea → Prototype → Patent. Bottom (L→R): Funding ← Publication ← Product.
  static const List<int> _topRow = <int>[0, 1, 2];
  /// Product under Patent (col 2); Publication col 1; Funding col 0.
  static const List<int> _bottomRow = <int>[5, 4, 3];

  @override
  State<InnovationJourneyGrid> createState() => _InnovationJourneyGridState();
}

class _InnovationJourneyGridState extends State<InnovationJourneyGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compactTablet =
        ResponsiveHelper.isTablet(context) && !ResponsiveHelper.isDesktopOrWider(context);
    final double scale = compactTablet ? 0.9 : 1;
    final double nodeW = InnovationMilestoneNode.width * scale;
    final double nodeH = InnovationMilestoneNode.height * scale;
    const double rowGap = 36;
    final double gridHeight = nodeH * 2 + rowGap + 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const LandingSectionHeader(
          title: 'Structured Innovation Journey',
          subtitle:
              'Transform ideas into impactful products, research, and ventures through a connected innovation ecosystem.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: gridHeight,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double w = constraints.maxWidth;
              const double topY = 4;
              final double bottomY = topY + nodeH + rowGap;

              final double spreadW = w * (compactTablet ? 0.96 : 0.92);
              final double gap = (spreadW - nodeW * 3) / 2;
              final double step = nodeW + gap;
              final double offsetX = (w - (2 * gap + nodeW * 3)) / 2;

              Offset topLeft(int stageIndex) {
                final bool top = stageIndex <= 2;
                final int col = top
                    ? InnovationJourneyGrid._topRow.indexOf(stageIndex)
                    : InnovationJourneyGrid._bottomRow.indexOf(stageIndex);
                return Offset(offsetX + col * step, top ? topY : bottomY);
              }

              final List<JourneyConnectorSegment> segments =
                  <JourneyConnectorSegment>[
                JourneyConnectorSegment(
                  from: MilestoneAnchors.exitRight(topLeft(0), scale),
                  to: MilestoneAnchors.enterLeft(topLeft(1), scale),
                ),
                JourneyConnectorSegment(
                  from: MilestoneAnchors.exitRight(topLeft(1), scale),
                  to: MilestoneAnchors.enterLeft(topLeft(2), scale),
                ),
                JourneyConnectorSegment(
                  from: MilestoneAnchors.exitBottom(topLeft(2), scale),
                  to: MilestoneAnchors.enterTop(topLeft(3), scale),
                  emphasis: true,
                ),
                JourneyConnectorSegment(
                  from: MilestoneAnchors.exitLeft(topLeft(3), scale),
                  to: MilestoneAnchors.enterRight(topLeft(4), scale),
                  emphasis: true,
                ),
                JourneyConnectorSegment(
                  from: MilestoneAnchors.exitLeft(topLeft(4), scale),
                  to: MilestoneAnchors.enterRight(topLeft(5), scale),
                  emphasis: true,
                ),
              ];

              return AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      CustomPaint(
                        size: Size(w, gridHeight),
                        painter: JourneyConnectorPainter(
                          segments: segments,
                          pulse: _pulse.value,
                        ),
                      ),
                      for (int i = 0; i < LandingPipelineData.stages.length; i++)
                        Positioned(
                          left: topLeft(i).dx,
                          top: topLeft(i).dy,
                          child: InnovationMilestoneNode(
                            icon: LandingPipelineData.stages[i].icon,
                            label: LandingPipelineData.stages[i].label,
                            accent: LandingPipelineData.stages[i].accent,
                            scale: scale,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
