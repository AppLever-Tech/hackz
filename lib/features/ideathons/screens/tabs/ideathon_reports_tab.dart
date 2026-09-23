import 'package:flutter/material.dart';

import 'package:hackz/features/events/widgets/certificate_event_signatory_panel.dart';
import 'package:hackz/features/events/widgets/certificate_signatory_configuration_dialog.dart';
import 'package:hackz/features/events/widgets/event_reports_section.dart';
import 'package:hackz/features/exports/certificate/certificate_event_context.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_config.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';
import 'package:hackz/features/ideathons/reports/ideathon_certificate_report_items.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonReportsTab extends StatefulWidget {
  const IdeathonReportsTab({super.key, required this.vm, required this.actor});

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  State<IdeathonReportsTab> createState() => _IdeathonReportsTabState();
}

class _IdeathonReportsTabState extends State<IdeathonReportsTab> {
  CertificateEventSignatoryDraft? _signatoryDraft;
  bool _loadingSignatories = true;

  @override
  void initState() {
    super.initState();
    _reloadSignatories();
  }

  Future<void> _reloadSignatories() async {
    final CertificateEventSignatoryDraft? saved =
        await CertificateEventSignatoryStore.load(widget.vm.ideathon.ideathonId);
    if (!mounted) return;
    setState(() {
      _signatoryDraft = saved;
      _loadingSignatories = false;
    });
  }

  Future<void> _openSignatories() async {
    final CertificateEventSignatoryDraft? saved = await showCertificateSignatoryConfigurationDialog(
      context: context,
      ideathon: widget.vm.ideathon,
      initialDraft: _signatoryDraft,
    );
    if (saved == null || !mounted) return;
    setState(() => _signatoryDraft = saved);
  }

  @override
  Widget build(BuildContext context) {
    final CertificateEventContext eventContext = CertificateEventContext.fromIdeathonDetails(widget.vm);
    final bool signatoriesReady = CertificateEventSignatoryConfig.meetsMinimum(_signatoryDraft);

    return FutureBuilder<int>(
      future: IdeathonCertificateReportItems.countParticipants(eventContext),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int participantCount = snapshot.data ?? 0;
        final items = IdeathonCertificateReportItems.build(
          vm: widget.vm,
          actor: widget.actor,
          event: eventContext,
          participantCount: participantCount,
          signatoryDraft: _signatoryDraft,
          signatoriesReady: signatoriesReady,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          children: <Widget>[
            const Text(
              'Configure signatories once, then generate or download participation, winner, and runner-up certificates.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingSignatories)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              CertificateEventSignatoryPanel(
                draft: _signatoryDraft,
                onEdit: _openSignatories,
              ),
            if (!signatoriesReady && !_loadingSignatories) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Add at least ${CertificateEventSignatoryConfig.minimumSignatories} signatories to generate certificates.',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 12),
            EventReportsSection(
              items: items,
              certificatesReady: signatoriesReady,
              onOpenSignatories: _openSignatories,
            ),
          ],
        );
      },
    );
  }
}
