import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../team/models/enums/team_status.dart';
import '../../problems/models/problem_model.dart';
import '../../problems/validators/problem_submission_validators.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../screens/common/app_dialog_template.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../team/services/faculty_teams_service.dart';
import '../../team/services/team_service.dart';
import '../../../workspace/workspace.dart';
import 'package:hackz/features/attachment/widgets/attachment_pick_field.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../widgets/innovation_submission_team_selector.dart';
import '../../../widgets/loading/loading.dart';

/// Problem-first innovation submission workspace (launch from Problem Card only).
///
/// [gate] is an optional submission-control snapshot computed by the caller
/// (typically the problems list / problem-statements table). When supplied,
/// the workspace surfaces a defensive guard on save so a stale UI cannot
/// bypass the cap or the deadline.
Future<bool?> showInnovationSubmissionWorkspace({
  required BuildContext context,
  required UserModel currentUser,
  required ProblemModel problem,
  IdeaSubmissionGate? gate,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return InnovationSubmissionWorkspace(
        currentUser: currentUser,
        problem: problem,
        gate: gate,
      );
    },
  );
}

class InnovationSubmissionWorkspace extends StatefulWidget {
  const InnovationSubmissionWorkspace({
    super.key,
    required this.currentUser,
    required this.problem,
    this.gate,
  });

  final UserModel currentUser;
  final ProblemModel problem;
  final IdeaSubmissionGate? gate;

  @override
  State<InnovationSubmissionWorkspace> createState() => _InnovationSubmissionWorkspaceState();
}

class _InnovationSubmissionWorkspaceState extends State<InnovationSubmissionWorkspace> {
  static const List<String> _presentationExtensions = <String>['pdf', 'ppt', 'pptx', 'doc', 'docx'];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _gitRepositoryController = TextEditingController();
  final TextEditingController _youtubeDemoController = TextEditingController();

  List<TeamModel> _teams = <TeamModel>[];
  TeamModel? _selectedTeam;
  String? _recentTeamId;
  List<PlatformFile> _presentationFiles = <PlatformFile>[];
  bool _busy = false;
  bool _loadingTeams = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gitRepositoryController.dispose();
    _youtubeDemoController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _loadingTeams = true);
    try {
      final data = await FacultyTeamsService.load(widget.currentUser);
      if (!mounted) return;
      setState(() {
        _teams = data.teams.where((t) => t.status != TeamStatus.inactive).toList(growable: false);
        if (_selectedTeam == null && _teams.isNotEmpty) {
          _selectedTeam = _teams.first;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  bool get _canSubmit {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final IdeaSubmissionGate? g = widget.gate;
    final bool gateOpen = g == null || g.canSubmit;
    return !_busy &&
        !_loadingTeams &&
        _teams.isNotEmpty &&
        _selectedTeam != null &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        widget.problem.isSubmissionOpen &&
        gateOpen;
  }

  Future<void> _submit() async {
    final team = _selectedTeam;
    if (!_canSubmit || team == null) return;

    // Defense-in-depth: re-check the gate right before save. The caller is
    // expected to keep [widget.gate] fresh, but if the cap was hit while the
    // dialog was open we surface a snackbar identical to the problem-card
    // pill instead of dropping the user into a generic Firestore failure.
    final IdeaSubmissionGate? g = widget.gate;
    if (g != null && !g.canSubmit) {
      FeedbackService.showWarning(
        context,
        title: 'Submission blocked',
        message: describeBlockedReason(g),
      );
      return;
    }
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final int fileCount = _presentationFiles.length;
    setState(() => _busy = true);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Submitting Innovation',
        message: fileCount > 0
            ? 'Uploading $fileCount attachment${fileCount == 1 ? '' : 's'} and saving your proposal...'
            : 'Saving your innovation proposal...',
        successMessage: 'Innovation submitted',
        task: () async {
          if (fileCount > 0) {
            HkzAsyncLoader.update(
              message: 'Uploading $fileCount file${fileCount == 1 ? '' : 's'} securely...',
            );
          }
          await FacultyTeamsService.submitIdea(
            faculty: widget.currentUser,
            team: team,
            problem: widget.problem,
            ideaTitle: title,
            description: description,
            attachmentFiles: _presentationFiles,
            gitRepositoryUrl: _gitRepositoryController.text,
            youtubeDemoUrl: _youtubeDemoController.text,
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Cannot submit innovation',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Submit failed',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPresentationPanel() async {
    var draft = List<PlatformFile>.from(_presentationFiles);
    await showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.wide,
      maxWidth: 720,
      child: StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(AppIcons.attachments, color: Color(0xFF6A38FF), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Presentation / Document',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a presentation or document (PPT, PPTX, PDF, DOC, DOCX). Files upload when you submit.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
              const SizedBox(height: 14),
              AttachmentFilesPickField(
                files: draft,
                enabled: !_busy,
                label: 'Presentation files',
                hint: 'Supported: PPT, PPTX, PDF, DOC, DOCX.',
                allowedExtensions: _presentationExtensions,
                onChanged: (next) => setModal(() => draft = next),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _presentationFiles = draft);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.extraWide,
      maxWidth: 920,
      contentPadding: EdgeInsets.zero,
      footer: _buildFooter(context),
      child: _buildBody(context),
    );
  }

  EdgeInsets get _contentPadding {
    if (ResponsiveHelper.isMobile(context)) {
      return const EdgeInsets.fromLTRB(16, 8, 16, 12);
    }
    return const EdgeInsets.fromLTRB(22, 18, 22, 12);
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingTeams) {
      return Padding(
        padding: _contentPadding,
        child: const SizedBox(
          height: 320,
          child: Center(child: HkzProgressIndicator(size: 36)),
        ),
      );
    }

    return Padding(
      padding: _contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(context),
          const SizedBox(height: 14),
          _section(
            title: 'Problem context',
            compact: true,
            child: _buildProblemHero(context),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Your team',
            subtitle: 'Select the team submitting this innovation',
            child: _buildTeamSelection(context),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Title',
            child: _buildTitleField(context),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Description',
            child: _buildDescriptionField(context),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Innovation Assets',
            subtitle: 'Optional — repository, demo video, and presentation',
            child: _buildInnovationAssetsSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(AppIcons.ideas, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Innovation Submission',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                'Propose your solution for the selected challenge',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProblemHero(BuildContext context) {
    final ProblemModel p = widget.problem;
    final String title = p.title.trim().isEmpty ? 'Untitled Problem' : p.title.trim();
    final String code = p.problemNumber.trim().isEmpty ? '—' : p.problemNumber.trim();
    final String department =
        p.departmentDisplayName.trim().isEmpty ? '—' : p.departmentDisplayName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EntityCardPills.workspace(
          title,
          ContextPillSemantic.problem,
          () => WorkspaceNavigator.openProblem(context, p.problemId),
          fullWidth: true,
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _spaced(<Widget>[
              EntityCardPills.meta(code, icon: AppIcons.problems),
              EntityCardPills.meta(department, icon: AppIcons.departments),
              if (p.category.trim().isNotEmpty)
                EntityCardPills.meta(p.category.trim(), icon: AppIcons.orgType),
              if (p.theme.trim().isNotEmpty)
                EntityCardPills.meta(p.theme.trim(), icon: AppIcons.insights),
              ...p.tags.map((String t) => EntityCardPills.meta(t)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelection(BuildContext context) {
    return InnovationSubmissionTeamSelector(
      teams: _teams,
      selectedTeam: _selectedTeam,
      enabled: !_busy,
      recentTeamId: _recentTeamId,
      onTeamSelected: (TeamModel team) {
        setState(() {
          _selectedTeam = team;
          _recentTeamId = team.teamId;
        });
      },
      onOpenTeamWorkspace: (TeamModel team) => WorkspaceNavigator.openTeam(context, team.teamId),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _titleController,
        enabled: !_busy,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          height: 1.2,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'What is your innovation idea?',
          hintStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    const List<String> prompts = <String>[
      'What problem are you solving?',
      'What makes this unique?',
      'How can this scale?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: prompts
              .map(
                (String p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          enabled: !_busy,
          onChanged: (_) => setState(() {}),
          minLines: 4,
          maxLines: 6,
          style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            alignLabelWithHint: true,
            hintText: 'Describe your approach, impact, and how you will deliver it.',
            hintStyle: TextStyle(color: Colors.grey.shade500, height: 1.4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnovationAssetsSection(BuildContext context) {
    final int count = _presentationFiles.length;
    final String presentationLabel =
        count == 0 ? 'Add presentation / document' : '$count file${count == 1 ? '' : 's'} attached';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildAssetUrlField(
          controller: _gitRepositoryController,
          hint: 'https://github.com/org/repo',
          icon: Icons.code_rounded,
          label: 'Git Repository URL',
        ),
        const SizedBox(height: 10),
        _buildAssetUrlField(
          controller: _youtubeDemoController,
          hint: 'https://youtube.com/watch?v=...',
          icon: Icons.play_circle_outline_rounded,
          label: 'YouTube Demo URL',
        ),
        const SizedBox(height: 10),
        EntityCardPills.workspace(
          presentationLabel,
          ContextPillSemantic.generic,
          _openPresentationPanel,
          icon: AppIcons.attachments,
        ),
      ],
    );
  }

  Widget _buildAssetUrlField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_busy,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final team = _selectedTeam;
    final String teamLabel = team?.teamName ?? 'No team selected';
    final int attachCount = _presentationFiles.length;
    final bool ready = _canSubmit;

    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _footerMeta(Icons.groups_3_outlined, teamLabel),
              if (attachCount > 0)
                _footerMeta(AppIcons.attachments, '$attachCount presentation file${attachCount == 1 ? '' : 's'}'),
              _footerMeta(
                ready ? AppIcons.workflowApproved : AppIcons.workflowPendingReview,
                ready ? 'Ready to submit' : 'Complete required fields',
                color: ready ? const Color(0xFF059669) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(AppIcons.ideas, size: 18),
                  label: const Text('Submit Innovation'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: const Color(0xFF6A38FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerMeta(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    String? subtitle,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          SizedBox(height: compact ? 6 : 10),
          child,
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.isEmpty) return items;
    final List<Widget> out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(const SizedBox(width: 6));
      out.add(items[i]);
    }
    return out;
  }
}
