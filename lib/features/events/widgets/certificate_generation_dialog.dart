import 'package:flutter/material.dart';

import '../../../core/download/hackz_file_download.dart';
import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../exports/certificate/certificate_batch_generator.dart';
import '../../exports/certificate/certificate_data.dart';
import '../../exports/certificate/certificate_event_context.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import '../../exports/certificate/certificate_generation_plan.dart';
import '../../exports/certificate/certificate_generation_service.dart';
import '../../exports/certificate/certificate_recipient_groups.dart';
import '../../exports/certificate/certificate_selectable_entry.dart';
import '../../exports/certificate/certificate_signatory_people_loader.dart';
import '../../exports/certificate/certificate_team_member_loader.dart';
import '../../exports/certificate/certificate_type.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../../user/models/user_model.dart';
import 'certificate_generation_dialog_recipients.dart';
import 'certificate_generation_dialog_signatories.dart';

Future<void> showCertificateGenerationDialog({
  required BuildContext context,
  required CertificateEventContext event,
  required UserModel actor,
  required CertificateType certificateType,
  required IdeathonModel ideathon,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _CertificateGenerationDialogShell(
        event: event,
        actor: actor,
        certificateType: certificateType,
        ideathon: ideathon,
      );
    },
  );
}

class _CertificateGenerationDialogShell extends StatefulWidget {
  const _CertificateGenerationDialogShell({
    required this.event,
    required this.actor,
    required this.certificateType,
    required this.ideathon,
  });

  final CertificateEventContext event;
  final UserModel actor;
  final CertificateType certificateType;
  final IdeathonModel ideathon;

  @override
  State<_CertificateGenerationDialogShell> createState() => _CertificateGenerationDialogShellState();
}

class _CertificateGenerationDialogShellState extends State<_CertificateGenerationDialogShell> {
  late CertificateRecipientType _recipientType;
  late Set<String> _selectedTeamKeys;
  late Set<String> _selectedIndividualKeys;
  late Set<String> _expandedTeamKeys;
  String _searchQuery = '';
  int _signatoryCount = 2;
  List<CertificateSignatorySlotDraft> _slots = _emptySlots();
  Map<String, List<CertificateMember>> _membersByTeam = <String, List<CertificateMember>>{};
  List<UserModel> _eligiblePeople = const <UserModel>[];
  bool _loadingMembers = false;
  bool _loadingSignatories = true;
  bool _generating = false;
  CertificateGenerationProgress? _progress;

  CertificateEventContext get event => widget.event;
  CertificateType get certificateType => widget.certificateType;

  static List<CertificateSignatorySlotDraft> _emptySlots() {
    return List<CertificateSignatorySlotDraft>.generate(
      3,
      (_) => const CertificateSignatorySlotDraft(),
    );
  }

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
    _loadSignatoriesAndPeople();
    _ensureMembersLoaded();
  }

  Future<void> _loadSignatoriesAndPeople() async {
    final CertificateEventSignatoryDraft? saved =
        await CertificateEventSignatoryStore.load(widget.ideathon.ideathonId);
    final List<UserModel> people = await CertificateSignatoryPeopleLoader.load(
      orgId: widget.ideathon.orgId,
      departmentCode: widget.ideathon.departmentId,
      eventCoordinatorIds: widget.ideathon.coordinatorIds,
    );
    if (!mounted) return;
    setState(() {
      _eligiblePeople = people;
      _signatoryCount = saved?.signatoryCount ?? 2;
      if (saved != null && saved.slots.isNotEmpty) {
        _slots = _emptySlots();
        for (int i = 0; i < _slots.length && i < saved.slots.length; i++) {
          _slots[i] = saved.slots[i];
        }
      }
      _loadingSignatories = false;
    });
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

  List<CertificateSignatory> get _resolvedSignatories {
    return List<CertificateSignatory>.generate(_signatoryCount, (int i) {
      final CertificateSignatorySlotDraft slot = _slots[i];
      return CertificateSignatory(
        name: slot.name.trim(),
        designation: slot.designation.trim(),
        signatureImage: CertificateData.memoryImageFromBytes(slot.signatureBytes),
      );
    });
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
      await CertificateEventSignatoryStore.save(
        widget.ideathon.ideathonId,
        CertificateEventSignatoryDraft(signatoryCount: _signatoryCount, slots: _slots),
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

  bool get _canGenerate => _plan.estimatedCertificates > 0 && !_generating && !_loadingMembers;

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
            'Choose recipients and signatories for this ${event.eventTemplateLabel}.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Generate for'),
          const SizedBox(height: 8),
          _recipientSegment(),
          const SizedBox(height: 14),
          _sectionLabel('Recipients'),
          const SizedBox(height: 8),
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
            enabled: !_generating,
          ),
          if (_loadingMembers) ...<Widget>[
            const SizedBox(height: 10),
            const Center(child: HkzProgressIndicator(size: 24)),
          ],
          const SizedBox(height: 16),
          if (_loadingSignatories)
            const Center(child: HkzProgressIndicator(size: 24))
          else
            CertificateGenerationSignatoriesSection(
              signatoryCount: _signatoryCount,
              slots: _slots,
              eligiblePeople: _eligiblePeople,
              allEligiblePeople: _eligiblePeople,
              enabled: !_generating,
              onSignatoryCountChanged: (int count) => setState(() => _signatoryCount = count),
              onSlotChanged: (int index, CertificateSignatorySlotDraft slot) =>
                  setState(() => _slots[index] = slot),
            ),
          if (_generating && _progress != null) ...<Widget>[
            const SizedBox(height: 12),
            _progressBar(_progress!),
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
      onSelectionChanged: _generating
          ? null
          : (Set<CertificateRecipientType> next) {
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
    final String summary = count == 0
        ? 'No certificates selected'
        : '$count certificate${count == 1 ? '' : 's'} · $_signatoryCount signatories';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3FF),
        border: Border(top: BorderSide(color: Color(0xFFD9CBFF))),
      ),
      child: ResponsiveDialogActions(
        leading: Text(
          summary,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        children: <Widget>[
          TextButton(
            onPressed: _generating ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _canGenerate ? _generate : null,
            icon: _generating
                ? const SizedBox(width: 18, height: 18, child: HkzProgressIndicator(size: 18, strokeWidth: 2.2))
                : const Icon(AppIcons.download, size: 18),
            label: Text(_generating ? 'Generating…' : _generateLabel),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
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
