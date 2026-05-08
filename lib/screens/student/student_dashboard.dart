import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/attachment_model.dart';
import '../../models/enums/team_status.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../../utils/student_dashboard_service.dart';
import '../../widgets/attachment_viewer.dart';
import '../../widgets/student_team_overview_card.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<String>('results_$refreshToken'),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.student, user),
          );
        }
        return _StudentDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _StudentDashboardHome extends StatefulWidget {
  const _StudentDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_StudentDashboardHome> createState() => _StudentDashboardHomeState();
}

class _StudentDashboardHomeState extends State<_StudentDashboardHome> {
  late Future<StudentDashboardVm> _future;
  final StudentDashboardService _service = StudentDashboardService();
  int _activityLimit = 8;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentDashboardVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load student dashboard: ${snapshot.error}');
        }
        final vm = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(vm),
              const SizedBox(height: 16),
              _buildStatusAndDetailsRow(vm),
              const SizedBox(height: 16),
              StudentTeamOverviewCard(vm: vm),
              const SizedBox(height: 16),
              _buildIdeasSection(vm),
              const SizedBox(height: 16),
              _buildPaymentsAndEvaluation(vm),
              const SizedBox(height: 16),
              _buildRecentActivity(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(StudentDashboardVm vm) {
    const spacing = 16.0;
    return LayoutBuilder(
      builder: (_, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = (maxWidth / 260).floor().clamp(1, 4);
        final cardWidth = (maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: cardWidth,
              child: DashboardCountCard(
                value: '${vm.teamMemberCount}',
                label: 'Members • ${vm.team.teamName.isEmpty ? 'No Team' : vm.team.teamName}',
                icon: AppIcons.teams,
                iconBgColor: const Color(0xFFEAF2FF),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardIconMetricCard(
                metrics: <DashboardIconMetric>[
                  DashboardIconMetric(
                    icon: AppIcons.statusSubmitted,
                    tooltip: 'Submitted',
                    count: '${vm.submittedIdeas}',
                    color: StatusStyles.submitted,
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusApproved,
                    tooltip: 'Approved',
                    count: '${vm.approvedIdeas}',
                    color: StatusStyles.approved,
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusRejected,
                    tooltip: 'Rejected',
                    count: '${vm.rejectedIdeas}',
                    color: StatusStyles.rejected,
                  ),
                ],
                label: 'Ideas',
                icon: AppIcons.ideas,
                iconBgColor: const Color(0xFFF2EDFF),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCountCard(
                value: vm.avgScore?.toStringAsFixed(1) ?? '-',
                secondaryValue: vm.highestScore?.toStringAsFixed(1) ?? '-',
                label: 'Avg / Highest Score',
                icon: AppIcons.scoring,
                iconBgColor: const Color(0xFFE8FAF1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardIconMetricCard(
                metrics: <DashboardIconMetric>[
                  DashboardIconMetric(
                    icon: AppIcons.statusSubmitted,
                    tooltip: 'Pending',
                    count: '${vm.pendingPayments}',
                    color: const Color(0xFFB56A11),
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusApproved,
                    tooltip: 'Verified',
                    count: '${vm.verifiedPayments}',
                    color: const Color(0xFF177C50),
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusRejected,
                    tooltip: 'Rejected',
                    count: '${vm.rejectedPayments}',
                    color: const Color(0xFFB93838),
                  ),
                ],
                label: 'Payments',
                icon: AppIcons.payments,
                iconBgColor: const Color(0xFFFFF4E8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusAndDetailsRow(StudentDashboardVm vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 252,
            child: _buildStudentDetails(vm),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 252,
            child: ChartCard(
              title: 'Idea Status Distribution',
              child: SizedBox(
                height: 188,
                child: _StudentIdeaStatusDonut(vm: vm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDetails(StudentDashboardVm vm) {
    return ChartCard(
      title: 'Student Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _detailRow(icon: AppIcons.student, label: 'Student', value: vm.studentName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Department', value: vm.department),
          const SizedBox(height: 8),
          _detailRow(
            icon: AppIcons.teams,
            label: 'Team',
            value: vm.team.teamName.isEmpty ? '-' : vm.team.teamName,
          ),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.faculty, label: 'Mentor', value: vm.mentorName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Dept Admin', value: vm.departmentAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'College Admin', value: vm.collegeAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'Organization', value: vm.organizationName),
        ],
      ),
    );
  }

  Widget _buildIdeasSection(StudentDashboardVm vm) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Team & Idea Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (vm.ideaCards.isEmpty)
            const Text('No ideas found for your team yet.')
          else
            ...vm.ideaCards.take(6).map((item) => _ideaCard(item)),
        ],
      ),
    );
  }

  Widget _ideaCard(StudentIdeaItem item) {
    final payment = item.payment;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.idea.problemTitle.isEmpty ? item.idea.problemNumber : item.idea.problemTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(item.idea.status),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _miniChip('${item.idea.problemNumber} • ${item.problemDepartment}', AppIcons.problems),
              _miniChip('Payment: ${_paymentLabel(payment?.status)}', AppIcons.payments),
              _miniChip(
                'Score: ${item.latestScore == null ? '-' : item.latestScore!.score.toStringAsFixed(1)}',
                AppIcons.scoring,
              ),
              _miniChip('Attachments: ${item.attachmentCount}', AppIcons.attachments),
            ],
          ),
          if (item.feedbackSummary.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.feedbackSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF4D567F)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: () => _showIdeaDetails(item),
                child: const Text('View Idea Details'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: item.feedbackSummary.trim().isEmpty ? null : () => _showFeedback(item),
                child: const Text('View Feedback'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showIdeaAttachments(item.idea.ideaId),
                child: const Text('View Attachments'),
              ),
              const Spacer(),
              Text(
                _formatDate(item.idea.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsAndEvaluation(StudentDashboardVm vm) {
    final paymentRows = vm.ideaCards
        .where((i) => i.payment != null)
        .map((i) => i.payment!)
        .toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SectionContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (paymentRows.isEmpty)
                  const Text('No payments yet.')
                else
                  ...paymentRows.take(5).map(
                    (p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF8FAFF),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${p.problemNumber} • ${p.amount.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _paymentChip(p.status),
                          const SizedBox(width: 8),
                          _miniChip(
                            'Shot: ${vm.paymentAttachmentCounts[p.paymentId] ?? 0}',
                            AppIcons.attachments,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SectionContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Feedback & Evaluation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...vm.ideaCards.where((i) => i.latestScore != null).take(5).map(
                  (i) => ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(i.idea.problemTitle.isEmpty ? i.idea.problemNumber : i.idea.problemTitle),
                    subtitle: Text('Rating: ${i.latestScore!.score.toStringAsFixed(1)} / 10'),
                    childrenPadding: const EdgeInsets.only(bottom: 10),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          i.feedbackSummary.trim().isEmpty ? 'No feedback summary.' : i.feedbackSummary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.ideaCards.where((i) => i.latestScore != null).isEmpty)
                  const Text('No evaluations received yet.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(StudentDashboardVm vm) {
    final visible = vm.activities.take(_activityLimit).toList(growable: false);
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('No recent activity.')
          else
            ...visible.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Icon(a.icon, size: 18, color: const Color(0xFF4B5AA9)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.text)),
                    Text(
                      _formatDate(a.at),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
                    ),
                  ],
                ),
              ),
            ),
          if (_activityLimit < vm.activities.length)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _activityLimit += 8),
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(IdeaStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StatusStyles.colorForIdeaStatus(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(StatusStyles.iconForIdeaStatus(status), size: 14, color: StatusStyles.colorForIdeaStatus(status)),
          const SizedBox(width: 4),
          Text(
            _ideaStatusLabel(status),
            style: TextStyle(
              fontSize: 11,
              color: StatusStyles.colorForIdeaStatus(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: const Color(0xFF4F5A89)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _paymentChip(PaymentRecordStatus status) {
    final color = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFB56A11),
      PaymentRecordStatus.verified => const Color(0xFF177C50),
      PaymentRecordStatus.rejected => const Color(0xFFB93838),
    };
    final bg = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFFFF1E4),
      PaymentRecordStatus.verified => const Color(0xFFE7F9F1),
      PaymentRecordStatus.rejected => const Color(0xFFFDECEC),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(
        _paymentLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 22,
          child: Icon(icon, size: 16, color: const Color(0xFF57629A)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B556A), fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF4B556A))),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _showIdeaAttachments(String ideaId) async {
    final attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.idea,
      entityId: ideaId,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AttachmentViewerDialog(
        title: 'Idea Attachments',
        attachments: attachments,
      ),
    );
  }

  Future<void> _showIdeaDetails(StudentIdeaItem item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.idea.problemTitle.isEmpty ? 'Idea Details' : item.idea.problemTitle),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Problem: ${item.idea.problemNumber}'),
              const SizedBox(height: 6),
              Text('Department: ${item.problemDepartment}'),
              const SizedBox(height: 6),
              Text('Status: ${_ideaStatusLabel(item.idea.status)}'),
              const SizedBox(height: 10),
              Text(item.idea.description.isEmpty ? '-' : item.idea.description),
            ],
          ),
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showFeedback(StudentIdeaItem item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Feedback'),
        content: SizedBox(
          width: 520,
          child: Text(item.feedbackSummary.trim().isEmpty ? 'No feedback available.' : item.feedbackSummary),
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _ideaStatusLabel(IdeaStatus status) {
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

  String _paymentLabel(PaymentRecordStatus? status) {
    if (status == null) return '-';
    switch (status) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.verified:
        return 'Verified';
      case PaymentRecordStatus.rejected:
        return 'Rejected';
    }
  }
}

class _StudentIdeaStatusDonut extends StatelessWidget {
  const _StudentIdeaStatusDonut({required this.vm});

  final StudentDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    final total = (vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas + vm.approvedOrRejectedIdeas).clamp(1, 1 << 20);
    return Row(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.78,
            child: CustomPaint(
              painter: _StudentDonutPainter(
                pendingPct: vm.pendingIdeas / total,
                submittedPct: vm.submittedIdeas / total,
                reviewPct: vm.reviewIdeas / total,
                donePct: vm.approvedOrRejectedIdeas / total,
              ),
              child: Center(
                child: Text('${vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas + vm.approvedOrRejectedIdeas}'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LegendRow(color: StatusStyles.submitted, text: 'Pending ${vm.pendingIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: const Color(0xFF5C6BC0), text: 'Submitted ${vm.submittedIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.underReview, text: 'Under Review ${vm.reviewIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.approved, text: 'Approved/Rejected ${vm.approvedOrRejectedIdeas}'),
            ],
          ),
        ),
      ],
    );
  }
}


class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StudentDonutPainter extends CustomPainter {
  _StudentDonutPainter({
    required this.pendingPct,
    required this.submittedPct,
    required this.reviewPct,
    required this.donePct,
  });

  final double pendingPct;
  final double submittedPct;
  final double reviewPct;
  final double donePct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.shortestSide * 0.31);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    double start = -1.57;

    void arc(double value, Color color) {
      if (value <= 0) return;
      final sweep = 6.28318530718 * value;
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    arc(pendingPct, StatusStyles.submitted);
    arc(submittedPct, const Color(0xFF5C6BC0));
    arc(reviewPct, StatusStyles.underReview);
    arc(donePct, StatusStyles.approved);
  }

  @override
  bool shouldRepaint(covariant _StudentDonutPainter oldDelegate) {
    return oldDelegate.pendingPct != pendingPct ||
        oldDelegate.submittedPct != submittedPct ||
        oldDelegate.reviewPct != reviewPct ||
        oldDelegate.donePct != donePct;
  }
}

