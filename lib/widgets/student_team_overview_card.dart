import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../constants/status_styles.dart';
import '../models/enums/team_status.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../utils/common_helpers.dart';
import '../utils/student_dashboard_service.dart';
import '../screens/common/dashboard_components.dart';
import '../workspace/workspace.dart';

class StudentTeamOverviewCard extends StatelessWidget {
  const StudentTeamOverviewCard({
    super.key,
    required this.vm,
  });

  final StudentDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    final ideas = vm.ideaCards;
    final activeIdeas = ideas
        .where((i) => i.idea.status != IdeaStatus.approved && i.idea.status != IdeaStatus.rejected)
        .length;
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('My Team Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (vm.team.teamId.isEmpty)
            _emptyState('No team assigned yet.')
          else ...<Widget>[
            _header(context, activeIdeas: activeIdeas),
            const SizedBox(height: 10),
            _membersRow(context),
            const SizedBox(height: 10),
            _ideasBlock(),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, {required int activeIdeas}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAF2FF),
            child: const Icon(AppIcons.teams, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: vm.team.teamId.trim().isEmpty
                            ? null
                            : () => WorkspaceNavigator.openTeam(context, vm.team.teamId),
                        child: Text(
                          vm.team.teamName.isEmpty ? 'Team' : vm.team.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                      ),
                    ),
                    _teamStatusPill(vm.team.status),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _mini('Department', vm.department),
                    _mini(
                      'Mentor',
                      vm.mentorName,
                      onTap: vm.mentorId.trim().isEmpty
                          ? null
                          : () => WorkspaceNavigator.openUser(context, vm.mentorId),
                    ),
                    _mini('Members', '${vm.teamMembers.length}'),
                    _mini('Active Ideas', '$activeIdeas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersRow(BuildContext context) {
    if (vm.teamMembers.isEmpty) return _emptyState('No team members found.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Team Members', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: vm.teamMembers.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final name = '${m.firstName} ${m.lastName}'.trim().isEmpty ? m.userId : '${m.firstName} ${m.lastName}'.trim();
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFFDCE6FF),
                      child: Text(
                        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => WorkspaceNavigator.openUser(context, m.userId),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (idx == 0) ...<Widget>[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFB56A11)),
                    ],
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _ideasBlock() {
    if (vm.ideaCards.isEmpty) return _emptyState('No ideas submitted by this team yet.');
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 4),
      title: const Text('Idea Progress', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${vm.ideaCards.length} ideas'),
      children: vm.ideaCards
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : item.idea.ideaTitle.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.problemDepartment,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5B628A)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: <Widget>[
                            _ideaPill(item.idea.status),
                            _paymentPill(item.payment?.status),
                            _scoreBadge(item),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(item.idea.createdAt),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6E7394)),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _scoreBadge(StudentIdeaItem item) {
    final evaluated = item.latestScore != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: evaluated ? const Color(0xFFE7F9F1) : const Color(0xFFF2F4FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        evaluated
            ? 'Score ${item.latestScore!.score.toStringAsFixed(1)} • ${item.scoreCount} judge(s)'
            : 'Not evaluated',
        style: TextStyle(
          fontSize: 11,
          color: evaluated ? const Color(0xFF177C50) : const Color(0xFF5F678E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ideaPill(IdeaStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StatusStyles.colorForIdeaStatus(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(StatusStyles.iconForIdeaStatus(status), size: 12, color: StatusStyles.colorForIdeaStatus(status)),
          const SizedBox(width: 4),
          Text(_ideaLabel(status), style: TextStyle(fontSize: 11, color: StatusStyles.colorForIdeaStatus(status))),
        ],
      ),
    );
  }

  Widget _paymentPill(PaymentRecordStatus? status) {
    final label = switch (status) {
      PaymentRecordStatus.pending => 'Payment Pending',
      PaymentRecordStatus.verified => 'Payment Verified',
      PaymentRecordStatus.rejected => 'Payment Rejected',
      null => 'Payment -',
    };
    final color = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFB56A11),
      PaymentRecordStatus.verified => const Color(0xFF177C50),
      PaymentRecordStatus.rejected => const Color(0xFFB93838),
      null => const Color(0xFF5B628A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _teamStatusPill(TeamStatus status) {
    final color = switch (status) {
      TeamStatus.active => const Color(0xFF177C50),
      TeamStatus.inactive => const Color(0xFFB93838),
      TeamStatus.locked => const Color(0xFFB56A11),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(status.value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _mini(String label, String value, {VoidCallback? onTap}) {
    final String text = '$label: ${value.trim().isEmpty ? '-' : value}';
    if (onTap == null) {
      return Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF5B628A)),
      );
    }
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF5B628A))),
    );
  }

  String _ideaLabel(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return 'Pending';
      case IdeaStatus.submitted:
        return 'Submitted';
      case IdeaStatus.underReview:
        return 'Under Review';
      case IdeaStatus.evaluated:
        return 'Evaluated';
      case IdeaStatus.approved:
        return 'Approved';
      case IdeaStatus.rejected:
        return 'Rejected';
    }
  }

  String _fmt(DateTime d) {
    return formatDateTime(d);
  }
}
