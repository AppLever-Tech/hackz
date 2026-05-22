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
import '../../utils/common_helpers.dart';
import '../../widgets/common/idea_status_distribution_donut.dart';
import '../../widgets/common/time_frame_filter.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../../workspace/workspace.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
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
        if (selectedMenuIndex == 4) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
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

enum _FacultyTimeframe {
  currentWeek('Current week'),
  lastWeek('Last week'),
  lastMonth('Last month'),
  lastSixMonths('Last 6 months'),
  all('All');

  const _FacultyTimeframe(this.label);
  final String label;
}

class _FacultyDashboardHome extends StatefulWidget {
  const _FacultyDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_FacultyDashboardHome> createState() => _FacultyDashboardHomeState();
}

class _FacultyDashboardHomeState extends State<_FacultyDashboardHome> {
  static const double _kDashboardIconSize = 18;
  static const double _kFacultyChartHeight = 200;
  static const double _kChartHeaderSpacing = 6;
  _FacultyDashboardVm? _vm;
  Object? _loadError;
  bool _loading = true;
  int _activityLimit = 8;
  _FacultyTimeframe _submissionTimeframe = _FacultyTimeframe.currentWeek;
  _FacultyTimeframe _activityTimeframe = _FacultyTimeframe.currentWeek;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final _FacultyDashboardVm vm = await _FacultyDashboardService().load(widget.user);
      if (!mounted) return;
      setState(() {
        _vm = vm;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Text('Unable to load faculty dashboard: $_loadError');
    }

    final _FacultyDashboardVm vm = _vm ?? _FacultyDashboardVm.empty;
    final gap = ResponsiveHelper.dashboardSectionGap(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSummaryCards(vm),
          SizedBox(height: gap),
          _buildCharts(vm),
          SizedBox(height: gap),
          _buildKeyCards(context, vm),
          SizedBox(height: gap),
          _buildRecentActivity(vm),
        ],
      ),
    );
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  Map<String, int> _buildTimeSeries(Iterable<DateTime> source, _FacultyTimeframe timeframe) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    late final DateTime start;
    late final DateTime end;
    late final int bucketCount;
    late final Duration bucketSize;
    switch (timeframe) {
      case _FacultyTimeframe.currentWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case _FacultyTimeframe.lastWeek:
        end = today.subtract(Duration(days: today.weekday - 1));
        start = end.subtract(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case _FacultyTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
        break;
      case _FacultyTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
        break;
      case _FacultyTimeframe.all:
        final dates = source.toList(growable: false)..sort();
        start = dates.isEmpty ? today.subtract(const Duration(days: 180)) : DateTime(dates.first.year, dates.first.month, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final days = end.difference(start).inDays.clamp(1, 3650).toInt();
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365).toInt());
        break;
    }

    final buckets = List<DateTime>.generate(bucketCount, (int i) => start.add(Duration(days: bucketSize.inDays * i)));
    final dates = source.map(_dateOnly).toList(growable: false);
    return <String, int>{
      for (int i = 0; i < buckets.length; i++)
        _bucketLabel(buckets[i], timeframe): dates.where((DateTime date) {
          final DateTime from = _dateOnly(buckets[i]);
          final DateTime to = _dateOnly(i == buckets.length - 1 ? end : buckets[i + 1]);
          return !date.isBefore(from) && date.isBefore(to);
        }).length,
    };
  }

  bool _isWithinTimeframe(DateTime date, _FacultyTimeframe timeframe) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final DateTime when = _dateOnly(date);
    switch (timeframe) {
      case _FacultyTimeframe.currentWeek:
        final DateTime start = today.subtract(Duration(days: today.weekday - 1));
        return !when.isBefore(start) && when.isBefore(start.add(const Duration(days: 7)));
      case _FacultyTimeframe.lastWeek:
        final DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final DateTime start = currentWeekStart.subtract(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(currentWeekStart);
      case _FacultyTimeframe.lastMonth:
        return !when.isBefore(today.subtract(const Duration(days: 30)));
      case _FacultyTimeframe.lastSixMonths:
        return !when.isBefore(DateTime(today.year, today.month - 5, 1));
      case _FacultyTimeframe.all:
        return true;
    }
  }

  String _bucketLabel(DateTime date, _FacultyTimeframe timeframe) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    switch (timeframe) {
      case _FacultyTimeframe.currentWeek:
      case _FacultyTimeframe.lastWeek:
        const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case _FacultyTimeframe.lastMonth:
        return '${date.month}/${date.day}';
      case _FacultyTimeframe.lastSixMonths:
        return months[date.month - 1];
      case _FacultyTimeframe.all:
        return '${months[date.month - 1]} ${date.year % 100}';
    }
  }

  Widget _buildSummaryCards(_FacultyDashboardVm vm) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Teams',
          value: '${vm.teamCount}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.teams,
        ),
        DashboardMetricChipData.single(
          label: 'Students',
          value: '${vm.studentCount}',
          color: const Color(0xFF16A34A),
          icon: AppIcons.student,
        ),
        DashboardMetricChipData.single(
          label: 'Problems',
          value: '${vm.departmentProblemCount}',
          color: const Color(0xFF059669),
          icon: AppIcons.problems,
        ),
        DashboardMetricChipData.withSegments(
          label: 'Ideas',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.ideas,
          segments: <DashboardMetricChipSegment>[
            DashboardMetricChipSegment(
              icon: AppIcons.statusSubmitted,
              tooltip: 'Submitted',
              value: '${vm.submittedIdeas}',
              color: StatusStyles.submitted,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusApproved,
              tooltip: 'Approved',
              value: '${vm.approvedIdeas}',
              color: StatusStyles.approved,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              value: '${vm.rejectedIdeas}',
              color: StatusStyles.rejected,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharts(_FacultyDashboardVm vm) {
    final statusChart = ChartCard(
      title: 'Idea Status',
      icon: AppIcons.ideas,
      headerSpacing: _kChartHeaderSpacing,
      child: ResponsiveChartBox(
        desktopHeight: _kFacultyChartHeight,
        child: IdeaStatusDistributionDonut(
          pending: vm.pendingIdeas,
          submitted: vm.submittedIdeas,
          underReview: vm.underReviewIdeas,
          evaluated: vm.evaluatedIdeas,
          approved: vm.approvedIdeas,
          rejected: vm.rejectedIdeas,
        ),
      ),
    );
    final submissionChart = ChartCard(
      title: 'Submissions Over Time',
      icon: AppIcons.submissions,
      headerSpacing: _kChartHeaderSpacing,
      trailing: TimeFrameFilter<_FacultyTimeframe>(
        options: _FacultyTimeframe.values,
        selected: _submissionTimeframe,
        labelBuilder: (_FacultyTimeframe option) => option.label,
        onChanged: (timeframe) => setState(() => _submissionTimeframe = timeframe),
      ),
      child: ResponsiveChartBox(
        desktopHeight: _kFacultyChartHeight,
        child: _SubmissionTrendChart(
          problemSeries: _buildTimeSeries(vm.problemDates, _submissionTimeframe),
          ideaSeries: _buildTimeSeries(vm.submissionDates, _submissionTimeframe),
          teamSeries: _buildTimeSeries(vm.teamCreationDates, _submissionTimeframe),
        ),
      ),
    );
    return ResponsivePair(
      spacing: ResponsiveHelper.dashboardSectionGap(context),
      secondFlex: 2,
      first: statusChart,
      second: submissionChart,
    );
  }

  Widget _buildKeyCards(BuildContext context, _FacultyDashboardVm vm) {
    final gap = ResponsiveHelper.dashboardSectionGap(context);
    return ResponsivePair(
      spacing: gap,
      first: _KeyDataCard(
        title: 'My Teams',
        icon: AppIcons.teams,
        count: vm.teamCount,
        teamPreview: vm.teams.take(3).toList(growable: false),
      ),
      second: _KeyDataCard(
        title: 'My Ideas',
        icon: AppIcons.ideas,
        count: vm.ideaCount,
        ideaPreviews: vm.ideaPreviews,
      ),
    );
  }

  Widget _buildRecentActivity(_FacultyDashboardVm vm) {
    final filtered = vm.activities.where((a) => _isWithinTimeframe(a.time, _activityTimeframe)).toList(growable: false);
    final visible = filtered.take(_activityLimit).toList(growable: false);
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardCardHeaderRow(
            title: 'Recent Activity',
            icon: AppIcons.clock,
            trailing: TimeFrameFilter<_FacultyTimeframe>(
              options: _FacultyTimeframe.values,
              selected: _activityTimeframe,
              labelBuilder: (_FacultyTimeframe option) => option.label,
              onChanged: (_FacultyTimeframe timeframe) => setState(() {
                _activityTimeframe = timeframe;
                _activityLimit = 8;
              }),
            ),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('No activity in this period.')
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
          if (_activityLimit < filtered.length)
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
    return formatDateTime(date);
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
          final teamId = ((m['teamId'] as String?) ?? '').trim();
          final createdBy = ((m['createdBy'] as String?) ?? '').trim();
          return teamIds.contains(teamId) || createdBy == user.userId;
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
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    for (final idea in ideas) {
      switch (idea.status) {
        case IdeaStatus.pendingSubmission:
          pending++;
          break;
        case IdeaStatus.evaluated:
          evaluated++;
          break;
        case IdeaStatus.approved:
          approved++;
          break;
        case IdeaStatus.rejected:
          rejected++;
          break;
        case IdeaStatus.underReview:
          underReview++;
          break;
        default:
          submitted++;
      }
    }

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
          icon: AppIcons.teams,
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
      pendingIdeas: pending,
      approvedIdeas: approved,
      rejectedIdeas: rejected,
      departmentProblemCount: departmentProblems.length,
      submissionDates: ideas.map((i) => i.createdAt).toList(growable: false),
      problemDates: departmentProblems
          .map((p) => (p.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now())
          .toList(growable: false),
      teamCreationDates: teams.map((t) => t.createdAt).toList(growable: false),
      ideaPreviews: (ideas.toList(growable: false)..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .map(
            (i) => _FacultyIdeaPreview(
              ideaId: i.ideaId,
              title: i.ideaTitle.trim().isEmpty ? 'Untitled Idea' : i.ideaTitle.trim(),
              status: i.status,
            ),
          )
          .toList(growable: false),
      activities: activities.take(40).toList(growable: false),
      usersById: usersById,
    );
  }
}

class _FacultyIdeaPreview {
  const _FacultyIdeaPreview({
    required this.ideaId,
    required this.title,
    required this.status,
  });

  final String ideaId;
  final String title;
  final IdeaStatus status;
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
    required this.pendingIdeas,
    required this.approvedIdeas,
    required this.rejectedIdeas,
    required this.departmentProblemCount,
    required this.submissionDates,
    required this.problemDates,
    required this.teamCreationDates,
    required this.ideaPreviews,
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
    pendingIdeas: 0,
    approvedIdeas: 0,
    rejectedIdeas: 0,
    departmentProblemCount: 0,
    submissionDates: <DateTime>[],
    problemDates: <DateTime>[],
    teamCreationDates: <DateTime>[],
    ideaPreviews: <_FacultyIdeaPreview>[],
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
  final int pendingIdeas;
  final int approvedIdeas;
  final int rejectedIdeas;
  final int departmentProblemCount;
  final List<DateTime> submissionDates;
  final List<DateTime> problemDates;
  final List<DateTime> teamCreationDates;
  final List<_FacultyIdeaPreview> ideaPreviews;
  final List<_ActivityItem> activities;
  final Map<String, Map<String, dynamic>> usersById;
}

class _KeyDataCard extends StatelessWidget {
  const _KeyDataCard({
    required this.title,
    required this.icon,
    required this.count,
    this.teamPreview = const <TeamModel>[],
    this.ideaPreviews = const <_FacultyIdeaPreview>[],
  });

  final String title;
  final IconData icon;
  final int count;
  final List<TeamModel> teamPreview;
  final List<_FacultyIdeaPreview> ideaPreviews;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: SizedBox(
        height: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFF2EDFF), shape: BoxShape.circle),
                  child: Icon(icon, size: 17, color: Color(0xFF6A38FF)),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(999)),
                  child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF3552CC))),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: teamPreview.isEmpty && ideaPreviews.isEmpty
                  ? const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394))))
                  : SingleChildScrollView(
                      child: Column(
                        children: title == 'My Teams'
                            ? teamPreview.map((team) => _teamBullet(context, team)).toList(growable: false)
                            : ideaPreviews.map((idea) => _ideaBullet(context, idea)).toList(growable: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamBullet(BuildContext context, TeamModel team) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          const Icon(AppIcons.statusActive, size: 9, color: Color(0xFF6A38FF)),
          const SizedBox(width: 8),
          Expanded(
            child: team.teamId.trim().isNotEmpty
                ? ContextPill(
                    label: team.teamName.isEmpty ? team.teamId : team.teamName,
                    semantic: ContextPillSemantic.team,
                    onTap: () => WorkspaceNavigator.openTeam(context, team.teamId),
                    compact: true,
                    expandWidth: true,
                  )
                : Text(
                    team.teamName.isEmpty ? team.teamId : team.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 8),
          const Icon(
            AppIcons.student,
            size: _FacultyDashboardHomeState._kDashboardIconSize,
            color: Color(0xFF4A4F73),
          ),
          const SizedBox(width: 4),
          Text(
            '${team.studentIds.length}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4A4F73)),
          ),
        ],
      ),
    );
  }

  Widget _ideaBullet(BuildContext context, _FacultyIdeaPreview idea) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          const Icon(AppIcons.statusActive, size: 9, color: Color(0xFF6A38FF)),
          const SizedBox(width: 8),
          Expanded(
            child: idea.ideaId.trim().isNotEmpty
                ? ContextPill(
                    label: idea.title,
                    semantic: ContextPillSemantic.idea,
                    onTap: () => WorkspaceNavigator.openIdea(context, idea.ideaId),
                    compact: true,
                    expandWidth: true,
                  )
                : Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 8),
          StatusStyles.ideaStatusIcon(
            idea.status,
            size: _FacultyDashboardHomeState._kDashboardIconSize,
          ),
        ],
      ),
    );
  }

}

class _SubmissionTrendChart extends StatelessWidget {
  const _SubmissionTrendChart({
    required this.problemSeries,
    required this.ideaSeries,
    required this.teamSeries,
  });

  final Map<String, int> problemSeries;
  final Map<String, int> ideaSeries;
  final Map<String, int> teamSeries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerRight,
          child: _SubmissionTrendLegend(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _MultiLineTimeSeriesChart(
            series: <_TrendSeries>[
              _TrendSeries(values: problemSeries, color: const Color(0xFF6A38FF)),
              _TrendSeries(values: ideaSeries, color: StatusStyles.underReview),
              _TrendSeries(values: teamSeries, color: const Color(0xFF16A34A)),
            ],
            emptyLabel: 'No trend data in this period.',
          ),
        ),
      ],
    );
  }
}

class _SubmissionTrendLegend extends StatelessWidget {
  const _SubmissionTrendLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 6,
      children: <Widget>[
        _LegendItem(icon: AppIcons.problems, color: Color(0xFF6A38FF), label: 'Problems'),
        _LegendItem(icon: AppIcons.submissions, color: StatusStyles.underReview, label: 'Ideas Submitted'),
        _LegendItem(icon: AppIcons.teams, color: Color(0xFF16A34A), label: 'Teams Created'),
      ],
    );
  }
}

class _TrendSeries {
  const _TrendSeries({
    required this.values,
    required this.color,
  });

  final Map<String, int> values;
  final Color color;
}

class _MultiLineTimeSeriesChart extends StatelessWidget {
  const _MultiLineTimeSeriesChart({
    required this.series,
    required this.emptyLabel,
  });

  final List<_TrendSeries> series;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final labels = series.isEmpty ? <String>[] : series.first.values.keys.toList(growable: false);
    final hasData = series.any((line) => line.values.values.any((value) => value > 0));
    if (series.isEmpty || labels.isEmpty || !hasData) {
      return Center(child: Text(emptyLabel));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              const RotatedBox(
                quarterTurns: 3,
                child: Text('Count', style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87))),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomPaint(
                  painter: _MultiLineTimeSeriesPainter(series: series),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _MultiLineTimeSeriesPainter extends CustomPainter {
  const _MultiLineTimeSeriesPainter({required this.series});

  final List<_TrendSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final allValues = series.expand((line) => line.values.values).toList(growable: false);
    if (allValues.isEmpty) return;
    final maxV = allValues.fold<int>(1, (a, b) => a > b ? a : b).toDouble();
    final count = series.first.values.length;
    final dx = count == 1 ? 0.0 : size.width / (count - 1);
    Offset pointAt(int index, int value) {
      final x = count == 1 ? size.width / 2 : dx * index;
      final y = size.height - ((value / maxV) * (size.height - 8)) - 4;
      return Offset(x, y);
    }

    for (final trend in series) {
      final values = trend.values.values.toList(growable: false);
      if (values.isEmpty) continue;
      final line = Paint()
        ..color = trend.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(pointAt(0, values[0]).dx, pointAt(0, values[0]).dy);
      for (int i = 1; i < count; i++) {
        final p = pointAt(i, values[i]);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);

      final dot = Paint()..color = trend.color;
      for (int i = 0; i < count; i++) {
        final p = pointAt(i, values[i]);
        canvas.drawCircle(p, 3.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineTimeSeriesPainter oldDelegate) =>
      oldDelegate.series != series;
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
