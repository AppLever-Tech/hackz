import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/models/evaluation_template.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../evaluations/services/evaluator_catalog_service.dart';
import '../../idea/models/idea_model.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_service.dart';
import '../services/ideathon_settings_service.dart';
import '../widgets/ideathon_assignee_select_row.dart';
import '../widgets/ideathon_idea_select_row.dart';

/// Department-admin Ideathon creation form (paid submitted ideas only).
class CreateIdeathonWorkspace extends StatefulWidget {
  const CreateIdeathonWorkspace({super.key, required this.user, required this.onCreated});

  final UserModel user;
  final ValueChanged<String> onCreated;

  @override
  State<CreateIdeathonWorkspace> createState() => _CreateIdeathonWorkspaceState();
}

class _CreateIdeathonWorkspaceState extends State<CreateIdeathonWorkspace> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ideaSearchController = TextEditingController();

  late DateTime _startDateTime;
  late DateTime _endDateTime;

  bool _loading = true;
  bool _saving = false;
  List<IdeaModel> _eligibleIdeas = <IdeaModel>[];
  Map<String, String> _teamNameByIdeaId = <String, String>{};
  List<UserModel> _evaluators = <UserModel>[];
  List<UserModel> _coordinators = <UserModel>[];
  List<EvaluationTemplate> _templates = <EvaluationTemplate>[];
  String? _selectedTemplateId;
  String? _optionalProblemId;

  final Set<String> _selectedIdeaIds = <String>{};
  final Set<String> _selectedJudgeIds = <String>{};
  final Set<String> _selectedCoordinatorIds = <String>{};

  int _minimumIdeas = IdeathonSettingsService.defaultMinimumIdeasForIdeathon;

  /// Collapsible sections (details/schedule stay always open).
  final Map<String, bool> _sectionExpanded = <String, bool>{
    'ideas': false,
    'evaluation': false,
    'people': false,
    'summary': false,
  };

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _startDateTime = DateTime(now.year, now.month, now.day + 14, 9, 0);
    _endDateTime = DateTime(now.year, now.month, now.day + 14, 17, 0);
    _ideaSearchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ideaSearchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final String orgId = widget.user.orgId.trim();
    final String dept = widget.user.departmentCode.trim();
    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);

    final List<IdeaModel> ideas =
        await IdeathonService.fetchEligibleIdeasForIdeathon(orgId: orgId);
    final List<UserModel> evaluators = await EvaluatorCatalogService.loadEvaluators(orgId: orgId);
    final List<UserModel> coordinators = await _loadCoordinators(orgId: orgId, dept: dept);
    final Map<String, String> teamNames = await _loadTeamNames(ideas);
    final List<EvaluationTemplate> templates = EvaluationTemplatesService.activeTemplates;
    final String defaultTemplateId = IdeathonSettingsService.ideathonEvaluationTemplateId(orgId);
    final int minimum = IdeathonSettingsService.minimumIdeasForIdeathon(orgId);

    if (!mounted) return;
    setState(() {
      _eligibleIdeas = ideas;
      _teamNameByIdeaId = teamNames;
      _evaluators = evaluators;
      _coordinators = coordinators;
      _templates = templates;
      _selectedTemplateId = templates.any((EvaluationTemplate t) => t.templateId == defaultTemplateId)
          ? defaultTemplateId
          : (templates.isNotEmpty ? templates.first.templateId : null);
      _minimumIdeas = minimum;
      _loading = false;
    });
  }

  Future<Map<String, String>> _loadTeamNames(List<IdeaModel> ideas) async {
    final Map<String, String> byIdea = <String, String>{};
    final Map<String, String> teamCache = <String, String>{};
    for (final IdeaModel idea in ideas) {
      final String teamId = idea.teamId.trim();
      if (teamId.isEmpty) continue;
      if (!teamCache.containsKey(teamId)) {
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await FirebaseFirestore.instance.collection(FirestoreUtils.hkzTeams).doc(teamId).get();
        final String name = ((doc.data()?['teamName'] as String?) ?? '').trim();
        teamCache[teamId] = name;
      }
      byIdea[idea.ideaId] = teamCache[teamId] ?? '';
    }
    return byIdea;
  }

  Future<List<UserModel>> _loadCoordinators({required String orgId, required String dept}) async {
    final String normalizedDept = dept.trim().toUpperCase();
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries =
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.coordinator.code)
          .get(),
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.faculty.code)
          .get(),
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.departmentAdmin.code)
          .get(),
    ];
    final List<QuerySnapshot<Map<String, dynamic>>> results =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(queries);
    final Map<String, UserModel> byId = <String, UserModel>{};
    for (final QuerySnapshot<Map<String, dynamic>> snap in results) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
        if (normalizedDept.isNotEmpty &&
            user.departmentCode.trim().toUpperCase() != normalizedDept) {
          continue;
        }
        byId[user.userId] = user;
      }
    }
    final List<UserModel> users = byId.values.toList()
      ..sort((UserModel a, UserModel b) {
        final int roleCmp = _coordinatorListRoleRank(a.role).compareTo(_coordinatorListRoleRank(b.role));
        if (roleCmp != 0) return roleCmp;
        return a.displayName.compareTo(b.displayName);
      });
    return users;
  }

  /// Coordinator assignees: department coordinator → faculty → department admin.
  static int _coordinatorListRoleRank(String roleCode) {
    return switch (UserRole.fromCode(roleCode)) {
      UserRole.coordinator => 0,
      UserRole.faculty => 1,
      UserRole.departmentAdmin => 2,
      _ => 3,
    };
  }

  List<({String id, String label})> get _problemOptions {
    final Map<String, String> byId = <String, String>{};
    for (final IdeaModel idea in _eligibleIdeas) {
      final String id = idea.problemId.trim();
      if (id.isEmpty) continue;
      final String title = idea.problemTitle.trim().isEmpty ? id : idea.problemTitle.trim();
      byId.putIfAbsent(id, () => title);
    }
    final List<MapEntry<String, String>> entries = byId.entries.toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) => a.value.compareTo(b.value));
    return entries
        .map((MapEntry<String, String> e) => (id: e.key, label: e.value))
        .toList(growable: false);
  }

  List<IdeaModel> get _filteredIdeas {
    final String q = _ideaSearchController.text.trim().toLowerCase();
    final String? problemId = _optionalProblemId;
    return _eligibleIdeas.where((IdeaModel idea) {
      if (problemId != null && problemId.isNotEmpty && idea.problemId.trim() != problemId) {
        return false;
      }
      if (q.isEmpty) return true;
      final String hay = <String>[
        idea.ideaTitle,
        idea.description,
        idea.problemTitle,
        idea.problemDepartmentCode,
        _teamNameByIdeaId[idea.ideaId] ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }

  EvaluationTemplate? get _selectedTemplate {
    final String? id = _selectedTemplateId;
    if (id == null || id.isEmpty) return null;
    for (final EvaluationTemplate t in _templates) {
      if (t.templateId == id) return t;
    }
    return null;
  }

  bool get _scheduleValid => _endDateTime.isAfter(_startDateTime);

  bool get _minimumMet => _selectedIdeaIds.length >= _minimumIdeas;

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _scheduleValid &&
      _minimumMet &&
      _selectedJudgeIds.isNotEmpty &&
      (_selectedTemplateId ?? '').trim().isNotEmpty &&
      !_saving;

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime current = isStart ? _startDateTime : _endDateTime;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time == null || !mounted) return;
    setState(() {
      final DateTime next = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDateTime = next;
        if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 8));
        }
      } else {
        _endDateTime = next;
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final String id = await IdeathonService.createIdeathon(
        actor: widget.user,
        input: CreateIdeathonInput(
          name: _nameController.text,
          description: _descriptionController.text,
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          ideaIds: _selectedIdeaIds.toList(),
          judgeIds: _selectedJudgeIds.toList(),
          coordinatorIds: _selectedCoordinatorIds.toList(),
          evaluationTemplateId: _selectedTemplateId ?? '',
          problemId: _optionalProblemId ?? '',
        ),
      );
      if (!mounted) return;
      widget.onCreated(id);
      FeedbackService.showSuccess(
        context,
        title: 'Ideathon created',
        message: 'Event created with ${_selectedIdeaIds.length} paid ideas.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to create ideathon', message: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    final EdgeInsets pad = EdgeInsets.fromLTRB(mobile ? 16 : 22, 8, mobile ? 16 : 22, 16);

    final Widget detailsCard = _sectionCard(
      title: 'Ideathon Details',
      icon: AppIcons.ideathons,
      fillRemaining: !mobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: HackzInputDecoration.fieldTextStyle,
            decoration: HackzInputDecoration.decorate(labelText: 'Event name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            style: HackzInputDecoration.fieldTextStyle,
            decoration: HackzInputDecoration.decorate(labelText: 'Description (optional)'),
          ),
        ],
      ),
    );

    final Widget scheduleCard = _sectionCard(
      title: 'Schedule',
      icon: AppIcons.clock,
      fillRemaining: !mobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _scheduleField(
            label: 'Start',
            icon: AppIcons.event,
            value: formatDateTime(_startDateTime.toLocal()),
            onTap: () => _pickDateTime(isStart: true),
          ),
          const SizedBox(height: 12),
          _scheduleField(
            label: 'End',
            icon: AppIcons.event,
            value: formatDateTime(_endDateTime.toLocal()),
            onTap: () => _pickDateTime(isStart: false),
          ),
          if (!_scheduleValid) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'End date/time must be after start date/time.',
              style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: pad,
            children: <Widget>[
              if (mobile) ...<Widget>[
                detailsCard,
                const SizedBox(height: 14),
                scheduleCard,
              ] else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(flex: 3, child: detailsCard),
                      const SizedBox(width: 14),
                      Expanded(flex: 2, child: scheduleCard),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Paid & Confirmed Ideas',
                icon: AppIcons.ideas,
                sectionKey: 'ideas',
                collapsible: true,
                trailing: _ideasSectionTrailing(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Only submitted ideas with coordinator-confirmed Faculty payment appear here. '
                      'Select at least the org minimum of paid ideas to create the Ideathon.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_problemOptions.isNotEmpty) ...<Widget>[
                          SizedBox(
                            width: mobile ? 148 : 200,
                            child: HackzSelectField<String>(
                              value: _optionalProblemId ?? '',
                              hint: 'All problems',
                              prefixIcon: AppIcons.problems,
                              minWidth: mobile ? 148 : 200,
                              options: <String>['', ..._problemOptions.map((e) => e.id)],
                              labelBuilder: (String id) {
                                if (id.isEmpty) return 'All problems';
                                for (final option in _problemOptions) {
                                  if (option.id == id) return option.label;
                                }
                                return id;
                              },
                              iconBuilder: (_) => AppIcons.problems,
                              onChanged: (String id) =>
                                  setState(() => _optionalProblemId = id.isEmpty ? null : id),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextField(
                            controller: _ideaSearchController,
                            style: HackzInputDecoration.fieldTextStyle,
                            decoration: HackzInputDecoration.decorate(
                              hintText: 'Search ideas, teams, problems…',
                              prefixIcon:
                                  const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_problemOptions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      const Text(
                        'Problem filter is optional. An Ideathon can include ideas from multiple problems.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (_filteredIdeas.isEmpty)
                      const Text(
                        'No paid ideas available. Faculty must pay and a coordinator must verify payment before ideas appear here.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    else
                      ..._filteredIdeas.map(
                        (IdeaModel idea) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: IdeathonIdeaSelectRow(
                            idea: idea,
                            selected: _selectedIdeaIds.contains(idea.ideaId),
                            teamName: _teamNameByIdeaId[idea.ideaId] ?? '',
                            onToggle: () => setState(() {
                              if (_selectedIdeaIds.contains(idea.ideaId)) {
                                _selectedIdeaIds.remove(idea.ideaId);
                              } else {
                                _selectedIdeaIds.add(idea.ideaId);
                              }
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Evaluation Template',
                icon: AppIcons.scoring,
                sectionKey: 'evaluation',
                collapsible: true,
                trailing: _evaluationSectionTrailing(),
                child: _buildTemplateSection(),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'People',
                icon: AppIcons.users,
                sectionKey: 'people',
                collapsible: true,
                trailing: _peopleSectionTrailing(),
                child: _buildJudgesCoordinatorsSection(context),
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Summary',
                icon: AppIcons.checklist,
                sectionKey: 'summary',
                collapsible: true,
                child: _buildSummary(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _ideasSectionTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _statusChip(
          ok: _selectedIdeaIds.isNotEmpty,
          icon: AppIcons.ideas,
          label: '${_selectedIdeaIds.length}',
        ),
        const SizedBox(width: 6),
        _minimumFeedback(),
      ],
    );
  }

  Widget _evaluationSectionTrailing() {
    final EvaluationTemplate? template = _selectedTemplate;
    final bool selected = template != null;
    final String name = selected
        ? (template.templateName.trim().isEmpty ? template.templateId : template.templateName.trim())
        : 'Not selected';
    return _statusChip(
      ok: selected,
      icon: AppIcons.scoring,
      label: name,
    );
  }

  Widget _peopleSectionTrailing() {
    final int judges = _selectedJudgeIds.length;
    final int coordinators = _selectedCoordinatorIds.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _statusChip(
          ok: judges > 0,
          icon: AppIcons.judges,
          label: '$judges',
        ),
        const SizedBox(width: 6),
        _statusChip(
          ok: coordinators > 0,
          icon: AppIcons.coordinator,
          label: '$coordinators',
        ),
      ],
    );
  }

  Widget _statusChip({
    required bool ok,
    required IconData icon,
    required String label,
  }) {
    final Color fg = ok ? const Color(0xFF047857) : const Color(0xFF9A3412);
    final Color iconColor = ok ? const Color(0xFF047857) : const Color(0xFFC2410C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ok ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            softWrap: true,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _minimumFeedback() {
    final bool met = _minimumMet;
    final String text = met
        ? 'Minimum paid ideas met'
        : '${_selectedIdeaIds.length} of $_minimumIdeas paid ideas required';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: met ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: met ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            met ? AppIcons.workflowApproved : AppIcons.info,
            size: 14,
            color: met ? const Color(0xFF047857) : const Color(0xFFC2410C),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: met ? const Color(0xFF047857) : const Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: HackzInputDecoration.labelStyle),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HackzInputDecoration.radius),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minWidth: 140),
            padding: HackzInputDecoration.contentPadding,
            decoration: HackzInputDecoration.pickerDecoration(),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 16, color: HackzInputDecoration.iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HackzInputDecoration.fieldTextStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSection() {
    if (_templates.isEmpty) {
      return const Text(
        'No active evaluation templates. Configure templates in Organization Settings.',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
      );
    }
    final EvaluationTemplate? selected = _selectedTemplate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Choose the evaluation template used for this Ideathon.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        HackzSelectField<String>(
          value: _selectedTemplateId,
          hint: 'Select evaluation template',
          prefixIcon: AppIcons.scoring,
          options: _templates.map((EvaluationTemplate t) => t.templateId).toList(growable: false),
          labelBuilder: (String id) {
            for (final EvaluationTemplate t in _templates) {
              if (t.templateId == id) return t.templateName;
            }
            return id;
          },
          iconBuilder: (_) => AppIcons.scoring,
          onChanged: (String id) => setState(() => _selectedTemplateId = id),
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 10),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: EntityCardPills.workspace(
              selected.templateName,
              ContextPillSemantic.evaluationTemplate,
              () => WorkspaceNavigator.openEvaluationTemplate(context, selected.templateId),
              icon: AppIcons.scoring,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary() {
    final EvaluationTemplate? template = _selectedTemplate;
    final String judges = _selectedJudgeIds.isEmpty
        ? 'None'
        : '${_selectedJudgeIds.length} selected';
    final String coords = _selectedCoordinatorIds.isEmpty
        ? 'None'
        : '${_selectedCoordinatorIds.length} selected';
    return Column(
      children: <Widget>[
        _summaryRow('Schedule', value: '${formatDateTime(_startDateTime.toLocal())} → ${formatDateTime(_endDateTime.toLocal())}'),
        _summaryRow('Paid ideas selected', value: '${_selectedIdeaIds.length}'),
        _summaryRow(
          'Minimum paid ideas',
          value: _minimumMet ? 'Met ($_minimumIdeas)' : '$_minimumIdeas required',
        ),
        _summaryRow(
          'Evaluation template',
          child: template == null
              ? null
              : EntityCardPills.workspace(
                  template.templateName,
                  ContextPillSemantic.evaluationTemplate,
                  () => WorkspaceNavigator.openEvaluationTemplate(context, template.templateId),
                  icon: AppIcons.scoring,
                ),
          value: template == null ? 'Not selected' : null,
        ),
        _summaryRow('Judges', value: judges),
        _summaryRow('Coordinators', value: coords),
      ],
    );
  }

  Widget _summaryRow(String label, {String? value, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? sectionKey,
    bool collapsible = false,
    bool fillRemaining = false,
    Widget? trailing,
  }) {
    final bool expanded = !collapsible || (_sectionExpanded[sectionKey] ?? false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: collapsible && sectionKey != null
                ? () => setState(() => _sectionExpanded[sectionKey] = !expanded)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 18, color: const Color(0xFF6A38FF)),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    flex: 0,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  if (collapsible) ...<Widget>[
                    const SizedBox(width: 6),
                    Icon(
                      expanded ? AppIcons.expandLess : AppIcons.expandMore,
                      size: 22,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: 12),
            if (fillRemaining) ...<Widget>[
              child,
              const Spacer(),
            ] else
              child,
          ],
        ],
      ),
    );
  }

  Widget _buildJudgesCoordinatorsSection(BuildContext context) {
    final bool sideBySide = !ResponsiveHelper.isMobile(context);
    final Widget judges = _buildAssigneeList(
      title: 'Judges',
      titleIcon: AppIcons.judges,
      users: _evaluators,
      selectedIds: _selectedJudgeIds,
      showJudgeType: true,
      onToggle: (String userId) => setState(() {
        if (_selectedJudgeIds.contains(userId)) {
          _selectedJudgeIds.remove(userId);
        } else {
          _selectedJudgeIds.add(userId);
        }
      }),
      emptyMessage: 'No judges available.',
    );
    final Widget coordinators = _buildAssigneeList(
      title: 'Coordinators',
      titleIcon: AppIcons.coordinator,
      users: _coordinators,
      selectedIds: _selectedCoordinatorIds,
      leadingIcon: AppIcons.coordinator,
      onToggle: (String userId) => setState(() {
        if (_selectedCoordinatorIds.contains(userId)) {
          _selectedCoordinatorIds.remove(userId);
        } else {
          _selectedCoordinatorIds.add(userId);
        }
      }),
      emptyMessage: 'No coordinators available.',
    );

    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: judges),
          const SizedBox(width: 12),
          Expanded(child: coordinators),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        judges,
        const SizedBox(height: 14),
        coordinators,
      ],
    );
  }

  Widget _buildAssigneeList({
    required String title,
    required IconData titleIcon,
    required List<UserModel> users,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
    required String emptyMessage,
    IconData? leadingIcon,
    bool showJudgeType = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(titleIcon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        if (users.isEmpty)
          Text(emptyMessage, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
        else
          ...users.map(
            (UserModel user) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IdeathonAssigneeSelectRow(
                user: user,
                selected: selectedIds.contains(user.userId),
                leadingIcon: leadingIcon,
                showJudgeType: showJudgeType,
                onToggle: () => onToggle(user.userId),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
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
      child: FilledButton.icon(
        onPressed: _canSubmit ? _submit : null,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(AppIcons.add, size: 18),
        label: const Text('Create Ideathon'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: const Color(0xFF6A38FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
