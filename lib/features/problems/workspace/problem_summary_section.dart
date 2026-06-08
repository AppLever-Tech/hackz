import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../services/problem_status_helpers.dart';
import '../../../utils/common_helpers.dart';
import '../screens/authoring/problem_authoring_section.dart';
import '../widgets/problem_category_chips.dart';
import 'problem_workspace.dart';

/// Read-only problem detail surface used in the workspace and the
/// problem-statement details tab.
///
/// Layout:
///   • Title (always)
///   • Optional meta chips (PS #, department, status) — gated by [showMetaChips]
///   • A non-collapsible "Description" card (matches the authoring "Core
///     Challenge" styling)
///   • Collapsible cards for every other authoring group that has any
///     populated field (innovation context, expected outcomes, constraints,
///     submission controls, team rules, preferred tech stack, classification,
///     resources & contact)
///   • Attachments are intentionally skipped — they're rendered separately
///     by the workspace body / details tab via
///     [WorkspaceAttachmentsPanel].
///
/// All section chrome reuses the same [ProblemAuthoringSection] widget so the
/// read surface and the authoring surface stay visually in sync.
class ProblemSummarySection extends StatefulWidget {
  const ProblemSummarySection({
    super.key,
    required this.vm,
    this.showMetaChips = true,
    this.prominentDescription = false,
    this.workspaceSectionsOnly = false,
  });

  final ProblemWorkspaceViewModel vm;
  final bool showMetaChips;
  final bool prominentDescription;

  /// When true (problem workspace), only the Description card is shown and
  /// its header is collapsible. Elsewhere the description stays always open.
  final bool workspaceSectionsOnly;

  @override
  State<ProblemSummarySection> createState() => _ProblemSummarySectionState();
}

class _ProblemSummarySectionState extends State<ProblemSummarySection> {
  /// Keyed by [_SectionId] enum names. Sections start collapsed so the page
  /// stays scannable; tapping the header expands them in place.
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.workspaceSectionsOnly) {
      _expanded.add(_SectionId.description.name);
    }
  }

  void _toggle(_SectionId id) {
    final String key = id.name;
    setState(() {
      if (_expanded.contains(key)) {
        _expanded.remove(key);
      } else {
        _expanded.add(key);
      }
    });
  }

  bool _isExpanded(_SectionId id) => _expanded.contains(id.name);

  @override
  Widget build(BuildContext context) {
    final p = widget.vm.problem;
    final String title = p.title.trim().isEmpty ? 'Untitled Problem' : p.title.trim();
    final String desc = p.description.trim();

    // Each section's data presence is precomputed so empty groups are
    // skipped entirely (no empty cards rendered for problems that haven't
    // been fully authored).
    final bool workspaceOnly = widget.workspaceSectionsOnly;
    final bool hasInnovation = !workspaceOnly &&
        (p.background.trim().isNotEmpty ||
        p.impact.trim().isNotEmpty ||
        p.stakeholders.trim().isNotEmpty ||
        p.researchContext.trim().isNotEmpty);
    final bool hasOutcomes = !workspaceOnly &&
        (p.expectedSolution.trim().isNotEmpty ||
        p.successCriteria.trim().isNotEmpty ||
        p.expectedDeliverables.trim().isNotEmpty ||
        p.suggestedTechnologies.isNotEmpty);
    final bool hasConstraints = !workspaceOnly &&
        (p.constraints.trim().isNotEmpty ||
        p.difficultyLevel.trim().isNotEmpty ||
        p.complexityLevel.trim().isNotEmpty ||
        p.timeline.trim().isNotEmpty);
    final bool hasSubmissionControls = !workspaceOnly &&
        (p.maxIdeasAllowed != null || p.ideaSubmissionDeadline != null);
    final bool hasTeamRules =
        !workspaceOnly && (p.minTeamSize != null || p.maxTeamSize != null);
    final bool hasTechStack = !workspaceOnly && p.preferredTechStack.isNotEmpty;
    final bool hasClassification = !workspaceOnly &&
        (p.category.trim().isNotEmpty ||
            p.theme.trim().isNotEmpty ||
            p.departmentDisplayName.trim().isNotEmpty ||
            p.tags.isNotEmpty);
    final bool hasResources = !workspaceOnly &&
        (p.youtubeLink.trim().isNotEmpty ||
        p.datasetLink.trim().isNotEmpty ||
        p.referenceLinks.isNotEmpty ||
        p.contactInformation.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
          ),
        ),
        if (widget.showMetaChips) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(AppIcons.problems,
                  p.problemNumber.trim().isEmpty ? p.problemId : p.problemNumber),
              _chip(AppIcons.departments, p.departmentDisplayName),
              _chip(
                ProblemStatusHelpers.icon(p.status),
                ProblemStatusHelpers.label(p.status),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        ProblemAuthoringSection(
          title: 'Description',
          subtitle: 'What the problem is and why it matters',
          icon: AppIcons.problems,
          iconBg: const Color(0xFFFFF1E5),
          iconColor: const Color(0xFFEA580C),
          status: const AuthoringSectionStatus(completed: 0, total: 0),
          collapsible: workspaceOnly,
          expanded: workspaceOnly ? _isExpanded(_SectionId.description) : true,
          onToggle: workspaceOnly ? () => _toggle(_SectionId.description) : () {},
          child: _DescriptionBody(
            description: desc,
            prominent: widget.prominentDescription,
          ),
        ),
        if (hasInnovation) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Innovation Context',
            subtitle: 'Background, impact, and stakeholders',
            icon: AppIcons.insights,
            iconBg: const Color(0xFFE9F1FF),
            iconColor: const Color(0xFF2563EB),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.innovation),
            onToggle: () => _toggle(_SectionId.innovation),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailValueBlock(label: 'Background', value: p.background),
                _DetailValueBlock(
                    label: 'Why this needs to be solved / Impact', value: p.impact),
                _DetailValueBlock(
                    label: 'Stakeholders / Beneficiaries', value: p.stakeholders),
                _DetailValueBlock(
                    label: 'Supporting data / Research context',
                    value: p.researchContext),
              ],
            ),
          ),
        ],
        if (hasOutcomes) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Expected Outcomes',
            subtitle: 'Solution direction, success criteria, deliverables',
            icon: AppIcons.ideas,
            iconBg: const Color(0xFFF6F0FF),
            iconColor: const Color(0xFF7C3AED),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.outcomes),
            onToggle: () => _toggle(_SectionId.outcomes),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailValueBlock(
                    label: 'Expected solution direction', value: p.expectedSolution),
                _DetailValueBlock(
                    label: 'Success criteria', value: p.successCriteria),
                _DetailValueBlock(
                    label: 'Expected deliverables', value: p.expectedDeliverables),
                if (p.suggestedTechnologies.isNotEmpty)
                  _DetailChipBlock(
                      label: 'Suggested technologies',
                      values: p.suggestedTechnologies),
              ],
            ),
          ),
        ],
        if (hasConstraints) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Constraints & Feasibility',
            subtitle: 'Real-world limits, difficulty, and timeline',
            icon: AppIcons.info,
            iconBg: const Color(0xFFFEF3E6),
            iconColor: const Color(0xFFD97706),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.constraints),
            onToggle: () => _toggle(_SectionId.constraints),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailValueBlock(
                    label: 'Constraints / Limitations', value: p.constraints),
                _DetailValueBlock(label: 'Difficulty level', value: p.difficultyLevel),
                _DetailValueBlock(label: 'Complexity level', value: p.complexityLevel),
                _DetailValueBlock(label: 'Timeline / feasibility', value: p.timeline),
              ],
            ),
          ),
        ],
        if (hasSubmissionControls) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Submission Controls',
            subtitle: 'Idea cap and submission deadline',
            icon: AppIcons.ideas,
            iconBg: const Color(0xFFEEF6FF),
            iconColor: const Color(0xFF1D4ED8),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.submissionControls),
            onToggle: () => _toggle(_SectionId.submissionControls),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (p.maxIdeasAllowed != null)
                  _DetailValueBlock(
                    label: 'Max ideas allowed',
                    value: '${p.maxIdeasAllowed}',
                  ),
                if (p.ideaSubmissionDeadline != null)
                  _DetailValueBlock(
                    label: 'Idea submission deadline',
                    value: formatDayMonthYear(p.ideaSubmissionDeadline!),
                  ),
              ],
            ),
          ),
        ],
        if (hasTeamRules) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Team Rules',
            subtitle: 'Minimum and maximum team size',
            icon: AppIcons.teams,
            iconBg: const Color(0xFFFFF1E5),
            iconColor: const Color(0xFFEA580C),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.teamRules),
            onToggle: () => _toggle(_SectionId.teamRules),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (p.minTeamSize != null)
                  _DetailValueBlock(
                      label: 'Minimum team size', value: '${p.minTeamSize}'),
                if (p.maxTeamSize != null)
                  _DetailValueBlock(
                      label: 'Maximum team size', value: '${p.maxTeamSize}'),
              ],
            ),
          ),
        ],
        if (hasTechStack) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Preferred Tech Stack',
            subtitle: 'Technologies you’d like to see in submissions',
            icon: AppIcons.insights,
            iconBg: const Color(0xFFF6F0FF),
            iconColor: const Color(0xFF7C3AED),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.techStack),
            onToggle: () => _toggle(_SectionId.techStack),
            child: _DetailChipBlock(
              label: 'Preferred technologies',
              values: p.preferredTechStack,
            ),
          ),
        ],
        if (hasClassification) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Classification',
            subtitle: 'Department, category, theme, and tags',
            icon: AppIcons.orgType,
            iconBg: const Color(0xFFE6F8EF),
            iconColor: const Color(0xFF047857),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.classification),
            onToggle: () => _toggle(_SectionId.classification),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailValueBlock(label: 'Department', value: p.departmentDisplayName),
                _DetailCategoryField(selected: p.category),
                _DetailValueBlock(label: 'Theme', value: p.theme),
                if (p.tags.isNotEmpty)
                  _DetailChipBlock(label: 'Tags', values: p.tags),
              ],
            ),
          ),
        ],
        if (hasResources) ...<Widget>[
          const SizedBox(height: 12),
          ProblemAuthoringSection(
            title: 'Resources & Contact',
            subtitle: 'Supporting links and how to reach the author',
            icon: AppIcons.website,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4338CA),
            status: const AuthoringSectionStatus(completed: 0, total: 0),
            expanded: _isExpanded(_SectionId.resources),
            onToggle: () => _toggle(_SectionId.resources),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailValueBlock(label: 'YouTube link', value: p.youtubeLink),
                _DetailValueBlock(label: 'Dataset link', value: p.datasetLink),
                if (p.referenceLinks.isNotEmpty)
                  _DetailChipBlock(
                      label: 'Reference links', values: p.referenceLinks),
                _DetailValueBlock(
                    label: 'Contact information', value: p.contactInformation),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _chip(IconData icon, String text) {
    final String value = text.trim().isEmpty ? '—' : text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF57629A)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stable identifier per collapsible section so the expanded-state set stays
/// stable across rebuilds.
enum _SectionId {
  description,
  innovation,
  outcomes,
  constraints,
  submissionControls,
  teamRules,
  techStack,
  classification,
  resources,
}

/// Renders the problem description as a paragraph. Honours
/// [ProblemSummarySection.prominentDescription] so the details tab gets a
/// larger, never-truncated body while the workspace summary keeps a more
/// compact preview.
class _DescriptionBody extends StatelessWidget {
  const _DescriptionBody({required this.description, required this.prominent});

  final String description;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      description,
      maxLines: prominent ? null : 8,
      overflow: prominent ? TextOverflow.visible : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: prominent ? 15 : 13,
        height: prominent ? 1.55 : 1.45,
        color: const Color(0xFF1E293B),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Label + Software/Hardware chip row for the classification section.
class _DetailCategoryField extends StatelessWidget {
  const _DetailCategoryField({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 900;
    final double labelWidth = compact ? 170 : 220;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: const Text(
              'Category',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProblemCategoryChips(selected: selected, compact: compact),
          ),
        ],
      ),
    );
  }
}

/// Label + multi-line value block used inside every read-only section card.
/// Empty values short-circuit to `SizedBox.shrink` so the caller doesn't
/// need to gate each row.
class _DetailValueBlock extends StatelessWidget {
  const _DetailValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    final bool compact = MediaQuery.sizeOf(context).width < 900;
    final double labelWidth = compact ? 170 : 220;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trimmed,
              softWrap: true,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label + wrapped chip row used for chip-list fields (suggested technologies,
/// preferred tech stack, tags, reference links).
class _DetailChipBlock extends StatelessWidget {
  const _DetailChipBlock({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (v) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      v,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
