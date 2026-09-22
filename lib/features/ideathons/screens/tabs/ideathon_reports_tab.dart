import 'package:flutter/material.dart';
import 'package:hackz/core/responsive/mobile_toolbar_button_styles.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/widgets/certificate_generation_dialog.dart';
import 'package:hackz/features/events/widgets/event_detail_section.dart';
import 'package:hackz/features/exports/certificate/certificate_event_context.dart';
import 'package:hackz/features/exports/services/export_tenant_guard.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonReportsTab extends StatelessWidget {
  const IdeathonReportsTab({super.key, required this.vm, required this.actor});

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    final CertificateEventContext eventContext = CertificateEventContext.fromIdeathonDetails(vm);
    final bool canGenerate = ExportTenantGuard.actorMatchesBoundOrganisation(actor) &&
        (eventContext.participationEntries.isNotEmpty ||
            eventContext.winnerEntry != null ||
            eventContext.runnerUpEntry != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        const Text(
          'Generate participation, winner, and runner-up certificates on demand. Large batches are processed in controlled groups.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        EventDetailSection(
          title: 'Certificates',
          icon: AppIcons.achievement,
          titleFontSize: 14,
          titleFontWeight: FontWeight.w900,
          titleColor: const Color(0xFF0F172A),
          trailing: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: canGenerate
                  ? () => showCertificateGenerationDialog(
                        context: context,
                        event: eventContext,
                        actor: actor,
                      )
                  : null,
              icon: const Icon(AppIcons.download, size: MobileToolbarButtonStyles.toolbarIconSize),
              label: const Text('Generate Certificates'),
              style: MobileToolbarButtonStyles.filled(compact: true),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${vm.ideathon.eventKind.label} · ${eventContext.submissionLabel} · ${eventContext.participationEntries.length} participating entries',
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
              ),
              if (!canGenerate) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Add participating ${vm.ideathon.eventKind.entriesLabel.toLowerCase()} before generating certificates.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
