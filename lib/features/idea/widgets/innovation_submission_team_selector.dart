import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../team/models/team_model.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';

/// Scalable team picker for [InnovationSubmissionWorkspace].
class InnovationSubmissionTeamSelector extends StatefulWidget {
  const InnovationSubmissionTeamSelector({
    super.key,
    required this.teams,
    required this.selectedTeam,
    required this.onTeamSelected,
    required this.onOpenTeamWorkspace,
    this.enabled = true,
    this.recentTeamId,
  });

  static const int expandableThreshold = 5;
  static const int searchThreshold = 8;
  static const double pickerTileWidth = 168;

  final List<TeamModel> teams;
  final TeamModel? selectedTeam;
  final ValueChanged<TeamModel> onTeamSelected;
  final ValueChanged<TeamModel> onOpenTeamWorkspace;
  final bool enabled;
  final String? recentTeamId;

  @override
  State<InnovationSubmissionTeamSelector> createState() => _InnovationSubmissionTeamSelectorState();
}

class _InnovationSubmissionTeamSelectorState extends State<InnovationSubmissionTeamSelector> {
  final TextEditingController _searchController = TextEditingController();
  bool _expanded = false;

  bool get _useExpandableMode => widget.teams.length > InnovationSubmissionTeamSelector.expandableThreshold;

  bool get _showSearch => widget.teams.length > InnovationSubmissionTeamSelector.searchThreshold;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamModel> get _filteredTeams {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.teams;
    return widget.teams
        .where((TeamModel t) => t.teamName.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _selectTeam(TeamModel team) {
    widget.onTeamSelected(team);
    if (_useExpandableMode) {
      setState(() => _expanded = false);
    }
  }

  int _memberCount(TeamModel team) => team.studentIds.length;

  String _teamDisplayName(TeamModel team) {
    final String name = team.teamName.trim();
    return name.isEmpty ? 'Untitled team' : name;
  }

  Widget _teamNamePill(TeamModel team) {
    return EntityCardPills.workspace(
      _teamDisplayName(team),
      ContextPillSemantic.team,
      () => widget.onOpenTeamWorkspace(team),
      fullWidth: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teams.isEmpty) {
      return const Text(
        'No active teams available. Create or join a team before submitting.',
        style: TextStyle(color: Color(0xFF64748B)),
      );
    }

    if (!_useExpandableMode) {
      return _buildDirectGrid(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSelectedTeamCard(context, widget.selectedTeam),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: widget.enabled
                ? () => setState(() => _expanded = !_expanded)
                : null,
            icon: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.expand_more, size: 20),
            ),
            label: Text(_expanded ? 'Hide teams' : 'Change team'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6A38FF),
              side: const BorderSide(color: Color(0xFFD9CBFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildExpandedSelector(context),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  Widget _buildDirectGrid(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.teams
          .map((TeamModel team) => _teamPickerTile(context, team, fullWidth: mobile))
          .toList(growable: false),
    );
  }

  Widget _buildExpandedSelector(BuildContext context) {
    final List<TeamModel> visible = _filteredTeams;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_showSearch) ...<Widget>[
            TextField(
              controller: _searchController,
              enabled: widget.enabled,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search teams',
                prefixIcon: const Icon(AppIcons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFCFDFF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No teams match your search.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: _buildPickerGrid(context, visible),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickerGrid(BuildContext context, List<TeamModel> teams) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    if (mobile) {
      return Column(
        children: teams
            .map(
              (TeamModel team) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _teamPickerTile(context, team, fullWidth: true),
              ),
            )
            .toList(growable: false),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: teams.map((TeamModel team) => _teamPickerTile(context, team)).toList(growable: false),
    );
  }

  Widget _buildSelectedTeamCard(BuildContext context, TeamModel? team) {
    if (team == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: const Text(
          'Select a team below to continue.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
        ),
      );
    }

    final int members = _memberCount(team);
    final bool isRecent = widget.recentTeamId != null && widget.recentTeamId == team.teamId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6A38FF), width: 1.6),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x286A38FF), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Selected team',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6A38FF), letterSpacing: 0.3),
              ),
              if (isRecent) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Recent',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF5B21B6)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _teamNamePill(team),
          const SizedBox(height: 6),
          Text(
            '$members member${members == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _teamPickerTile(BuildContext context, TeamModel team, {bool fullWidth = false}) {
    final bool selected = widget.selectedTeam?.teamId == team.teamId;
    final int members = _memberCount(team);
    final bool isRecent = widget.recentTeamId != null && widget.recentTeamId == team.teamId;

    final Widget tile = Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.enabled ? () => _selectTeam(team) : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: fullWidth ? double.infinity : InnovationSubmissionTeamSelector.pickerTileWidth,
          padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF6A38FF) : const Color(0xFFD9E2F5),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: _teamNamePill(team)),
                  if (isRecent)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.history, size: 14, color: Color(0xFF7C3AED)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$members member${members == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) return tile;

    return SizedBox(
      width: InnovationSubmissionTeamSelector.pickerTileWidth,
      child: tile,
    );
  }
}
