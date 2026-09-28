import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../exports/certificate/certificate_event_signatory_config.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import '../../exports/certificate/certificate_signatory_people_loader.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../../user/models/user_model.dart';
import 'certificate_generation_dialog_signatories.dart';

Future<CertificateEventSignatoryDraft?> showCertificateSignatoryConfigurationDialog({
  required BuildContext context,
  required IdeathonModel ideathon,
  CertificateEventSignatoryDraft? initialDraft,
}) {
  return showAppDialog<CertificateEventSignatoryDraft>(
    context: context,
    width: DialogWidthPreset.wide,
    barrierDismissible: false,
    child: CertificateSignatoryConfigurationDialog(
      ideathon: ideathon,
      initialDraft: initialDraft,
    ),
  );
}

class CertificateSignatoryConfigurationDialog extends StatefulWidget {
  const CertificateSignatoryConfigurationDialog({
    super.key,
    required this.ideathon,
    this.initialDraft,
  });

  final IdeathonModel ideathon;
  final CertificateEventSignatoryDraft? initialDraft;

  @override
  State<CertificateSignatoryConfigurationDialog> createState() => _CertificateSignatoryConfigurationDialogState();
}

class _CertificateSignatoryConfigurationDialogState extends State<CertificateSignatoryConfigurationDialog> {
  int _signatoryCount = 2;
  List<CertificateSignatorySlotDraft> _slots = CertificateEventSignatoryConfig.normalizedSlots(null);
  List<UserModel> _eligiblePeople = const <UserModel>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyDraft(widget.initialDraft);
    _loadPeople();
  }

  void _applyDraft(CertificateEventSignatoryDraft? draft) {
    _signatoryCount = CertificateEventSignatoryConfig.normalizedCount(draft);
    _slots = CertificateEventSignatoryConfig.normalizedSlots(draft);
  }

  Future<void> _loadPeople() async {
    final List<UserModel> people = await CertificateSignatoryPeopleLoader.load(
      orgId: widget.ideathon.orgId,
      departmentCode: widget.ideathon.departmentId,
      eventCoordinatorIds: widget.ideathon.coordinatorIds,
    );
    if (!mounted) return;
    setState(() {
      _eligiblePeople = people;
      _loading = false;
    });
  }

  CertificateEventSignatoryDraft get _draft =>
      CertificateEventSignatoryDraft(signatoryCount: _signatoryCount, slots: _slots);

  Future<void> _save() async {
    if (!CertificateEventSignatoryConfig.meetsMinimum(_draft)) {
      await FeedbackService.showError(
        context,
        title: 'Signatories incomplete',
        message: 'Add at least ${CertificateEventSignatoryConfig.minimumSignatories} signatories with a name on the certificate.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await CertificateEventSignatoryStore.save(widget.ideathon.ideathonId, _draft);
      if (!mounted) return;
      Navigator.of(context).pop(_draft);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Certificate signatories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure signatories once for all certificate types in this event. Edits here do not change user profiles.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: HkzProgressIndicator(size: 28))
        else
          CertificateEventSignatoryConfigurationSection(
            signatoryCount: _signatoryCount,
            slots: _slots,
            eligiblePeople: _eligiblePeople,
            allEligiblePeople: _eligiblePeople,
            enabled: !_saving,
            onSignatoryCountChanged: (int count) => setState(() => _signatoryCount = count),
            onSlotChanged: (int index, CertificateSignatorySlotDraft slot) => setState(() => _slots[index] = slot),
          ),
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: HkzProgressIndicator(size: 18, strokeWidth: 2.2))
                  : const Text('Save signatories'),
            ),
          ],
        ),
      ],
    );
  }
}
