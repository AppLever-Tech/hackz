import 'package:flutter/material.dart';

import '../../../core/download/hackz_file_download.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../exports/certificate/certificate_batch_generator.dart';
import '../../exports/certificate/certificate_data.dart';
import '../../exports/certificate/certificate_event_context.dart';
import '../../exports/certificate/certificate_event_signatory_config.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import '../../exports/certificate/certificate_generation_plan.dart';
import '../../exports/certificate/certificate_generation_service.dart';
import '../../exports/certificate/certificate_recipient_groups.dart';
import '../../exports/certificate/certificate_selectable_entry.dart';
import '../../exports/certificate/certificate_team_member_loader.dart';
import '../../exports/certificate/certificate_type.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../user/models/user_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'certificate_generation_dialog_recipients.dart';

Future<void> showCertificateGenerationDialog({
  required BuildContext context,
  required CertificateEventContext event,
  required UserModel actor,
  required CertificateType certificateType,
  CertificateEventSignatoryDraft? signatoryDraft,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _CertificateGenerationDialogShell(
        event: event,
        actor: actor,
        certificateType: certificateType,
        signatoryDraft: signatoryDraft,
      );
    },
  );
}

class _CertificateGenerationDialogShell extends StatefulWidget {
  const _CertificateGenerationDialogShell({
    required this.event,
    required this.actor,
    required this.certificateType,
    this.signatoryDraft,
  });

  final CertificateEventContext event;
  final UserModel actor;
  final CertificateType certificateType;
  final CertificateEventSignatoryDraft? signatoryDraft;

  @override
  State<_CertificateGenerationDialogShell> createState() => _CertificateGenerationDialogShellState();
}

class _CertificateGenerationDialogShellState extends State<_CertificateGenerationDialogShell> {
  late CertificateRecipientType _recipientType;
  late Set<String> _selectedTeamKeys;
  late Set<String> _selectedIndividualKeys;
  late Set<String> _expandedTeamKeys;
  String _searchQuery = '';
  Map<String, List<CertificateMember>> _membersByTeam = <String, List<CertificateMember>>{};
  bool _loadingMembers = false;
  bool _generating = false;
  CertificateGenerationProgress? _progress;
  String? _successMessage;
  String? _errorMessage;

  CertificateEventContext get event => widget.event;
  CertificateType get certificateType => widget.certificateType;
  CertificateEventSignatoryDraft? get _signatoryDraft => widget.signatoryDraft;

  bool get _signatoriesReady => CertificateEventSignatoryConfig.meetsMinimum(_signatoryDraft);

  List<CertificateSelectableEntry> get _pool => switch (certificateType) {
        CertificateType.participation => event.participationEntries,
        CertificateType.winner =>
          event.winnerEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.winnerEntry!],
        CertificateType.runnerUp =>
          event.runnerUpEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.runnerUpEntry!],
      };

  List<CertificateTeamSubmissionGroup> get _groups => CertificateRecipientGroups.groupByTeam(_pool);

  @override
  void initState() {
    super.initState();
    _recipientType = CertificateRecipientType.team;
    _selectedTeamKeys = _pool.map((CertificateSelectableEntry e) => certificateTeamSubmissionKey(e)).toSet();
    _selectedIndividualKeys = <String>{};
    _expandedTeamKeys = <String>{
      for (final CertificateTeamSubmissionGroup g in _groups)
        if (g.submissions.length > 1) g.teamKey,
    };
    _ensureMembersLoaded();
  }

  Future<void> _ensureMembersLoaded() async {
    if (_membersByTeam.isNotEmpty) return;
    final Iterable<String> teamIds =
        _pool.map((CertificateSelectableEntry e) => e.teamId.trim()).where((String id) => id.isNotEmpty);
    if (teamIds.isEmpty) return;
    setState(() => _loadingMembers = true);
    try {
      final Map<String, List<CertificateMember>> loaded = await CertificateTeamMemberLoader.membersByTeamId(teamIds);
      if (!mounted) return;
      setState(() {
        _membersByTeam = loaded;
        if (_selectedIndividualKeys.isEmpty && _pool.isNotEmpty) {
          _selectedIndividualKeys = _allIndividualKeys();
        }
      });
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Set<String> _allIndividualKeys() {
    final Set<String> keys = <String>{};
    for (final CertificateTeamSubmissionGroup group in _groups) {
      for (final CertificateSelectableEntry entry in group.submissions) {
        keys.addAll(_individualKeysForEntry(entry));
      }
    }
    return keys;
  }

  Iterable<String> _individualKeysForEntry(CertificateSelectableEntry entry) sync* {
    final List<CertificateMember> roster = _membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
    if (roster.isEmpty) {
      yield certificateIndividualSubmissionKey(
        userId: entry.teamId.trim().isNotEmpty ? entry.teamId : entry.entryId,
        entry: entry,
      );
    } else {
      for (final CertificateMember member in roster) {
        yield certificateIndividualSubmissionKey(userId: member.userId, entry: entry);
      }
    }
  }

  List<CertificateSelectableEntry> get _selectedEntries {
    if (_recipientType == CertificateRecipientType.team) {
      return _pool
          .where((CertificateSelectableEntry e) => _selectedTeamKeys.contains(certificateTeamSubmissionKey(e)))
          .toList();
    }
    final Set<String> entryIds = <String>{};
    for (final String key in _selectedIndividualKeys) {
      final int sep = key.indexOf('|');
      if (sep > 0) entryIds.add(key.substring(sep + 1).trim());
    }
    return _pool.where((CertificateSelectableEntry e) => entryIds.contains(e.entryId.trim())).toList(growable: false);
  }

  CertificateGenerationPlan get _plan => CertificateGenerationService.plan(
        event: event,
        certificateType: certificateType,
        recipientType: _recipientType,
        selectedEntries: _selectedEntries,
        membersByTeam: _membersByTeam,
        selectedIndividualKeys: _recipientType == CertificateRecipientType.individual ? _selectedIndividualKeys : const <String>{},
      );

  List<CertificateSignatory> get _resolvedSignatories =>
      CertificateEventSignatoryConfig.toPdfSignatories(_signatoryDraft);

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
      _successMessage = null;
      _errorMessage = null;
      _progress = CertificateGenerationProgress(phase: 'Preparing', completed: 0, total: plan.estimatedCertificates);
    });
    try {
      await _ensureMembersLoaded();
      final List<CertificateData> rows = await CertificateGenerationService.buildCertificateData(
        event: event,
        plan: plan,
        membersByTeam: _membersByTeam,
        selectedIndividualKeys: _recipientType == CertificateRecipientType.individual ? _selectedIndividualKeys : const <String>{},
        signatories: _resolvedSignatories,
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
        useSaveFilePicker: false,
      );
      if (!mounted) return;
      if (saved == HackzFileDownloadResult.cancelled) {
        setState(() {
          _generating = false;
          _progress = null;
        });
        return;
      }
      final String summary = result.failed == 0
          ? '${result.succeeded} certificate${result.succeeded == 1 ? '' : 's'} saved successfully.'
          : '${result.succeeded} succeeded, ${result.failed} failed.';
      setState(() {
        _generating = false;
        _progress = null;
        _successMessage = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _progress = null;
        _errorMessage = '$e';
      });
    }
  }

  bool get _canGenerate =>
      _signatoriesReady &&
      _plan.estimatedCertificates > 0 &&
      !_generating &&
      !_loadingMembers &&
      _successMessage == null;

  String get _title => switch (certificateType) {
        CertificateType.participation => 'Generate Participation Certificates',
        CertificateType.winner => 'Generate Winner Certificates',
        CertificateType.runnerUp => 'Generate Runner-Up Certificates',
      };

  String get _generateLabel {
    final int n = _plan.estimatedCertificates;
    if (n <= 0) return 'Generate certificates';
    if (n == 1) return 'Generate certificate';
    return 'Generate $n certificates';
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.wide,
      showBorder: true,
      footer: _stickyFooter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose recipients for this ${event.eventTemplateLabel}.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 16),
          if (_generating) ...<Widget>[
            _generationStatusPanel(),
          ] else if (_successMessage != null) ...<Widget>[
            _successPanel(_successMessage!),
          ] else ...<Widget>[
            _generateForRow(context),
            const SizedBox(height: 14),
            if (_errorMessage != null) ...<Widget>[
              _errorPanel(_errorMessage!),
              const SizedBox(height: 12),
            ],
            CertificateGenerationRecipientsSection(
              certificateType: certificateType,
            recipientType: _recipientType,
            pool: _pool,
            searchQuery: _searchQuery,
            onSearchChanged: (String q) => setState(() => _searchQuery = q),
            selectedTeamSubmissionKeys: _selectedTeamKeys,
            selectedIndividualKeys: _selectedIndividualKeys,
            onTeamSubmissionToggle: (String key, bool selected) {
              setState(() {
                if (selected) {
                  _selectedTeamKeys.add(key);
                } else {
                  _selectedTeamKeys.remove(key);
                }
              });
            },
            onTeamGroupToggle: (CertificateTeamSubmissionGroup group, bool selected) {
              setState(() {
                for (final CertificateSelectableEntry e in group.submissions) {
                  final String key = certificateTeamSubmissionKey(e);
                  if (selected) {
                    _selectedTeamKeys.add(key);
                  } else {
                    _selectedTeamKeys.remove(key);
                  }
                }
              });
            },
            onIndividualGroupToggle: (CertificateTeamSubmissionGroup group, bool selected) {
              setState(() {
                for (final CertificateSelectableEntry entry in group.submissions) {
                  for (final String key in _individualKeysForEntry(entry)) {
                    if (selected) {
                      _selectedIndividualKeys.add(key);
                    } else {
                      _selectedIndividualKeys.remove(key);
                    }
                  }
                }
              });
            },
            onIndividualToggle: (String key, bool selected) {
              setState(() {
                if (selected) {
                  _selectedIndividualKeys.add(key);
                } else {
                  _selectedIndividualKeys.remove(key);
                }
              });
            },
            onSelectAllVisible: _selectAllVisible,
            onClear: () => setState(() {
              _selectedTeamKeys = <String>{};
              _selectedIndividualKeys = <String>{};
            }),
            membersByTeam: _membersByTeam,
            expandedTeamKeys: _expandedTeamKeys,
            onExpandedChanged: (String teamKey, bool expanded) {
              setState(() {
                if (expanded) {
                  _expandedTeamKeys.add(teamKey);
                } else {
                  _expandedTeamKeys.remove(teamKey);
                }
              });
            },
              enabled: _errorMessage == null,
            ),
            if (_loadingMembers) ...<Widget>[
              const SizedBox(height: 10),
              const Center(child: HkzProgressIndicator(size: 24)),
            ],
          ],
        ],
      ),
    );
  }

  void _selectAllVisible() {
    setState(() {
      if (_recipientType == CertificateRecipientType.team) {
        for (final CertificateTeamSubmissionGroup group in _filteredGroups()) {
          for (final CertificateSelectableEntry e in group.submissions) {
            _selectedTeamKeys.add(certificateTeamSubmissionKey(e));
          }
        }
      } else {
        for (final CertificateTeamSubmissionGroup group in _filteredGroups()) {
          for (final CertificateSelectableEntry entry in group.submissions) {
            final List<CertificateMember> roster = _membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
            if (roster.isEmpty) {
              if (CertificateRecipientGroups.matchesIndividualSearch(
                group: group,
                memberName: entry.displayLabel,
                query: _searchQuery,
              )) {
                _selectedIndividualKeys.add(
                  certificateIndividualSubmissionKey(
                    userId: entry.teamId.trim().isNotEmpty ? entry.teamId : entry.entryId,
                    entry: entry,
                  ),
                );
              }
            } else {
              for (final CertificateMember member in roster) {
                if (CertificateRecipientGroups.matchesIndividualSearch(
                  group: group,
                  memberName: member.displayName,
                  query: _searchQuery,
                )) {
                  _selectedIndividualKeys.add(
                    certificateIndividualSubmissionKey(userId: member.userId, entry: entry),
                  );
                }
              }
            }
          }
        }
      }
    });
  }

  List<CertificateTeamSubmissionGroup> _filteredGroups() {
    return _groups
        .where((CertificateTeamSubmissionGroup g) => CertificateRecipientGroups.matchesTeamSearch(g, _searchQuery))
        .toList(growable: false);
  }

  Widget _generateForRow(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _sectionLabel('Generate for'),
        _recipientSegment(),
      ],
    );
  }

  Widget _recipientSegment() {
    return SegmentedButton<CertificateRecipientType>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<CertificateRecipientType>>[
        ButtonSegment<CertificateRecipientType>(
          value: CertificateRecipientType.team,
          label: Text('Team'),
        ),
        ButtonSegment<CertificateRecipientType>(
          value: CertificateRecipientType.individual,
          label: Text('Individual'),
        ),
      ],
      selected: <CertificateRecipientType>{_recipientType},
      onSelectionChanged: (Set<CertificateRecipientType> next) {
              if (_generating) return;
              if (next.isEmpty) return;
              setState(() => _recipientType = next.first);
              _ensureMembersLoaded();
            },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _stickyFooter() {
    final int count = _plan.estimatedCertificates;
    final int sigCount = CertificateEventSignatoryConfig.normalizedCount(_signatoryDraft);
    final String summary = count == 0
        ? 'No certificates selected'
        : '$count certificate${count == 1 ? '' : 's'} · $sigCount signatories';

    final double horizontal = ResponsiveHelper.isMobile(context) ? 16 : 22;

    final bool mobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        12,
        horizontal,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3FF),
        border: Border(top: BorderSide(color: Color(0xFFD9CBFF))),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  summary,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                _footerButtons(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    summary,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 12),
                _footerButtons(),
              ],
            ),
    );
  }

  Widget _footerButtons() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        TextButton(
          onPressed: _generating ? null : () => Navigator.of(context).pop(),
          child: Text(_successMessage != null ? 'Close' : 'Cancel'),
        ),
        if (_successMessage == null)
          FilledButton.icon(
            onPressed: _canGenerate ? _generate : null,
            icon: const Icon(AppIcons.download, size: 18),
            label: Text(_generateLabel),
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

  Widget _generationStatusPanel() {
    final CertificateGenerationProgress? progress = _progress;
    final String detail = progress == null
        ? 'Generating certificates…'
        : '${progress.phase}: ${progress.completed} of ${progress.total}'
            '${progress.failed > 0 ? ' (${progress.failed} failed)' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HkzProgressIndicator(size: 36),
          const SizedBox(height: 14),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _successPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Generation complete',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFBE123C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFBE123C)),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
