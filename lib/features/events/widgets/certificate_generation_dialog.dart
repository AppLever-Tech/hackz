import 'package:flutter/material.dart';

import '../../../core/download/hackz_file_download.dart';
import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../exports/certificate/certificate_batch_generator.dart';
import '../../exports/certificate/certificate_data.dart';
import '../../exports/certificate/certificate_document_builder.dart';
import '../../exports/certificate/certificate_event_context.dart';
import '../../exports/certificate/certificate_generation_plan.dart';
import '../../exports/certificate/certificate_generation_service.dart';
import '../../exports/certificate/certificate_selectable_entry.dart';
import '../../exports/certificate/certificate_team_member_loader.dart';
import '../../exports/certificate/certificate_type.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../user/models/user_model.dart';

Future<void> showCertificateGenerationDialog({
  required BuildContext context,
  required CertificateEventContext event,
  required UserModel actor,
}) {
  return showAppDialog<void>(
    context: context,
    width: DialogWidthPreset.wide,
    barrierDismissible: false,
    child: CertificateGenerationDialog(event: event, actor: actor),
  );
}

class CertificateGenerationDialog extends StatefulWidget {
  const CertificateGenerationDialog({
    super.key,
    required this.event,
    required this.actor,
  });

  final CertificateEventContext event;
  final UserModel actor;

  @override
  State<CertificateGenerationDialog> createState() => _CertificateGenerationDialogState();
}

class _CertificateGenerationDialogState extends State<CertificateGenerationDialog> {
  late CertificateType _certificateType;
  late CertificateRecipientType _recipientType;
  late Set<String> _selectedEntryIds;
  Map<String, List<CertificateMember>> _membersByTeam = <String, List<CertificateMember>>{};
  bool _loadingMembers = false;
  bool _generating = false;
  CertificateGenerationProgress? _progress;

  CertificateEventContext get event => widget.event;

  @override
  void initState() {
    super.initState();
    _certificateType = CertificateType.participation;
    _recipientType = CertificateRecipientType.team;
    _selectedEntryIds = _defaultSelectionIds(_certificateType);
  }

  Set<String> _defaultSelectionIds(CertificateType type) {
    return CertificateGenerationService.defaultSelection(event: event, type: type)
        .map((CertificateSelectableEntry e) => e.entryId)
        .toSet();
  }

  List<CertificateSelectableEntry> get _pool => switch (_certificateType) {
        CertificateType.participation => event.participationEntries,
        CertificateType.winner =>
          event.winnerEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.winnerEntry!],
        CertificateType.runnerUp =>
          event.runnerUpEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.runnerUpEntry!],
      };

  List<CertificateSelectableEntry> get _selectedEntries {
    return _pool.where((CertificateSelectableEntry e) => _selectedEntryIds.contains(e.entryId)).toList(growable: false);
  }

  CertificateGenerationPlan get _plan => CertificateGenerationService.plan(
        event: event,
        certificateType: _certificateType,
        recipientType: _recipientType,
        selectedEntries: _selectedEntries,
        membersByTeam: _membersByTeam,
      );

  Future<void> _ensureMembersLoaded() async {
    if (_recipientType != CertificateRecipientType.individual) return;
    if (_membersByTeam.isNotEmpty) return;
    setState(() => _loadingMembers = true);
    try {
      final Map<String, List<CertificateMember>> loaded =
          await CertificateTeamMemberLoader.membersByTeamId(_selectedEntries.map((CertificateSelectableEntry e) => e.teamId));
      if (!mounted) return;
      setState(() => _membersByTeam = loaded);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void _onCertificateTypeChanged(CertificateType next) {
    if (next == _certificateType) return;
    setState(() {
      _certificateType = next;
      _selectedEntryIds = _defaultSelectionIds(next);
    });
    _ensureMembersLoaded();
  }

  void _onRecipientTypeChanged(CertificateRecipientType next) {
    if (next == _recipientType) return;
    setState(() => _recipientType = next);
    _ensureMembersLoaded();
  }

  Future<void> _preview() async {
    if (!_canGenerate) return;
    try {
      if (!ExportTenantGuard.actorMatchesBoundOrganisation(widget.actor)) {
        throw StateError('Organisation context required.');
      }
      await _ensureMembersLoaded();
      final List<CertificateData> rows = await CertificateGenerationService.buildCertificateData(
        event: event,
        plan: _plan,
        membersByTeam: _membersByTeam,
      );
      if (rows.isEmpty || !mounted) return;
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(<CertificateData>[rows.first]);
      final HackzFileDownloadResult saved = await HackzFileDownload.save(
        fileName: 'Hackz_Certificate_Preview.pdf',
        bytes: bytes,
        mimeType: HackzFileDownload.pdfMimeType,
      );
      if (!mounted || saved == HackzFileDownloadResult.cancelled) return;
      await FeedbackService.showSuccess(context, title: 'Preview ready', message: 'Sample certificate downloaded.');
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Preview failed', message: '$e');
    }
  }

  Future<void> _generate() async {
    if (!_canGenerate || _generating) return;
    if (!ExportTenantGuard.actorMatchesBoundOrganisation(widget.actor)) {
      await FeedbackService.showError(context, title: 'Unable to generate', message: 'Organisation context required.');
      return;
    }
    final CertificateGenerationPlan plan = _plan;
    if (plan.isLargeJob) {
      final bool ok = await FeedbackService.showConfirmation(
        context,
        title: 'Generate ${plan.estimatedCertificates} certificates?',
        message:
            'This event needs a large batch. Certificates will be processed in controlled groups and downloaded as a ZIP archive.',
        confirmLabel: 'Generate',
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _generating = true;
      _progress = CertificateGenerationProgress(phase: 'Preparing', completed: 0, total: plan.estimatedCertificates);
    });
    try {
      await _ensureMembersLoaded();
      final List<CertificateData> rows = await CertificateGenerationService.buildCertificateData(
        event: event,
        plan: plan,
        membersByTeam: _membersByTeam,
      );
      final CertificateGenerationResult result = await CertificateBatchGenerator.generate(
        certificates: rows,
        plan: plan,
        eventName: event.eventName,
        onProgress: (CertificateGenerationProgress p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      final HackzFileDownloadResult saved = await HackzFileDownload.save(
        fileName: result.fileName,
        bytes: result.bytes,
        mimeType: result.mimeType,
      );
      if (!mounted || saved == HackzFileDownloadResult.cancelled) return;
      final String summary = result.failed == 0
          ? '${result.succeeded} certificate${result.succeeded == 1 ? '' : 's'} saved.'
          : '${result.succeeded} succeeded, ${result.failed} failed.';
      await FeedbackService.showSuccess(context, title: 'Generation complete', message: summary);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Generation failed', message: '$e');
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _progress = null;
        });
      }
    }
  }

  bool get _canGenerate => _plan.estimatedCertificates > 0 && !_generating;

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final CertificateGenerationPlan plan = _plan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Generate Certificates',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          'On-demand Sample A certificates for this ${event.eventTemplateLabel}.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Certificate type'),
        const SizedBox(height: 8),
        _typeChips(),
        const SizedBox(height: 14),
        _sectionLabel('Generate for'),
        const SizedBox(height: 8),
        _recipientChips(),
        const SizedBox(height: 14),
        _sectionLabel('Event'),
        const SizedBox(height: 6),
        _readOnlyField(event.eventName.trim().isEmpty ? event.eventId : event.eventName),
        const SizedBox(height: 14),
        _sectionLabel('Recipients'),
        const SizedBox(height: 8),
        _recipientPanel(compact),
        const SizedBox(height: 12),
        _summaryCard(plan),
        if (_generating && _progress != null) ...<Widget>[
          const SizedBox(height: 12),
          _progressBar(_progress!),
        ],
        if (_loadingMembers) ...<Widget>[
          const SizedBox(height: 10),
          const Center(child: HkzProgressIndicator(size: 24)),
        ],
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            TextButton(
              onPressed: _generating ? null : () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: _canGenerate && !_loadingMembers ? _preview : null,
              icon: const Icon(AppIcons.attachmentPdf, size: 18),
              label: const Text('Preview'),
            ),
            FilledButton.icon(
              onPressed: _canGenerate && !_loadingMembers ? _generate : null,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: HkzProgressIndicator(size: 18, strokeWidth: 2.2))
                  : const Icon(AppIcons.download, size: 18),
              label: Text(_generating ? 'Generating…' : 'Generate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
    );
  }

  Widget _readOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _choiceChip(
          label: 'Participation',
          selected: _certificateType == CertificateType.participation,
          enabled: event.participationEntries.isNotEmpty,
          onTap: () => _onCertificateTypeChanged(CertificateType.participation),
        ),
        _choiceChip(
          label: 'Winner — First Place',
          selected: _certificateType == CertificateType.winner,
          enabled: event.usesWinners && event.winnerEntry != null,
          onTap: () => _onCertificateTypeChanged(CertificateType.winner),
        ),
        _choiceChip(
          label: 'Runner-Up — Second Place',
          selected: _certificateType == CertificateType.runnerUp,
          enabled: event.usesWinners && event.runnerUpEntry != null,
          onTap: () => _onCertificateTypeChanged(CertificateType.runnerUp),
        ),
      ],
    );
  }

  Widget _recipientChips() {
    return Wrap(
      spacing: 8,
      children: <Widget>[
        _choiceChip(
          label: 'Team certificate',
          selected: _recipientType == CertificateRecipientType.team,
          enabled: true,
          onTap: () => _onRecipientTypeChanged(CertificateRecipientType.team),
        ),
        _choiceChip(
          label: 'Individual certificates',
          selected: _recipientType == CertificateRecipientType.individual,
          enabled: true,
          onTap: () => _onRecipientTypeChanged(CertificateRecipientType.individual),
        ),
      ],
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled && !_generating ? (_) => onTap() : null,
      showCheckmark: true,
      selectedColor: const Color(0xFFEDE9FE),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _recipientPanel(bool compact) {
    if (_pool.isEmpty) {
      return Text(
        _unavailableMessage(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
      );
    }
    if (_certificateType != CertificateType.participation) {
      final CertificateSelectableEntry entry = _pool.first;
      return _readOnlyField('${entry.displayLabel} · ${entry.submissionTitle}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '${_selectedEntryIds.length} of ${_pool.length} selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const Spacer(),
            TextButton(
              onPressed: _generating
                  ? null
                  : () => setState(() => _selectedEntryIds = _pool.map((CertificateSelectableEntry e) => e.entryId).toSet()),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: _generating ? null : () => setState(() => _selectedEntryIds = <String>{}),
              child: const Text('Clear'),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: compact ? 160 : 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _pool.length,
            itemBuilder: (BuildContext context, int index) {
              final CertificateSelectableEntry entry = _pool[index];
              final bool checked = _selectedEntryIds.contains(entry.entryId);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: checked,
                onChanged: _generating
                    ? null
                    : (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedEntryIds.add(entry.entryId);
                          } else {
                            _selectedEntryIds.remove(entry.entryId);
                          }
                        });
                        _ensureMembersLoaded();
                      },
                title: Text(entry.displayLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                subtitle: entry.submissionTitle.trim().isEmpty
                    ? null
                    : Text(entry.submissionTitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              );
            },
          ),
        ),
      ],
    );
  }

  String _unavailableMessage() {
    return switch (_certificateType) {
      CertificateType.participation => 'Add participating ${event.eventKind.entriesLabel.toLowerCase()} first.',
      CertificateType.winner => 'Winner is available after Department Admin selects a winner.',
      CertificateType.runnerUp => 'Runner-up is available after Department Admin selects a runner-up.',
    };
  }

  Widget _summaryCard(CertificateGenerationPlan plan) {
    final String modeLabel = switch (plan.outputMode) {
      CertificateOutputMode.singlePdf => 'Single PDF',
      CertificateOutputMode.multiPagePdf => 'Combined PDF',
      CertificateOutputMode.zipArchive => 'ZIP archive (batched)',
    };
    final String typeLabel = switch (plan.certificateType) {
      CertificateType.participation => 'Participation',
      CertificateType.winner => 'Winner — First Place',
      CertificateType.runnerUp => 'Runner-Up — Second Place',
    };
    final String forLabel =
        plan.recipientType == CertificateRecipientType.team ? 'Team' : 'Individual';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _summaryRow('Certificate type', typeLabel),
          _summaryRow('Generate for', forLabel),
          _summaryRow('Selected entries', '${plan.selectedTeamCount}'),
          _summaryRow('Estimated certificates', '${plan.estimatedCertificates}'),
          _summaryRow('Output', modeLabel),
          _summaryRow('Submission label', event.submissionLabel),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(CertificateGenerationProgress progress) {
    final double value = progress.total == 0 ? 0 : progress.completed / progress.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${progress.phase}: ${progress.completed} of ${progress.total}'
          '${progress.failed > 0 ? ' (${progress.failed} failed)' : ''}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 5),
      ],
    );
  }
}
