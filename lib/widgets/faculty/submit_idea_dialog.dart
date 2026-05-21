import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/team_status.dart';
import '../../models/problem_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/faculty_teams_service.dart';
import '../../utils/team_service.dart';
import '../attachment_pick_field.dart';
import '../loading/loading.dart';
import '../responsive/responsive_dialog_actions.dart';
import '../responsive/responsive_filter_bar.dart';

class SubmitIdeaDialog extends StatefulWidget {
  const SubmitIdeaDialog({
    super.key,
    required this.currentUser,
    this.team,
    this.initialProblem,
  });

  final UserModel currentUser;
  final TeamModel? team;
  final ProblemModel? initialProblem;

  @override
  State<SubmitIdeaDialog> createState() => _SubmitIdeaDialogState();
}

class _SubmitIdeaDialogState extends State<SubmitIdeaDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<TeamModel> _teams = <TeamModel>[];
  TeamModel? _selectedTeam;
  List<ProblemModel> _problems = <ProblemModel>[];
  ProblemModel? _selectedProblem;
  List<PlatformFile> _attachmentFiles = <PlatformFile>[];
  bool _busy = false;
  bool _loadingLookups = true;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.team;
    _selectedProblem = widget.initialProblem;
    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loadingLookups = true);
    try {
      final List<ProblemModel> orgProblems =
          await TeamService.getActiveProblemsForCollege(widget.currentUser.orgId);
      if (!mounted) return;
      setState(() {
        _problems = orgProblems;
        if (_problems.isEmpty) {
          _selectedProblem = null;
        } else {
          final ProblemModel? preset = widget.initialProblem;
          if (preset != null && _problems.any((p) => p.problemId == preset.problemId)) {
            _selectedProblem = preset;
          } else if (_selectedProblem == null ||
              !_problems.any((p) => p.problemId == _selectedProblem!.problemId)) {
            _selectedProblem = _problems.first;
          }
        }
      });

      if (widget.team != null) return;

      final data = await FacultyTeamsService.load(widget.currentUser);
      if (!mounted) return;
      setState(() {
        _teams = data.teams.where((team) => team.status != TeamStatus.inactive).toList(growable: false);
        if (_selectedTeam == null && _teams.isNotEmpty) _selectedTeam = _teams.first;
      });
    } finally {
      if (mounted) setState(() => _loadingLookups = false);
    }
  }

  Future<void> _submit() async {
    final team = _selectedTeam;
    final problem = _selectedProblem;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (team == null || problem == null || title.isEmpty || description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Idea title and description are required.')),
        );
      }
      return;
    }
    final int fileCount = _attachmentFiles.length;
    setState(() => _busy = true);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Uploading Idea',
        message: fileCount > 0
            ? 'Uploading $fileCount attachment${fileCount == 1 ? '' : 's'} and saving idea...'
            : 'Saving idea and updating records...',
        successMessage: 'Idea submitted',
        task: () async {
          if (fileCount > 0) {
            HkzAsyncLoader.update(
              message: 'Uploading $fileCount file${fileCount == 1 ? '' : 's'} securely...',
            );
          }
          await FacultyTeamsService.submitIdea(
            faculty: widget.currentUser,
            team: team,
            problem: problem,
            ideaTitle: title,
            description: description,
            attachmentFiles: _attachmentFiles,
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _problemLabel(ProblemModel p) {
    final dept = p.departmentCode.trim();
    final base = '${p.problemNumber} • ${p.title}';
    if (dept.isEmpty) return base;
    return '$base ($dept)';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLookups) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: HkzProgressIndicator(size: 36)),
      );
    }

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
          if (_problems.isEmpty)
            const Text(
              'No active problems are available for this college. Ask a college admin to publish problems.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedProblem?.problemId,
              isExpanded: true,
              items: _problems
                  .map(
                    (problem) => DropdownMenuItem<String>(
                      value: problem.problemId,
                      child: Text(_problemLabel(problem), overflow: TextOverflow.ellipsis),
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
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Idea title',
              prefixIcon: Icon(AppIcons.ideas),
              border: OutlineInputBorder(),
              hintText: 'Short name for your solution',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Idea description',
              prefixIcon: Icon(AppIcons.attachmentDocument),
              border: OutlineInputBorder(),
              hintText: 'Describe your solution approach, impact and implementation outline.',
            ),
          ),
          const SizedBox(height: 12),
          AttachmentFilesPickField(
            files: _attachmentFiles,
            enabled: !_busy,
            onChanged: (next) => setState(() => _attachmentFiles = next),
          ),
          const SizedBox(height: 10),
          const Text('Files are uploaded to secure storage and linked to this idea after you submit.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          ResponsiveDialogActions(
            leading: const Text(
              'Submitting locks team edits for this idea cycle.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            children: <Widget>[
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _busy || _problems.isEmpty ? null : _submit,
                child: const Text('Submit Idea'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
