import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/status_styles.dart';
import '../models/enums/idea_status.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../evaluations/models/score_model.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../shared/widgets/lifecycle_timeline.dart';
import '../widgets/idea_lifecycle_strip.dart';
import '../workspace/idea_workspace_loader.dart';

/// Idea Lifecycle tab for [IdeaDetailsPane].
class IdeaLifecycleTab extends StatelessWidget {
  const IdeaLifecycleTab({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents(vm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: IdeaLifecycleStrip(currentStatus: vm.idea.status),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: LifecycleTimeline(
            title: 'Innovation lifecycle',
            subtitle: '${events.length} event${events.length == 1 ? '' : 's'} tracked',
            events: events,
          ),
        ),
      ],
    );
  }

  static List<LifecycleTimelineEvent> _buildEvents(IdeaWorkspaceViewModel vm) {
    final idea = vm.idea;
    final List<LifecycleTimelineEvent> events = <LifecycleTimelineEvent>[
      LifecycleTimelineEvent(
        title: 'Innovation created',
        subtitle: idea.ideaTitle.trim().isEmpty ? 'Draft recorded' : idea.ideaTitle.trim(),
        when: idea.createdAt,
        icon: AppIcons.ideas,
        color: const Color(0xFF6A38FF),
      ),
      LifecycleTimelineEvent(
        title: ideaWorkspaceStatusLabel(idea.status),
        subtitle: StatusStyles.labelForIdeaStatus(idea.status),
        when: idea.createdAt,
        icon: StatusStyles.iconForIdeaStatus(idea.status),
        color: StatusStyles.colorForIdeaStatus(idea.status),
      ),
    ];

    if (vm.scores.isNotEmpty) {
      final ScoreModel latest = vm.scores.first;
      events.add(
        LifecycleTimelineEvent(
          title: 'Evaluated',
          subtitle: 'Score ${latest.score.toStringAsFixed(1)} · ${vm.reviewerCount} reviewer${vm.reviewerCount == 1 ? '' : 's'}',
          when: latest.createdAt,
          icon: StatusStyles.iconForIdeaStatus(IdeaStatus.evaluated),
          color: const Color(0xFF0EA5E9),
        ),
      );
    }

    final PaymentModel? payment = vm.payment;
    if (payment != null) {
      events.add(
        LifecycleTimelineEvent(
          title: 'Payment ${vm.paymentStatusLabel.toLowerCase()}',
          subtitle: payment.paymentId.trim().isEmpty ? 'Contribution record' : 'Payment ${payment.paymentId.trim()}',
          when: payment.createdAt,
          icon: AppIcons.payments,
          color: const Color(0xFF059669),
        ),
      );
    }

    events.sort((LifecycleTimelineEvent a, LifecycleTimelineEvent b) {
      final DateTime aWhen = a.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bWhen = b.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bWhen.compareTo(aWhen);
    });

    return events;
  }
}
