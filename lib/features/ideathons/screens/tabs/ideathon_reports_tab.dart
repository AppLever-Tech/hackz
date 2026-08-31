import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/features/events/models/event_report_item.dart';
import 'package:hackz/features/events/widgets/event_reports_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonReportsTab extends StatelessWidget {
  const IdeathonReportsTab({
    super.key,
    required this.vm,
    required this.actor,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    final bool hasIdeas = vm.ideas.isNotEmpty;
    final bool hasWinner = vm.ideathon.winnerIdeaId.trim().isNotEmpty;
    final bool hasRunnerUp = vm.ideathon.runnerUpIdeaId.trim().isNotEmpty;
    return EventReportsSection(
      items: <EventReportItem>[
        EventReportItem(
          id: 'participation',
          title: 'Participation e-certificates',
          description: 'Certificates for ideas registered in this event.',
          icon: AppIcons.ideas,
          available: hasIdeas,
          unavailableReason: 'Add participating ideas before generating certificates.',
          onDownload: () => _unavailable(context, 'Participation e-certificates'),
        ),
        EventReportItem(
          id: 'winner',
          title: 'Winner certificates',
          description: 'Certificates for the official winner selected by Department Admin.',
          icon: AppIcons.achievement,
          available: hasWinner,
          unavailableReason: 'Winner certificates are available after Department Admin selects a winner.',
          onDownload: () => _unavailable(context, 'Winner certificates'),
        ),
        EventReportItem(
          id: 'runnerUp',
          title: 'Runner-up certificates',
          description: 'Certificates for the official runner-up selected by Department Admin.',
          icon: AppIcons.results,
          available: hasRunnerUp,
          unavailableReason: 'Runner-up certificates are available after Department Admin selects a runner-up.',
          onDownload: () => _unavailable(context, 'Runner-up certificates'),
        ),
      ],
    );
  }

  static Future<void> _unavailable(BuildContext context, String title) {
    return FeedbackService.showInfo(
      context,
      title: title,
      message:
          'Certificate templates are not configured for this organisation yet. The Reports module is ready for Hackathon reuse once generation is enabled.',
    );
  }
}
