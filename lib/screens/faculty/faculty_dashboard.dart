import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'teams_screen.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return TeamsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.faculty, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.faculty, user),
          );
        }
        return _FacultyDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _FacultyDashboardHome extends StatefulWidget {
  const _FacultyDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_FacultyDashboardHome> createState() => _FacultyDashboardHomeState();
}

class _FacultyDashboardHomeState extends State<_FacultyDashboardHome> {
  static const double _kDashboardIconSize = 18;
  late Future<_FacultyDashboardVm> _future;
  int _activityLimit = 8;

  @override
  void initState() {
    super.initState();
    _future = _FacultyDashboardService().load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FacultyDashboardVm>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<_FacultyDashboardVm> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load faculty dashboard: ${snapshot.error}');
        }
        final vm = snapshot.data ?? _FacultyDashboardVm.empty;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(vm),
              const SizedBox(height: 16),
              _buildCharts(vm),
              const SizedBox(height: 16),
              _buildKeyCards(context, vm),
              const SizedBox(height: 16),
              _buildRecentActivity(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(_FacultyDashboardVm vm) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        _MetricComboCard(
          icon: AppIcons.users,
          title: 'Teams & Students',
          stats: <_MetricStat>[
            _MetricStat(
              icon: AppIcons.teams,
              count: vm.teamCount,
              tooltip: 'Teams',
              color: const Color(0xFF1E88E5),
            ),
            _MetricStat(
              icon: AppIcons.student,
              count: vm.studentCount,
              tooltip: 'Students',
              color: const Color(0xFF2E7D32),
            ),
          ],
          iconBgColor: const Color(0xFFEAF2FF),
        ),
        _MetricComboCard(
          icon: AppIcons.ideas,
          title: 'Ideas',
          stats: <_MetricStat>[
            _MetricStat(
              icon: AppIcons.statusSubmitted,
              count: vm.submittedIdeas,
              tooltip: 'Submitted',
              color: StatusStyles.submitted,
            ),
            _MetricStat(
              icon: AppIcons.statusUnderReview,
              count: vm.underReviewIdeas,
              tooltip: 'Under Review',
              color: StatusStyles.underReview,
            ),
            _MetricStat(
              icon: AppIcons.statusEvaluated,
              count: vm.evaluatedIdeas,
              tooltip: 'Evaluated',
              color: StatusStyles.evaluated,
            ),
          ],
          iconBgColor: const Color(0xFFF2EDFF),
        ),
        _MetricComboCard(
          icon: AppIcons.problems,
          title: 'Problems',
          stats: <_MetricStat>[
            _MetricStat(
              icon: AppIcons.problems,
              count: vm.departmentProblemCount,
              tooltip: 'Dept Problems',
              color: const Color(0xFFC62828),
            ),
            _MetricStat(
              icon: AppIcons.ideas,
              count: vm.ideaCount,
              tooltip: 'Ideas Count',
              color: StatusStyles.evaluated,
            ),
          ],
          iconBgColor: const Color(0xFFE8FAF1),
        ),
      ],
    );
  }

  Widget _buildCharts(_FacultyDashboardVm vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ChartCard(
            title: 'Idea Status',
            child: SizedBox(
              height: 210,
              child: _IdeaStatusDonut(vm: vm),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ChartCard(
            title: 'Submissions Over Time',
            child: SizedBox(
              height: 210,
              child: _SubmissionTrendChart(series: vm.submissionsByDay),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyCards(BuildContext context, _FacultyDashboardVm vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _KeyDataCard(
            title: 'My Teams',
            teamPreview: vm.teams.take(3).toList(growable: false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KeyDataCard(
            title: 'My Problems',
            preview: vm.problemPreview,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KeyDataCard(
            title: 'My Ideas',
            preview: vm.ideaPreview,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(_FacultyDashboardVm vm) {
    final visible = vm.activities.take(_activityLimit).toList(growable: false);
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('No recent activity.')
          else
            ...visible.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Icon(a.icon, size: _kDashboardIconSize, color: a.color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.text)),
                    Text(
                      _formatDate(a.time),
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

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FacultyDashboardService {
  Future<_FacultyDashboardVm> load(UserModel user) async {
    final db = FirebaseFirestore.instance;
    final departmentCode = user.departmentCode.trim().toUpperCase();
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.getFacultyTeams(user.userId),
      db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: user.orgId).get(),
      db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: user.orgId).get(),
      db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: user.orgId).get(),
    ]);

    final teams = results[0] as List<TeamModel>;
    final ideaDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final userDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;

    final teamIds = teams.map((t) => t.teamId).where((id) => id.isNotEmpty).toSet();
    final studentIds = <String>{};
    for (final team in teams) {
      studentIds.addAll(team.studentIds.where((id) => id.isNotEmpty));
    }

    final ideas = ideaDocs
        .where((d) {
          final m = d.data();
          final dept = ((m['departmentCode'] as String?) ?? '').trim().toUpperCase();
          final teamId = ((m['teamId'] as String?) ?? '').trim();
          return dept == departmentCode && teamIds.contains(teamId);
        })
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .toList(growable: false);

    final departmentProblems = problemDocs.where((d) {
      final m = d.data();
      final dept = ((m['departmentCode'] as String?) ?? '').trim().toUpperCase();
      return dept == departmentCode;
    }).toList(growable: false);

    final usersById = <String, Map<String, dynamic>>{};
    for (final u in userDocs) {
      usersById[u.id] = u.data();
    }

    int submitted = 0;
    int underReview = 0;
    int evaluated = 0;
    for (final idea in ideas) {
      switch (idea.status) {
        case IdeaStatus.evaluated:
          evaluated++;
          break;
        case IdeaStatus.underReview:
          underReview++;
          break;
        default:
          submitted++;
      }
    }

    final byDay = <String, int>{};
    for (final idea in ideas) {
      final key =
          '${idea.createdAt.year}-${idea.createdAt.month.toString().padLeft(2, '0')}-${idea.createdAt.day.toString().padLeft(2, '0')}';
      byDay[key] = (byDay[key] ?? 0) + 1;
    }
    final sortedDays = byDay.keys.toList(growable: false)..sort();
    final submissionsByDay = <String, int>{for (final day in sortedDays.take(7)) day.substring(5): byDay[day] ?? 0};

    final teamNameById = <String, String>{
      for (final t in teams) t.teamId: (t.teamName.isEmpty ? t.teamId : t.teamName)
    };

    final activities = <_ActivityItem>[
      ...ideas.map((i) {
        final icon = StatusStyles.iconForIdeaStatus(i.status);
        final color = StatusStyles.colorForIdeaStatus(i.status);
        final text = i.status == IdeaStatus.evaluated
            ? 'Idea evaluated in ${teamNameById[i.teamId] ?? i.teamId}'
            : i.status == IdeaStatus.underReview
                ? 'Idea under review from ${teamNameById[i.teamId] ?? i.teamId}'
                : 'Idea submitted by ${teamNameById[i.teamId] ?? i.teamId}';
        return _ActivityItem(icon: icon, color: color, text: text, time: i.createdAt);
      }),
      ...teams.map(
        (t) => _ActivityItem(
          icon: AppIcons.users,
          color: const Color(0xFF6E7394),
          text: 'Team created: ${t.teamName.isEmpty ? t.teamId : t.teamName}',
          time: t.createdAt,
        ),
      ),
      ...ideas
          .where((i) => i.status == IdeaStatus.pendingSubmission)
          .map(
            (i) => _ActivityItem(
              icon: AppIcons.payments,
              color: StatusStyles.submitted,
              text: 'Payment pending for ${teamNameById[i.teamId] ?? i.teamId}',
              time: i.createdAt,
            ),
          ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    return _FacultyDashboardVm(
      teams: teams,
      teamCount: teams.length,
      studentCount: studentIds.length,
      ideaCount: ideas.length,
      submittedIdeas: submitted,
      underReviewIdeas: underReview,
      evaluatedIdeas: evaluated,
      departmentProblemCount: departmentProblems.length,
      submissionsByDay: submissionsByDay,
      problemPreview: departmentProblems
          .take(3)
          .map((p) => ((p.data()['title'] as String?) ?? 'Untitled problem').trim())
          .toList(growable: false),
      ideaPreview: ideas
          .take(3)
          .map((i) => i.problemTitle.isEmpty ? i.description : i.problemTitle)
          .toList(growable: false),
      activities: activities.take(40).toList(growable: false),
      usersById: usersById,
    );
  }
}

class _FacultyDashboardVm {
  const _FacultyDashboardVm({
    required this.teams,
    required this.teamCount,
    required this.studentCount,
    required this.ideaCount,
    required this.submittedIdeas,
    required this.underReviewIdeas,
    required this.evaluatedIdeas,
    required this.departmentProblemCount,
    required this.submissionsByDay,
    required this.problemPreview,
    required this.ideaPreview,
    required this.activities,
    required this.usersById,
  });

  static const empty = _FacultyDashboardVm(
    teams: <TeamModel>[],
    teamCount: 0,
    studentCount: 0,
    ideaCount: 0,
    submittedIdeas: 0,
    underReviewIdeas: 0,
    evaluatedIdeas: 0,
    departmentProblemCount: 0,
    submissionsByDay: <String, int>{},
    problemPreview: <String>[],
    ideaPreview: <String>[],
    activities: <_ActivityItem>[],
    usersById: <String, Map<String, dynamic>>{},
  );

  final List<TeamModel> teams;
  final int teamCount;
  final int studentCount;
  final int ideaCount;
  final int submittedIdeas;
  final int underReviewIdeas;
  final int evaluatedIdeas;
  final int departmentProblemCount;
  final Map<String, int> submissionsByDay;
  final List<String> problemPreview;
  final List<String> ideaPreview;
  final List<_ActivityItem> activities;
  final Map<String, Map<String, dynamic>> usersById;
}

class _MetricComboCard extends StatelessWidget {
  static const double _kIconSize = 18;

  const _MetricComboCard({
    required this.icon,
    required this.title,
    required this.stats,
    required this.iconBgColor,
  });

  final IconData icon;
  final String title;
  final List<_MetricStat> stats;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: SectionContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: Icon(icon, size: _kIconSize),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: Row(
                children: stats
                    .map(
                      (stat) => Expanded(
                        child: Tooltip(
                          message: stat.tooltip,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(stat.icon, size: _kIconSize, color: stat.color),
                              const SizedBox(width: 6),
                              Text(
                                '${stat.count}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: stat.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricStat {
  const _MetricStat({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final Color color;
}

class _KeyDataCard extends StatelessWidget {
  const _KeyDataCard({
    required this.title,
    this.preview = const <String>[],
    this.teamPreview = const <TeamModel>[],
  });

  final String title;
  final List<String> preview;
  final List<TeamModel> teamPreview;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (preview.isEmpty && teamPreview.isEmpty)
            const Text('-', style: TextStyle(color: Color(0xFF6E7394)))
          else if (title == 'My Teams' && teamPreview.isNotEmpty)
            ...teamPreview.map(
              (team) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        team.teamName.isEmpty ? team.teamId : team.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Icon(
                          AppIcons.student,
                          size: _FacultyDashboardHomeState._kDashboardIconSize,
                          color: const Color(0xFF4A4F73),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${team.studentIds.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A4F73),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            ...preview.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdeaStatusDonut extends StatelessWidget {
  const _IdeaStatusDonut({required this.vm});
  final _FacultyDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    final total = (vm.submittedIdeas + vm.underReviewIdeas + vm.evaluatedIdeas).clamp(1, 1 << 20);
    final submittedPct = vm.submittedIdeas / total;
    final reviewPct = vm.underReviewIdeas / total;
    final evaluatedPct = vm.evaluatedIdeas / total;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 14,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8ECF8)),
              ),
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _DonutPainter(submittedPct: submittedPct, reviewPct: reviewPct, evaluatedPct: evaluatedPct),
                ),
              ),
              Text('${vm.ideaCount}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LegendItem(
                icon: AppIcons.statusSubmitted,
                color: StatusStyles.submitted,
                label: 'Submitted',
              ),
              SizedBox(height: 6),
              _LegendItem(
                icon: AppIcons.statusUnderReview,
                color: StatusStyles.underReview,
                label: 'Under Review',
              ),
              SizedBox(height: 6),
              _LegendItem(
                icon: AppIcons.statusEvaluated,
                color: StatusStyles.evaluated,
                label: 'Evaluated',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.submittedPct,
    required this.reviewPct,
    required this.evaluatedPct,
  });

  final double submittedPct;
  final double reviewPct;
  final double evaluatedPct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 10);
    const stroke = 14.0;
    double start = -1.5708;
    void arc(double pct, Color color) {
      if (pct <= 0) return;
      final p = Paint()
        ..color = color
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final sweep = pct * 6.28318;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }

    arc(submittedPct, StatusStyles.submitted);
    arc(reviewPct, StatusStyles.underReview);
    arc(evaluatedPct, StatusStyles.evaluated);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.submittedPct != submittedPct ||
      oldDelegate.reviewPct != reviewPct ||
      oldDelegate.evaluatedPct != evaluatedPct;
}

class _SubmissionTrendChart extends StatelessWidget {
  const _SubmissionTrendChart({required this.series});
  final Map<String, int> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No submissions yet.'));
    }
    final labels = series.keys.toList(growable: false);
    final values = series.values.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _LegendItem(
          icon: AppIcons.submissions,
          color: StatusStyles.underReview,
          label: 'Ideas Submitted',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Idea Count',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomPaint(
                  painter: _SubmissionTrendLinePainter(values: values),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List<Widget>.generate(
            values.length,
            (int i) => Expanded(
              child: Text(
                '${values[i]}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: labels
              .map((label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
                    ),
                  ))
              .toList(growable: false),
        ),
        const SizedBox(height: 2),
        const Align(
          alignment: Alignment.center,
          child: Text(
            'Date',
            style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
          ),
        ),
      ],
    );
  }
}

class _SubmissionTrendLinePainter extends CustomPainter {
  const _SubmissionTrendLinePainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) return;
    final maxV = values.fold<int>(1, (a, b) => a > b ? a : b).toDouble();
    final count = values.length;
    final dx = count == 1 ? 0.0 : size.width / (count - 1);
    Offset pointAt(int index, int value) {
      final x = dx * index;
      final y = size.height - ((value / maxV) * (size.height - 8)) - 4;
      return Offset(x, y);
    }

    final line = Paint()
      ..color = StatusStyles.underReview
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pointAt(0, values[0]).dx, pointAt(0, values[0]).dy);
    for (int i = 1; i < count; i++) {
      final p = pointAt(i, values[i]);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = StatusStyles.underReview;
    for (int i = 0; i < count; i++) {
      final p = pointAt(i, values[i]);
      canvas.drawCircle(p, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SubmissionTrendLinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class _LegendItem extends StatelessWidget {
  static const double _kIconSize = 18;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: _kIconSize, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String text;
  final DateTime time;
}
