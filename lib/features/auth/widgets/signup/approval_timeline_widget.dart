import 'package:flutter/material.dart';

import 'approval_timeline_vm.dart';

class ApprovalTimelineWidget extends StatelessWidget {
  const ApprovalTimelineWidget({
    super.key,
    required this.steps,
  });

  final List<ApprovalTimelineStepVm> steps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _verticalLayout(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _horizontalLayout(),
        );
      },
    );
  }

  List<Widget> _horizontalLayout() {
    final out = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      out.add(Expanded(child: _StepTile(step: steps[i])));
      if (i < steps.length - 1) {
        out.add(_ConnectorLine(stateLeft: steps[i].state));
      }
    }
    return out;
  }

  List<Widget> _verticalLayout() {
    return List<Widget>.generate(steps.length, (int i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StepIcon(step: steps[i]),
            const SizedBox(width: 12),
            Expanded(child: _StepLabels(step: steps[i], alignStart: true)),
          ],
        ),
      );
    });
  }
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({required this.stateLeft});

  final ApprovalTimelineNodeState stateLeft;

  @override
  Widget build(BuildContext context) {
    final bool active = stateLeft == ApprovalTimelineNodeState.completed ||
        stateLeft == ApprovalTimelineNodeState.error;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final ApprovalTimelineStepVm step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _StepIcon(step: step),
        const SizedBox(height: 8),
        _StepLabels(step: step, alignStart: false),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.step});

  final ApprovalTimelineStepVm step;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(step.state);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.background,
        border: Border.all(color: style.border, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: style.background.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(step.icon, size: 20, color: style.iconColor),
    );
  }

  _NodeStyle _styleFor(ApprovalTimelineNodeState s) {
    switch (s) {
      case ApprovalTimelineNodeState.completed:
        return const _NodeStyle(
          background: Color(0xFFE8F8EE),
          border: Color(0xFF86EFAC),
          iconColor: Color(0xFF15803D),
        );
      case ApprovalTimelineNodeState.current:
        return const _NodeStyle(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFDBA74),
          iconColor: Color(0xFFC2410C),
        );
      case ApprovalTimelineNodeState.upcoming:
        return const _NodeStyle(
          background: Color(0xFFF8FAFC),
          border: Color(0xFFE2E8F0),
          iconColor: Color(0xFF94A3B8),
        );
      case ApprovalTimelineNodeState.error:
        return const _NodeStyle(
          background: Color(0xFFFEF2F2),
          border: Color(0xFFF87171),
          iconColor: Color(0xFFB91C1C),
        );
    }
  }
}

class _NodeStyle {
  const _NodeStyle({
    required this.background,
    required this.border,
    required this.iconColor,
  });

  final Color background;
  final Color border;
  final Color iconColor;
}

class _StepLabels extends StatelessWidget {
  const _StepLabels({required this.step, required this.alignStart});

  final ApprovalTimelineStepVm step;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final TextAlign ta = alignStart ? TextAlign.start : TextAlign.center;
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          step.title,
          textAlign: ta,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: switch (step.state) {
              ApprovalTimelineNodeState.upcoming => const Color(0xFF94A3B8),
              ApprovalTimelineNodeState.error => const Color(0xFFB91C1C),
              _ => const Color(0xFF334155),
            },
          ),
        ),
        const SizedBox(height: 2),
        Text(
          switch (step.state) {
            ApprovalTimelineNodeState.completed => 'Completed',
            ApprovalTimelineNodeState.current => 'In progress',
            ApprovalTimelineNodeState.upcoming => 'Queued',
            ApprovalTimelineNodeState.error => 'Needs attention',
          },
          textAlign: ta,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
