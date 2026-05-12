import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/team_status.dart';
import '../../models/problem_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/faculty_teams_service.dart';
import '../../utils/team_service.dart';

class SubmitIdeaDialog extends StatefulWidget {
  const SubmitIdeaDialog({
    super.key,
    required this.currentUser,
    this.team,
    this.problems,
  });

  final UserModel currentUser;
  final TeamModel? team;
  final List<ProblemModel>? problems;

  @override
  State<SubmitIdeaDialog> createState() => _SubmitIdeaDialogState();
}

class _SubmitIdeaDialogState extends State<SubmitIdeaDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _filesController = TextEditingController();
  List<TeamModel> _teams = <TeamModel>[];
  TeamModel? _selectedTeam;
  List<ProblemModel> _problems = <ProblemModel>[];
  ProblemModel? _selectedProblem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.team;
    _problems = widget.problems ?? <ProblemModel>[];
    if (_problems.isNotEmpty) _selectedProblem = _problems.first;
    _loadLookupsIfNeeded();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _filesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final team = _selectedTeam;
    final problem = _selectedProblem;
    if (team == null || problem == null || _descriptionController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final files = _filesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
      await FacultyTeamsService.submitIdea(
        faculty: widget.currentUser,
        team: team,
        problem: problem,
        description: _descriptionController.text,
        files: files,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadLookupsIfNeeded() async {
    if (widget.team != null && widget.problems != null) return;
    final data = await FacultyTeamsService.load(widget.currentUser);
    if (!mounted) return;
    setState(() {
      _teams = data.teams.where((team) => team.status != TeamStatus.inactive).toList(growable: false);
      if (_selectedTeam == null && _teams.isNotEmpty) _selectedTeam = _teams.first;
      if (_problems.isEmpty) {
        _problems = data.problems;
        if (_problems.isNotEmpty) _selectedProblem = _problems.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.ideas, color: Color(0xFF6A38FF), size: 24),
              const SizedBox(width: 10),
              const Expanded(child: Text('Submit Idea', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
              if (_selectedTeam != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(999)),
                  child: Text(_selectedTeam!.teamName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF6A38FF))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.team == null) ...<Widget>[
            DropdownButtonFormField<String>(
              value: _selectedTeam?.teamId,
              isExpanded: true,
              items: _teams
                  .map(
                    (team) => DropdownMenuItem<String>(
                      value: team.teamId,
                      child: Text(team.teamName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedTeam = _teams.firstWhere((team) => team.teamId == value));
              },
              decoration: const InputDecoration(labelText: 'Team', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            value: _selectedProblem?.problemId,
            isExpanded: true,
            items: _problems
                .map(
                  (problem) => DropdownMenuItem<String>(
                    value: problem.problemId,
                    child: Text('${problem.problemNumber} • ${problem.title}', overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedProblem = _problems.firstWhere((problem) => problem.problemId == value));
            },
            decoration: const InputDecoration(labelText: 'Problem', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Idea details', border: OutlineInputBorder(), hintText: 'Describe your solution approach, impact and implementation outline.'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _filesController,
            decoration: const InputDecoration(
              prefixIcon: Icon(AppIcons.attachments),
              labelText: 'Attachments',
              hintText: 'Comma-separated URLs for now',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Payment and attachment workflow hooks are preserved for the idea submission pipeline.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Submitting locks team edits for this idea cycle.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
              OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Submitting...' : 'Submit Idea')),
            ],
          ),
        ],
      ),
    );
  }
}
