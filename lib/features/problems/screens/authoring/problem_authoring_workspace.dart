import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../../../models/attachment_model.dart';
import '../../../../models/enums/user_role.dart';
import '../../../../models/user_model.dart';
import '../../../../responsive/responsive_helper.dart';
import '../../../../shared/feedback/feedback.dart';
import '../../../../utils/attachment_service.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../widgets/attachment_upload_preview.dart';
import '../../../org_settings/constants/org_setting_keys.dart';
import '../../../org_settings/services/org_settings_service.dart';
import '../../constants/problem_constants.dart';
import '../../models/problem_model.dart';
import '../../services/problem_utils.dart';
import '../../validators/problem_authoring_validators.dart';
import 'problem_authoring_inputs.dart';
import 'problem_authoring_section.dart';

/// Full-screen "Problem Authoring Workspace" - replaces the old CRUD dialog.
///
/// Renders an innovation-platform style sectional workspace:
/// sticky header, hero, progressive expandable sections, sticky footer.
class ProblemAuthoringWorkspace extends StatefulWidget {
  const ProblemAuthoringWorkspace({
    super.key,
    required this.currentUser,
    this.initialProblem,
    this.embedded = false,
    this.onBack,
    this.onSaved,
  });

  final UserModel currentUser;
  final ProblemModel? initialProblem;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  @override
  State<ProblemAuthoringWorkspace> createState() => _ProblemAuthoringWorkspaceState();
}

enum _AuthoringSectionId {
  coreChallenge,
  innovationContext,
  expectedOutcomes,
  constraints,
  submissionControls,
  teamRules,
  techStack,
  classification,
  resources,
  attachments,
}

class _ProblemAuthoringWorkspaceState extends State<ProblemAuthoringWorkspace> {
  // Hero
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  // Section 1 - Core Challenge
  final TextEditingController _descriptionController = TextEditingController();

  // Section 2 - Innovation Context
  final TextEditingController _backgroundController = TextEditingController();
  final TextEditingController _impactController = TextEditingController();
  final TextEditingController _stakeholdersController = TextEditingController();
  final TextEditingController _researchController = TextEditingController();

  // Section 3 - Expected Outcomes
  final TextEditingController _expectedSolutionController = TextEditingController();
  final TextEditingController _successCriteriaController = TextEditingController();
  final TextEditingController _deliverablesController = TextEditingController();
  List<String> _suggestedTechnologies = <String>[];

  // Section 4 - Constraints & Feasibility
  final TextEditingController _constraintsController = TextEditingController();
  final TextEditingController _timelineController = TextEditingController();
  String _difficultyLevel = '';
  String _complexityLevel = '';

  // Section 5 - Classification
  final TextEditingController _themeController = TextEditingController();
  String _selectedDepartment = '';
  String _selectedCategory = '';
  List<String> _tags = <String>[];

  // Section 6 - Resources & Contact
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _datasetController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  List<String> _referenceLinks = <String>[];

  // Section 7 - Attachments
  final List<PlatformFile> _attachments = <PlatformFile>[];

  // Submission Controls (org-scoped — prefilled from OrgSettings on init).
  final TextEditingController _maxIdeasController = TextEditingController();
  DateTime? _ideaSubmissionDeadline;

  // Team Rules (org-scoped overrides per-problem).
  int? _minTeamSize;
  int? _maxTeamSize;

  // Tech Stack (free chip input).
  List<String> _preferredTechStack = <String>[];

  // Org-level bounds cached after settings load — used for stepper limits and
  // validation. Default values match the org-settings defaults so the
  // workspace stays usable even if the settings load fails.
  int _orgMaxAllowedIdeas = 50;
  int _orgMinTeamSize = 1;
  int _orgMaxTeamSize = 30;

  // Workspace state
  bool _isActive = true;
  bool _isLoadingDepartments = true;
  bool _isSubmitting = false;
  List<Map<String, String>> _departmentOptions = <Map<String, String>>[];

  late final Set<_AuthoringSectionId> _expanded = <_AuthoringSectionId>{
    _AuthoringSectionId.coreChallenge,
  };

  bool get _isEdit => widget.initialProblem != null;
  bool get _isDeptAdmin =>
      UserRole.fromCode(widget.currentUser.role) == UserRole.departmentAdmin;

  static const List<String> _difficultyOptions = <String>['Beginner', 'Intermediate', 'Advanced'];
  static const List<String> _complexityOptions = <String>['Low', 'Medium', 'High'];
  static const List<String> _technologySuggestions = <String>[
    'AI/ML', 'IoT', 'GIS', 'Robotics', 'Cloud', 'Blockchain',
    'AR/VR', 'Mobile', 'Data Science', 'Cybersecurity',
  ];
  // Same shape as the suggested-technologies catalog above but used by the
  // dedicated "Preferred tech stack" section. Kept separate so authors can
  // mix-and-match without the lists colliding when both are edited.
  static const List<String> _techStackSuggestions = <String>[
    'Flutter', 'AI/ML', 'IoT', 'Cloud', 'Cybersecurity',
    'Mobile', 'Web', 'Data Science', 'AR/VR', 'Blockchain',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProblem;
    if (p != null) {
      _titleController.text = p.title;
      _summaryController.text = p.summary;
      _descriptionController.text = p.description;
      _backgroundController.text = p.background;
      _impactController.text = p.impact;
      _stakeholdersController.text = p.stakeholders;
      _researchController.text = p.researchContext;
      _expectedSolutionController.text = p.expectedSolution;
      _successCriteriaController.text = p.successCriteria;
      _deliverablesController.text = p.expectedDeliverables;
      _suggestedTechnologies = List<String>.from(p.suggestedTechnologies);
      _constraintsController.text = p.constraints;
      _timelineController.text = p.timeline;
      _difficultyLevel = p.difficultyLevel;
      _complexityLevel = p.complexityLevel;
      _themeController.text = p.theme;
      _selectedCategory = p.category;
      _selectedDepartment = p.departmentCode;
      _tags = List<String>.from(p.tags);
      _youtubeController.text = p.youtubeLink;
      _datasetController.text = p.datasetLink;
      _contactController.text = p.contactInformation;
      _referenceLinks = List<String>.from(p.referenceLinks);
      _isActive = p.isActive;

      // Section 8 — Submission Controls / Team Rules / Tech Stack.
      if (p.maxIdeasAllowed != null) {
        _maxIdeasController.text = p.maxIdeasAllowed.toString();
      }
      _ideaSubmissionDeadline = p.ideaSubmissionDeadline;
      _minTeamSize = p.minTeamSize;
      _maxTeamSize = p.maxTeamSize;
      _preferredTechStack = List<String>.from(p.preferredTechStack);
    } else {
      _ideaSubmissionDeadline = _oneMonthFrom(DateTime.now());
    }
    for (final c in _allControllers) {
      c.addListener(_onAnyControllerChanged);
    }
    _loadDepartments();
    _loadOrgSettingsBounds();
  }

  DateTime _oneMonthFrom(DateTime base) {
    final int year = base.month == 12 ? base.year + 1 : base.year;
    final int month = base.month == 12 ? 1 : base.month + 1;
    final DateTime firstOfNextNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final int maxDayInTargetMonth = firstOfNextNextMonth.subtract(const Duration(days: 1)).day;
    final int day = base.day <= maxDayInTargetMonth ? base.day : maxDayInTargetMonth;
    return DateTime(year, month, day, base.hour, base.minute);
  }

  /// Reads submission-control + team-size bounds from `OrgSettingsService` so
  /// the new sections can prefill defaults and validate against the org caps.
  ///
  /// Existing problems keep their already-saved override; new problems get
  /// the org `defaultMaxIdeasPerProblem` prefilled into the input.
  Future<void> _loadOrgSettingsBounds() async {
    try {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.currentUser.orgId);
      if (!mounted) return;
      final Map<String, dynamic> values = OrgSettingsService.instance.valuesSnapshot;
      final int defMax = (values[OrgSettingKeys.defaultMaxIdeasPerProblem] as num?)?.toInt() ?? 50;
      final int maxAllowed = (values[OrgSettingKeys.maxAllowedIdeasPerProblem] as num?)?.toInt() ?? 50;
      final int orgMinTeam = (values[OrgSettingKeys.minStudentsPerTeam] as num?)?.toInt() ?? 1;
      final int orgMaxTeam = (values[OrgSettingKeys.maxStudentsPerTeam] as num?)?.toInt() ?? 30;
      setState(() {
        _orgMaxAllowedIdeas = maxAllowed;
        _orgMinTeamSize = orgMinTeam;
        _orgMaxTeamSize = orgMaxTeam;
        // Prefill `max ideas allowed` only on create — never override an
        // existing per-problem value.
        if (!_isEdit && _maxIdeasController.text.trim().isEmpty) {
          _maxIdeasController.text = defMax.toString();
        }
      });
    } catch (_) {
      // Safe fallback values are already in place; suppress to avoid blocking
      // the authoring flow on settings-load hiccups.
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c
        ..removeListener(_onAnyControllerChanged)
        ..dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => <TextEditingController>[
        _titleController,
        _summaryController,
        _descriptionController,
        _backgroundController,
        _impactController,
        _stakeholdersController,
        _researchController,
        _expectedSolutionController,
        _successCriteriaController,
        _deliverablesController,
        _constraintsController,
        _timelineController,
        _themeController,
        _youtubeController,
        _datasetController,
        _contactController,
        _maxIdeasController,
      ];

  void _onAnyControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDepartments() async {
    try {
      final rows = await FirestoreUtils.getDepartmentsByCollege(widget.currentUser.orgId);
      final options = rows
          .map((row) {
            final code = ((row['code'] as String?) ?? '').trim();
            final name = ((row['name'] as String?) ?? '').trim();
            if (code.isEmpty || name.isEmpty) return null;
            return <String, String>{'code': code, 'name': name};
          })
          .whereType<Map<String, String>>()
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _departmentOptions = options;
        if (_isDeptAdmin) {
          _selectedDepartment = widget.currentUser.departmentCode.trim().toUpperCase();
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      for (final file in result.files) {
        final alreadyAdded = _attachments.any((f) => f.name == file.name && f.size == file.size);
        if (!alreadyAdded) _attachments.add(file);
      }
    });
  }

  // ----- Completion logic -----

  bool _filled(String value) => value.trim().isNotEmpty;

  AuthoringSectionStatus _coreChallengeStatus() => AuthoringSectionStatus(
        completed: _filled(_descriptionController.text) ? 1 : 0,
        total: 1,
        required: true,
      );

  AuthoringSectionStatus _innovationContextStatus() {
    int filled = 0;
    if (_filled(_backgroundController.text)) filled++;
    if (_filled(_impactController.text)) filled++;
    if (_filled(_stakeholdersController.text)) filled++;
    if (_filled(_researchController.text)) filled++;
    return AuthoringSectionStatus(completed: filled, total: 4);
  }

  AuthoringSectionStatus _expectedOutcomesStatus() {
    int filled = 0;
    if (_filled(_expectedSolutionController.text)) filled++;
    if (_filled(_successCriteriaController.text)) filled++;
    if (_filled(_deliverablesController.text)) filled++;
    if (_suggestedTechnologies.isNotEmpty) filled++;
    return AuthoringSectionStatus(completed: filled, total: 4);
  }

  AuthoringSectionStatus _constraintsStatus() {
    int filled = 0;
    if (_filled(_constraintsController.text)) filled++;
    if (_filled(_timelineController.text)) filled++;
    if (_filled(_difficultyLevel)) filled++;
    if (_filled(_complexityLevel)) filled++;
    return AuthoringSectionStatus(completed: filled, total: 4);
  }

  AuthoringSectionStatus _classificationStatus() {
    int filled = 0;
    if (_filled(_selectedDepartment)) filled++;
    if (_filled(_selectedCategory)) filled++;
    if (_filled(_themeController.text)) filled++;
    if (_tags.isNotEmpty) filled++;
    return AuthoringSectionStatus(completed: filled, total: 4, required: true);
  }

  AuthoringSectionStatus _resourcesStatus() {
    int filled = 0;
    if (_filled(_youtubeController.text)) filled++;
    if (_filled(_datasetController.text)) filled++;
    if (_referenceLinks.isNotEmpty) filled++;
    if (_filled(_contactController.text)) filled++;
    return AuthoringSectionStatus(completed: filled, total: 4);
  }

  AuthoringSectionStatus _attachmentsStatus() => AuthoringSectionStatus(
        completed: _attachments.isEmpty ? 0 : 1,
        total: 1,
      );

  AuthoringSectionStatus _submissionControlsStatus() {
    int filled = 0;
    if (_filled(_maxIdeasController.text)) filled++;
    if (_ideaSubmissionDeadline != null) filled++;
    return AuthoringSectionStatus(completed: filled, total: 2);
  }

  AuthoringSectionStatus _teamRulesStatus() {
    int filled = 0;
    if (_minTeamSize != null) filled++;
    if (_maxTeamSize != null) filled++;
    return AuthoringSectionStatus(completed: filled, total: 2);
  }

  AuthoringSectionStatus _techStackStatus() => AuthoringSectionStatus(
        completed: _preferredTechStack.isEmpty ? 0 : 1,
        total: 1,
      );

  bool get _canPublish {
    if (_isSubmitting || _isLoadingDepartments) return false;
    if (!_filled(_titleController.text)) return false;
    if (!_filled(_descriptionController.text)) return false;
    if (!_filled(_selectedDepartment)) return false;
    if (!_filled(_selectedCategory)) return false;
    if (!_filled(_themeController.text)) return false;
    return true;
  }

  // Hero counts only required fields used to gate publish.
  int get _requiredFieldsTotal => 5;
  int get _requiredFieldsCompleted {
    int filled = 0;
    if (_filled(_titleController.text)) filled++;
    if (_filled(_descriptionController.text)) filled++;
    if (_filled(_selectedDepartment)) filled++;
    if (_filled(_selectedCategory)) filled++;
    if (_filled(_themeController.text)) filled++;
    return filled;
  }

  void _toggleSection(_AuthoringSectionId id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Future<void> _publish() async {
    if (!_canPublish) return;

    // Centralized publish-time validation for the new submission-control,
    // team-rules, and tech-stack fields. Returns early with a snackbar on
    // the first violation so we don't fall back to a generic Firestore
    // error later in the save path.
    final int? maxIdeasValue = int.tryParse(_maxIdeasController.text.trim());
    final List<String?> errors = <String?>[
      ProblemAuthoringValidators.validateMaxIdeasAllowed(maxIdeasValue, _orgMaxAllowedIdeas),
      ProblemAuthoringValidators.validateDeadline(_ideaSubmissionDeadline),
      ProblemAuthoringValidators.validateTeamSize(
        min: _minTeamSize,
        max: _maxTeamSize,
        orgMin: _orgMinTeamSize,
        orgMax: _orgMaxTeamSize,
      ),
    ];
    final String? firstError = errors.firstWhere((String? e) => e != null, orElse: () => null);
    if (firstError != null) {
      FeedbackService.showWarning(
        context,
        title: 'Validation failed',
        message: firstError,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final problemNumber = _isEdit
          ? widget.initialProblem!.problemNumber
          : await ProblemUtils.generateProblemNumber();
      final orgTypeName = widget.currentUser.orgType?.name ?? 'college';
      final createProblemId = _isEdit
          ? widget.initialProblem!.problemId
          : FirebaseFirestore.instance.collection(FirestoreUtils.hkzProblems).doc().id;

      if (_attachments.isNotEmpty) {
        await AttachmentService.uploadAttachments(
          entityType: AttachmentEntityType.problem,
          entityId: createProblemId,
          orgId: widget.currentUser.orgId,
          departmentCode: _selectedDepartment,
          uploadedBy: widget.currentUser.userId,
          files: _attachments,
          fileType: 'problem',
        );
      }

      final problem = ProblemModel(
        problemId: createProblemId,
        problemNumber: problemNumber,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        orgId: widget.currentUser.orgId,
        orgType: orgTypeName,
        departmentCode: _selectedDepartment,
        createdBy: widget.currentUser.userId,
        category: _selectedCategory,
        theme: _themeController.text.trim(),
        tags: _tags,
        attachments: const <String>[],
        isActive: _isActive,
        createdAt: widget.initialProblem?.createdAt ?? DateTime.now(),
        updatedAt: _isEdit ? DateTime.now() : null,
        summary: _summaryController.text.trim(),
        background: _backgroundController.text.trim(),
        impact: _impactController.text.trim(),
        stakeholders: _stakeholdersController.text.trim(),
        researchContext: _researchController.text.trim(),
        expectedSolution: _expectedSolutionController.text.trim(),
        successCriteria: _successCriteriaController.text.trim(),
        expectedDeliverables: _deliverablesController.text.trim(),
        suggestedTechnologies: _suggestedTechnologies,
        constraints: _constraintsController.text.trim(),
        difficultyLevel: _difficultyLevel,
        timeline: _timelineController.text.trim(),
        complexityLevel: _complexityLevel,
        youtubeLink: _youtubeController.text.trim(),
        datasetLink: _datasetController.text.trim(),
        referenceLinks: _referenceLinks,
        contactInformation: _contactController.text.trim(),
        maxIdeasAllowed: maxIdeasValue,
        ideaSubmissionDeadline: _ideaSubmissionDeadline,
        minTeamSize: _minTeamSize,
        maxTeamSize: _maxTeamSize,
        preferredTechStack: _preferredTechStack,
      );

      if (_isEdit) {
        await FirestoreUtils.updateProblem(problem.problemId, problem.toMap());
      } else {
        await FirestoreUtils.createProblemWithId(
          problem: problem,
          problemId: createProblemId,
        );
      }
      if (!mounted) return;
      if (widget.embedded) {
        widget.onSaved?.call();
      } else {
        Navigator.of(context).maybePop(true);
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Unable to publish problem',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleBack() {
    if (widget.embedded) {
      widget.onBack?.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    final body = _buildWorkspaceBody(context);
    if (widget.embedded) {
      return Container(color: const Color(0xFFF5F7FB), child: body);
    }
    return Scaffold(backgroundColor: const Color(0xFFF5F7FB), body: SafeArea(child: body));
  }

  Widget _buildWorkspaceBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AuthoringTopBar(
          isEdit: _isEdit,
          isSubmitting: _isSubmitting,
          requiredCompleted: _requiredFieldsCompleted,
          requiredTotal: _requiredFieldsTotal,
          canPublish: _canPublish,
          onBack: _handleBack,
          onPublish: _publish,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.isMobile(context) ? 14 : 24,
              16,
              ResponsiveHelper.isMobile(context) ? 14 : 24,
              16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _AuthoringHero(
                      titleController: _titleController,
                      summaryController: _summaryController,
                      isActive: _isActive,
                      onActiveChanged: (v) => setState(() => _isActive = v),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      id: _AuthoringSectionId.coreChallenge,
                      title: 'Core Challenge',
                      subtitle: 'Define what innovators should solve',
                      icon: AppIcons.problems,
                      iconBg: const Color(0xFFFFF1E5),
                      iconColor: const Color(0xFFEA580C),
                      status: _coreChallengeStatus(),
                      child: AuthoringTextArea(
                        controller: _descriptionController,
                        label: 'Problem description',
                        hint: 'Describe the core challenge in clear, inspiring language.',
                        helperPrompts: const <String>[
                          'What is the core problem?',
                          'What challenge should innovators solve?',
                          'Why does this matter today?',
                        ],
                        minLines: 4,
                        maxLines: 8,
                        enabled: !_isSubmitting,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.classification,
                      title: 'Classification',
                      subtitle: 'Department, category, theme, and tags',
                      icon: AppIcons.orgType,
                      iconBg: const Color(0xFFE6F8EF),
                      iconColor: const Color(0xFF047857),
                      status: _classificationStatus(),
                      child: _buildClassification(),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.innovationContext,
                      title: 'Innovation Context',
                      subtitle: 'Background, impact, and stakeholders',
                      icon: AppIcons.insights,
                      iconBg: const Color(0xFFE9F1FF),
                      iconColor: const Color(0xFF2563EB),
                      status: _innovationContextStatus(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AuthoringTextArea(
                            controller: _backgroundController,
                            label: 'Background',
                            hint: 'What is the historical or domain context for this challenge?',
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextArea(
                            controller: _impactController,
                            label: 'Why this needs to be solved / Impact',
                            hint: 'Who is affected and what changes when this is solved?',
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextArea(
                            controller: _stakeholdersController,
                            label: 'Stakeholders / Beneficiaries',
                            hint: 'Communities, organizations, or users who benefit.',
                            minLines: 2,
                            maxLines: 4,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextArea(
                            controller: _researchController,
                            label: 'Supporting data / Research context',
                            hint: 'Stats, prior work, or references that justify the problem.',
                            minLines: 2,
                            maxLines: 4,
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.expectedOutcomes,
                      title: 'Expected Outcomes',
                      subtitle: 'Solution direction, success criteria, deliverables',
                      icon: AppIcons.ideas,
                      iconBg: const Color(0xFFF6F0FF),
                      iconColor: const Color(0xFF7C3AED),
                      status: _expectedOutcomesStatus(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AuthoringTextArea(
                            controller: _expectedSolutionController,
                            label: 'Expected solution direction',
                            hint: 'How should innovators approach this challenge?',
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextArea(
                            controller: _successCriteriaController,
                            label: 'Success criteria',
                            hint: 'What defines a winning solution? Measurable outcomes.',
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextArea(
                            controller: _deliverablesController,
                            label: 'Expected deliverables',
                            hint: 'Prototype, demo, research paper, MVP, etc.',
                            minLines: 2,
                            maxLines: 4,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringChipInput(
                            label: 'Suggested technologies',
                            hint: 'Add a technology and press Enter',
                            values: _suggestedTechnologies,
                            suggestions: _technologySuggestions,
                            enabled: !_isSubmitting,
                            onChanged: (next) => setState(() => _suggestedTechnologies = next),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.constraints,
                      title: 'Constraints & Feasibility',
                      subtitle: 'Real-world limits, difficulty, and timeline',
                      icon: AppIcons.statusUnderReview,
                      iconBg: const Color(0xFFFEF3E6),
                      iconColor: const Color(0xFFD97706),
                      status: _constraintsStatus(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AuthoringTextArea(
                            controller: _constraintsController,
                            label: 'Constraints / Limitations',
                            hint: 'Regulatory, technical, ethical, or budget constraints.',
                            minLines: 2,
                            maxLines: 4,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          AuthoringPairRow(
                            first: AuthoringChoiceChips(
                              label: 'Difficulty level',
                              options: _difficultyOptions,
                              selected: _difficultyLevel,
                              enabled: !_isSubmitting,
                              onChanged: (v) => setState(() => _difficultyLevel = v),
                            ),
                            second: AuthoringChoiceChips(
                              label: 'Complexity level',
                              options: _complexityOptions,
                              selected: _complexityLevel,
                              enabled: !_isSubmitting,
                              onChanged: (v) => setState(() => _complexityLevel = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextField(
                            controller: _timelineController,
                            label: 'Timeline / feasibility',
                            hint: 'e.g. 8 weeks prototype, 6 months MVP',
                            prefixIcon: Icons.schedule_outlined,
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.submissionControls,
                      title: 'Submission Controls',
                      subtitle: 'Idea cap and submission deadline',
                      icon: AppIcons.ideas,
                      iconBg: const Color(0xFFEEF6FF),
                      iconColor: const Color(0xFF1D4ED8),
                      status: _submissionControlsStatus(),
                      child: _buildSubmissionControls(),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.teamRules,
                      title: 'Team Rules',
                      subtitle: 'Minimum and maximum team size',
                      icon: AppIcons.teams,
                      iconBg: const Color(0xFFFFF1E5),
                      iconColor: const Color(0xFFEA580C),
                      status: _teamRulesStatus(),
                      child: _buildTeamRules(),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.techStack,
                      title: 'Preferred Tech Stack',
                      subtitle: 'Technologies you\u2019d like to see in submissions',
                      icon: AppIcons.insights,
                      iconBg: const Color(0xFFF6F0FF),
                      iconColor: const Color(0xFF7C3AED),
                      status: _techStackStatus(),
                      child: AuthoringChipInput(
                        label: 'Preferred technologies',
                        hint: 'Add a technology and press Enter',
                        values: _preferredTechStack,
                        suggestions: _techStackSuggestions,
                        enabled: !_isSubmitting,
                        onChanged: (next) => setState(() => _preferredTechStack = next),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.resources,
                      title: 'Resources & Contact',
                      subtitle: 'Supporting links and how to reach the author',
                      icon: AppIcons.website,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF4338CA),
                      status: _resourcesStatus(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AuthoringPairRow(
                            first: AuthoringTextField(
                              controller: _youtubeController,
                              label: 'YouTube link',
                              hint: 'https://youtube.com/...',
                              prefixIcon: Icons.play_circle_outline,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.url,
                            ),
                            second: AuthoringTextField(
                              controller: _datasetController,
                              label: 'Dataset link',
                              hint: 'https://...',
                              prefixIcon: Icons.dataset_outlined,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.url,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthoringLinkList(
                            label: 'Reference links',
                            hint: 'Add a supporting URL and press Enter',
                            values: _referenceLinks,
                            enabled: !_isSubmitting,
                            onChanged: (next) => setState(() => _referenceLinks = next),
                          ),
                          const SizedBox(height: 12),
                          AuthoringTextField(
                            controller: _contactController,
                            label: 'Contact information',
                            hint: 'Email, phone, or office for questions',
                            prefixIcon: AppIcons.email,
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      id: _AuthoringSectionId.attachments,
                      title: 'Attachments',
                      subtitle: 'Supporting documents, images, or briefs',
                      icon: AppIcons.attachments,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                      status: _attachmentsStatus(),
                      child: AttachmentUploadPreview(
                        files: _attachments,
                        onPickFiles: _pickAttachments,
                        onRemoveFile: (file) => setState(() => _attachments.remove(file)),
                        enabled: !_isSubmitting,
                        uploadButtonLabel: 'Upload supporting files',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        _AuthoringFooter(
          isSubmitting: _isSubmitting,
          isEdit: _isEdit,
          canPublish: _canPublish,
          requiredCompleted: _requiredFieldsCompleted,
          requiredTotal: _requiredFieldsTotal,
          onCancel: _handleBack,
          onPublish: _publish,
        ),
      ],
    );
  }

  ProblemAuthoringSection _buildSection({
    required _AuthoringSectionId id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required AuthoringSectionStatus status,
    required Widget child,
  }) {
    return ProblemAuthoringSection(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      status: status,
      expanded: _expanded.contains(id),
      onToggle: () => _toggleSection(id),
      child: child,
    );
  }

  Widget _buildSubmissionControls() {
    final DateTime? deadline = _ideaSubmissionDeadline;
    final String defaultWindowText = deadline != null
        ? 'Default deadline: one month from now (${formatDayMonthYear(deadline)})'
        : 'Default deadline: one month from now';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthoringPairRow(
          first: AuthoringTextField(
            controller: _maxIdeasController,
            label: 'Max ideas allowed',
            hint: 'e.g. 50 (org limit: $_orgMaxAllowedIdeas)',
            prefixIcon: AppIcons.ideas,
            enabled: !_isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
          ),
          second: AuthoringDeadlinePickerField(
            value: _ideaSubmissionDeadline,
            enabled: !_isSubmitting,
            onChanged: (DateTime? next) => setState(() => _ideaSubmissionDeadline = next),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          defaultWindowText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRules() {
    return AuthoringPairRow(
      first: AuthoringNumberStepperField(
        label: 'Minimum team size',
        value: _minTeamSize,
        min: _orgMinTeamSize,
        max: _orgMaxTeamSize,
        placeholderHint: 'Org default: $_orgMinTeamSize',
        enabled: !_isSubmitting,
        onChanged: (int? v) => setState(() => _minTeamSize = v),
      ),
      second: AuthoringNumberStepperField(
        label: 'Maximum team size',
        value: _maxTeamSize,
        min: _orgMinTeamSize,
        max: _orgMaxTeamSize,
        placeholderHint: 'Org default: $_orgMaxTeamSize',
        enabled: !_isSubmitting,
        onChanged: (int? v) => setState(() => _maxTeamSize = v),
      ),
    );
  }

  Widget _buildClassification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthoringPairRow(
          first: _buildDepartmentSelector(),
          second: AuthoringChoiceChips(
            label: 'Category',
            options: ProblemConstants.categories,
            selected: _selectedCategory,
            enabled: !_isSubmitting,
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        ),
        const SizedBox(height: 12),
        AuthoringTextField(
          controller: _themeController,
          label: 'Theme',
          hint: 'e.g. AI for Social Good, Climate Tech, FinTech',
          prefixIcon: AppIcons.insights,
          enabled: !_isSubmitting,
        ),
        const SizedBox(height: 12),
        AuthoringChipInput(
          label: 'Tags',
          hint: 'Add a tag and press Enter',
          values: _tags,
          enabled: !_isSubmitting,
          onChanged: (next) => setState(() => _tags = next),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelector() {
    if (_isLoadingDepartments) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const <Widget>[
          Text(
            'Department',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(minHeight: 2),
        ],
      );
    }
    if (_isDeptAdmin) {
      final match = _departmentOptions.firstWhere(
        (d) => d['code'] == _selectedDepartment,
        orElse: () => <String, String>{'code': _selectedDepartment, 'name': _selectedDepartment},
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Department',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.departments, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${match['name']} (${match['code']})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDepartment.isEmpty ? null : _selectedDepartment,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B)),
          decoration: InputDecoration(
            hintText: 'Select a department',
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.4),
            ),
          ),
          items: _departmentOptions
              .map(
                (d) => DropdownMenuItem<String>(
                  value: d['code']!,
                  child: Text('${d['name']} (${d['code']})'),
                ),
              )
              .toList(growable: false),
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() => _selectedDepartment = value ?? ''),
        ),
      ],
    );
  }
}

class _AuthoringTopBar extends StatelessWidget {
  const _AuthoringTopBar({
    required this.isEdit,
    required this.isSubmitting,
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.canPublish,
    required this.onBack,
    required this.onPublish,
  });

  final bool isEdit;
  final bool isSubmitting;
  final int requiredCompleted;
  final int requiredTotal;
  final bool canPublish;
  final VoidCallback onBack;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final bool ready = canPublish;
    final String statusLabel = ready
        ? 'Ready to publish'
        : 'Draft · $requiredCompleted/$requiredTotal essentials';
    final Color statusFg = ready ? const Color(0xFF047857) : const Color(0xFF6A38FF);
    final Color statusBg = ready ? const Color(0xFFE6F8EF) : const Color(0xFFEEF2FF);
    final IconData statusIcon =
        ready ? Icons.check_circle_outline_rounded : Icons.edit_note_rounded;
    final bool compact = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 18, 10, compact ? 10 : 18, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFDFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF3))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Back',
            onPressed: isSubmitting ? null : onBack,
            icon: const Icon(AppIcons.back, color: Color(0xFF334155)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  isEdit ? 'Edit Innovation Challenge' : 'Innovation Challenge Authoring',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    'Design a problem statement that inspires innovators',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(statusIcon, size: 14, color: statusFg),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusFg,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...<Widget>[
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: !canPublish || isSubmitting ? null : onPublish,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded, size: 18),
              label: Text(isEdit ? 'Save Problem' : 'Publish Problem'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthoringHero extends StatelessWidget {
  const _AuthoringHero({
    required this.titleController,
    required this.summaryController,
    required this.isActive,
    required this.onActiveChanged,
    required this.enabled,
  });

  final TextEditingController titleController;
  final TextEditingController summaryController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF6F3FF), Color(0xFFEEF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2DAFB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x12273B6A), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'New innovation challenge',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4338CA),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _ActiveSwitch(value: isActive, onChanged: enabled ? onActiveChanged : null),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.15,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.82),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD4DDF1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD4DDF1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
              ),
              hintText: 'What innovation challenge are you creating?',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                height: 1.2,
              ),
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: summaryController,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              height: 1.4,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Add a short tagline or summary...',
              hintStyle: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ActiveSwitch extends StatelessWidget {
  const _ActiveSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Color fg = value ? const Color(0xFF047857) : const Color(0xFF64748B);
    final Color bg = value ? const Color(0xFFE6F8EF) : const Color(0xFFF1F5F9);
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              value ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 5),
            Text(
              value ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthoringFooter extends StatelessWidget {
  const _AuthoringFooter({
    required this.isSubmitting,
    required this.isEdit,
    required this.canPublish,
    required this.requiredCompleted,
    required this.requiredTotal,
    required this.onCancel,
    required this.onPublish,
  });

  final bool isSubmitting;
  final bool isEdit;
  final bool canPublish;
  final int requiredCompleted;
  final int requiredTotal;
  final VoidCallback onCancel;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final bool ready = canPublish;
    final String statusLabel = ready
        ? 'All essentials filled'
        : '$requiredCompleted of $requiredTotal essentials filled';
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 22,
        12,
        compact ? 14 : 22,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Color(0xFFE6EAF3))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Icon(
                  ready ? Icons.check_circle_rounded : Icons.timeline_rounded,
                  size: 16,
                  color: ready ? const Color(0xFF047857) : const Color(0xFF6A38FF),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ready ? const Color(0xFF047857) : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(96, 44),
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFD9E2F5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: !canPublish || isSubmitting ? null : onPublish,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(
              isSubmitting
                  ? (isEdit ? 'Saving...' : 'Publishing...')
                  : (isEdit ? 'Save Problem' : 'Publish Problem'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(160, 44),
              backgroundColor: const Color(0xFF6A38FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
