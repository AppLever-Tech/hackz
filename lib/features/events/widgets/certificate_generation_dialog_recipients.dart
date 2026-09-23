import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../exports/certificate/certificate_recipient_groups.dart';
import '../../exports/certificate/certificate_selectable_entry.dart';
import '../../exports/certificate/certificate_type.dart';

/// Team / individual recipient picker for [CertificateGenerationDialog].
class CertificateGenerationRecipientsSection extends StatelessWidget {
  const CertificateGenerationRecipientsSection({
    super.key,
    required this.certificateType,
    required this.recipientType,
    required this.pool,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedTeamSubmissionKeys,
    required this.selectedIndividualKeys,
    required this.onTeamSubmissionToggle,
    required this.onTeamGroupToggle,
    required this.onIndividualGroupToggle,
    required this.onIndividualToggle,
    required this.onSelectAllVisible,
    required this.onClear,
    required this.membersByTeam,
    required this.expandedTeamKeys,
    required this.onExpandedChanged,
    required this.enabled,
  });

  final CertificateType certificateType;
  final CertificateRecipientType recipientType;
  final List<CertificateSelectableEntry> pool;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Set<String> selectedTeamSubmissionKeys;
  final Set<String> selectedIndividualKeys;
  final void Function(String entryId, bool selected) onTeamSubmissionToggle;
  final void Function(CertificateTeamSubmissionGroup group, bool selected) onTeamGroupToggle;
  final void Function(CertificateTeamSubmissionGroup group, bool selected) onIndividualGroupToggle;
  final void Function(String individualKey, bool selected) onIndividualToggle;
  final VoidCallback onSelectAllVisible;
  final VoidCallback onClear;
  final Map<String, List<CertificateMember>> membersByTeam;
  final Set<String> expandedTeamKeys;
  final void Function(String teamKey, bool expanded) onExpandedChanged;
  final bool enabled;

  List<CertificateTeamSubmissionGroup> get _groups =>
      CertificateRecipientGroups.groupByTeam(pool);

  List<CertificateTeamSubmissionGroup> get _filteredGroups {
    return _groups
        .where((CertificateTeamSubmissionGroup g) =>
            CertificateRecipientGroups.matchesTeamSearch(g, searchQuery))
        .toList(growable: false);
  }

  int get _selectedCount => recipientType == CertificateRecipientType.team
      ? selectedTeamSubmissionKeys.length
      : selectedIndividualKeys.length;

  int get _visibleSelectableCount {
    if (recipientType == CertificateRecipientType.team) {
      int n = 0;
      for (final CertificateTeamSubmissionGroup g in _filteredGroups) {
        n += g.submissions.length;
      }
      return n;
    }
    int n = 0;
    for (final CertificateTeamSubmissionGroup g in _filteredGroups) {
      for (final CertificateSelectableEntry entry in g.submissions) {
        final List<CertificateMember> roster = membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
        if (roster.isEmpty) {
          if (CertificateRecipientGroups.matchesIndividualSearch(
            group: g,
            memberName: entry.displayLabel,
            query: searchQuery,
          )) {
            n++;
          }
        } else {
          for (final CertificateMember member in roster) {
            if (CertificateRecipientGroups.matchesIndividualSearch(
              group: g,
              memberName: member.displayName,
              query: searchQuery,
            )) {
              n++;
            }
          }
        }
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (pool.isEmpty) {
      return Text(
        _emptyMessage(certificateType),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
      );
    }

    final String searchHint = recipientType == CertificateRecipientType.team
        ? 'Search by team or submission name'
        : 'Search by individual, team or submission name';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          enabled: enabled,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: searchHint,
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Text(
              '$_selectedCount selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const Spacer(),
            TextButton(onPressed: enabled ? onSelectAllVisible : null, child: const Text('Select all')),
            TextButton(onPressed: enabled ? onClear : null, child: const Text('Clear')),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: ResponsiveHelper.isMobile(context) ? 240 : 280),
          child: ListView(
            shrinkWrap: true,
            children: recipientType == CertificateRecipientType.team
                ? _teamRows(context)
                : _individualRows(context),
          ),
        ),
        if (_visibleSelectableCount == 0 && searchQuery.trim().isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No matches for your search.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  List<Widget> _teamRows(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (final CertificateTeamSubmissionGroup group in _filteredGroups) {
      if (group.submissions.length == 1) {
        final CertificateSelectableEntry entry = group.submissions.first;
        rows.add(_teamSubmissionRow(context, group: group, entry: entry, indent: false));
      } else {
        rows.add(_teamGroupHeader(context, group));
        if (expandedTeamKeys.contains(group.teamKey)) {
          for (final CertificateSelectableEntry entry in group.submissions) {
            rows.add(_teamSubmissionRow(context, group: group, entry: entry, indent: true));
          }
        }
      }
    }
    return rows;
  }

  List<Widget> _individualRows(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (final CertificateTeamSubmissionGroup group in _filteredGroups) {
      final bool multiSubmission = group.submissions.length > 1;
      if (multiSubmission) {
        rows.add(_teamGroupHeader(context, group, individualMode: true));
        if (!expandedTeamKeys.contains(group.teamKey)) continue;
      }
      for (final CertificateSelectableEntry entry in group.submissions) {
        final List<CertificateMember> roster = membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
        if (roster.isEmpty) {
          if (!CertificateRecipientGroups.matchesIndividualSearch(
            group: group,
            memberName: entry.displayLabel,
            query: searchQuery,
          )) {
            continue;
          }
          rows.add(
            _individualRow(
              context,
              label: entry.displayLabel,
              submissionTitle: entry.submissionTitle,
              key: certificateIndividualSubmissionKey(
                userId: entry.teamId.trim().isNotEmpty ? entry.teamId : entry.entryId,
                entry: entry,
              ),
              indent: multiSubmission,
            ),
          );
          continue;
        }
        for (final CertificateMember member in roster) {
          if (!CertificateRecipientGroups.matchesIndividualSearch(
            group: group,
            memberName: member.displayName,
            query: searchQuery,
          )) {
            continue;
          }
          rows.add(
            _individualRow(
              context,
              label: member.displayName,
              submissionTitle: entry.submissionTitle,
              key: certificateIndividualSubmissionKey(userId: member.userId, entry: entry),
              indent: multiSubmission || group.submissions.length > 1,
            ),
          );
        }
      }
    }
    return rows;
  }

  Widget _teamGroupHeader(BuildContext context, CertificateTeamSubmissionGroup group, {bool individualMode = false}) {
    final int selectedInGroup = individualMode ? _selectedIndividualInGroup(group) : _selectedSubmissionsInGroup(group);
    final int total = individualMode ? _individualCountInGroup(group) : group.submissions.length;
    final bool expanded = expandedTeamKeys.contains(group.teamKey);
    final bool? triState = selectedInGroup == 0
        ? false
        : (selectedInGroup >= total ? true : null);

    return InkWell(
      onTap: enabled ? () => onExpandedChanged(group.teamKey, !expanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Checkbox(
              tristate: true,
              value: triState,
              onChanged: enabled
                  ? (bool? value) {
                      final bool select = value == true;
                      if (individualMode) {
                        onIndividualGroupToggle(group, select);
                      } else {
                        onTeamGroupToggle(group, select);
                      }
                    }
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Icon(expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, size: 20),
            Expanded(
              child: _truncatedLabel(context, group.teamName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            Text(
              '$selectedInGroup / $total',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedSubmissionsInGroup(CertificateTeamSubmissionGroup group) {
    int n = 0;
    for (final CertificateSelectableEntry e in group.submissions) {
      if (selectedTeamSubmissionKeys.contains(certificateTeamSubmissionKey(e))) n++;
    }
    return n;
  }

  int _individualCountInGroup(CertificateTeamSubmissionGroup group) {
    int n = 0;
    for (final CertificateSelectableEntry entry in group.submissions) {
      final List<CertificateMember> roster = membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
      n += roster.isEmpty ? 1 : roster.length;
    }
    return n;
  }

  int _selectedIndividualInGroup(CertificateTeamSubmissionGroup group) {
    int n = 0;
    for (final CertificateSelectableEntry entry in group.submissions) {
      final List<CertificateMember> roster = membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
      if (roster.isEmpty) {
        final String key = certificateIndividualSubmissionKey(userId: entry.entryId, entry: entry);
        if (selectedIndividualKeys.contains(key)) n++;
      } else {
        for (final CertificateMember member in roster) {
          final String key = certificateIndividualSubmissionKey(userId: member.userId, entry: entry);
          if (selectedIndividualKeys.contains(key)) n++;
        }
      }
    }
    return n;
  }

  Widget _teamSubmissionRow(
    BuildContext context, {
    required CertificateTeamSubmissionGroup group,
    required CertificateSelectableEntry entry,
    required bool indent,
  }) {
    final String key = certificateTeamSubmissionKey(entry);
    final bool checked = selectedTeamSubmissionKeys.contains(key);
    final bool singleSubmissionTeam = group.submissions.length == 1;
    final String line = singleSubmissionTeam
        ? '${group.teamName} · ${entry.submissionTitle}'
        : entry.submissionTitle;

    return Padding(
      padding: EdgeInsets.only(left: indent ? 28 : 0),
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: enabled ? (bool? v) => onTeamSubmissionToggle(key, v == true) : null,
        title: _truncatedLabel(
          context,
          line,
          style: TextStyle(
            fontSize: 12,
            fontWeight: singleSubmissionTeam ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _individualRow(
    BuildContext context, {
    required String label,
    required String submissionTitle,
    required String key,
    required bool indent,
  }) {
    final String title = submissionTitle.trim();
    final String line = title.isEmpty ? label : '$label · $title';
    return Padding(
      padding: EdgeInsets.only(left: indent ? 28 : 0),
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: selectedIndividualKeys.contains(key),
        onChanged: enabled ? (bool? v) => onIndividualToggle(key, v == true) : null,
        title: _truncatedLabel(
          context,
          line,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _truncatedLabel(BuildContext context, String text, {required TextStyle style}) {
    final Widget label = Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (ResponsiveHelper.isMobile(context)) return label;
    return Tooltip(message: text, child: label);
  }

  static String _emptyMessage(CertificateType type) {
    return switch (type) {
      CertificateType.participation => 'Add participating submissions first.',
      CertificateType.winner => 'Winner is available after Department Admin selects a winner.',
      CertificateType.runnerUp => 'Runner-up is available after Department Admin selects a runner-up.',
    };
  }
}
