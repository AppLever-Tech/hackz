import 'package:flutter/material.dart';

import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';
import '../services/leaderboard_role_config.dart';
import '../services/leaderboard_showcase_service.dart';
import '../widgets/comparative_analytics_section.dart';
import '../widgets/innovation_momentum_chart.dart';
import '../widgets/leaderboard_hero_section.dart';
import '../widgets/leaderboard_tab_section.dart';
import '../widgets/rank_showcase_card.dart';
import '../widgets/rising_ideas_widget.dart';
import '../widgets/trend_indicator_widget.dart';

/// Innovation Leaderboard Showcase — analytics-first, separate from operational dashboards.
class LeaderboardShowcaseScreen extends StatefulWidget {
  const LeaderboardShowcaseScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<LeaderboardShowcaseScreen> createState() => _LeaderboardShowcaseScreenState();
}

class _LeaderboardShowcaseScreenState extends State<LeaderboardShowcaseScreen> {
  final LeaderboardShowcaseService _service = LeaderboardShowcaseService();
  late Future<LeaderboardShowcaseVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  List<LeaderboardShowcaseTab> _orderedTabs(LeaderboardShowcaseVm vm) {
    const order = <LeaderboardShowcaseTab>[
      LeaderboardShowcaseTab.teams,
      LeaderboardShowcaseTab.departments,
      LeaderboardShowcaseTab.mentors,
      LeaderboardShowcaseTab.ideas,
    ];
    return order.where((t) => vm.config.visibleTabs.contains(t)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaderboardShowcaseVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load leaderboard: ${snapshot.error}'));
        }
        final vm = snapshot.data!;
        if (vm.judgeMode) {
          return _JudgeEvaluationShowcase(vm: vm);
        }
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: ResponsiveHelper.isMobile(context) ? 8 : 0,
              right: ResponsiveHelper.isMobile(context) ? 8 : 0,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (vm.hero != null && vm.podium.isNotEmpty)
                  LeaderboardHeroSection(hero: vm.hero!, podium: vm.podium)
                else
                  _EmptyHeroPlaceholder(),
                const SizedBox(height: 20),
                LeaderboardTabSection(
                  visibleTabs: _orderedTabs(vm),
                  tabChildren: _tabBodies(vm),
                ),
                if (RoleVisibilityHelpers.canViewIdeas(UserRole.fromCode(widget.user.role))) ...<Widget>[
                  const SizedBox(height: 20),
                  RisingIdeasWidget(rows: vm.risingIdeaRows),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 20),
                InnovationMomentumChart(
                  series: vm.momentumSeries,
                  height: ResponsiveHelper.isMobile(context) ? 120 : 140,
                ),
                const SizedBox(height: 16),
                ComparativeAnalyticsSection(
                  title: 'Department participation pulse',
                  labels: vm.participationByDept.keys.toList(),
                  values: vm.participationByDept.values.toList(),
                  barColor: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 14),
                ComparativeAnalyticsSection(
                  title: 'Average composite score by department',
                  labels: vm.comparativeAvgScoreByDept.keys.toList(),
                  values: vm.comparativeAvgScoreByDept.values.toList(),
                  barColor: const Color(0xFF0EA5E9),
                ),
                if (vm.comparativeApprovalByDept.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  ComparativeAnalyticsSection(
                    title: 'Approval ratio by department',
                    labels: vm.comparativeApprovalByDept.keys.toList(),
                    values: vm.comparativeApprovalByDept.values.toList(),
                    barColor: const Color(0xFF22C55E),
                  ),
                ],
                const SizedBox(height: 18),
                _InsightsWrap(insights: vm.insights),
                if (vm.trendingThemes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _TrendingThemesRow(themes: vm.trendingThemes),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _tabBodies(LeaderboardShowcaseVm vm) {
    final tabs = _orderedTabs(vm);
    return tabs.map((t) {
      switch (t) {
        case LeaderboardShowcaseTab.teams:
          return ListView(
            padding: const EdgeInsets.only(right: 8),
            children: vm.teamRows
                .map(
                  (r) => RankShowcaseCard(
                    rank: r.rank,
                    title: r.spotlightIdeaTitle,
                    subtitle: '${r.teamName} • ${r.departmentLabel}',
                    onOpenSubtitleWorkspace: r.teamId.trim().isEmpty
                        ? null
                        : () => WorkspaceNavigator.openTeam(context, r.teamId),
                    subtitleWorkspaceSemantic: ContextPillSemantic.team,
                    scoreLabel: 'Innovation score',
                    scoreValue: r.finalScore.toStringAsFixed(1),
                    trend: r.trend,
                    achievementId: r.achievementId,
                  ),
                )
                .toList(),
          );
        case LeaderboardShowcaseTab.departments:
          return ListView(
            padding: const EdgeInsets.only(right: 8),
            children: vm.departmentRows.map((d) => _DepartmentShowcaseTile(row: d)).toList(),
          );
        case LeaderboardShowcaseTab.mentors:
          return ListView(
            padding: const EdgeInsets.only(right: 8),
            children: vm.mentorRows.map((m) => _MentorShowcaseTile(row: m)).toList(),
          );
        case LeaderboardShowcaseTab.ideas:
          return ListView(
            padding: const EdgeInsets.only(right: 8),
            children: vm.ideaRows
                .map(
                  (r) => RankShowcaseCard(
                    rank: r.rank,
                    title: r.title,
                    onOpenTitleWorkspace: r.ideaId.trim().isEmpty
                        ? null
                        : () => WorkspaceNavigator.openEvaluation(context, r.ideaId),
                    titleWorkspaceSemantic: ContextPillSemantic.evaluation,
                    subtitle: r.categoryTheme,
                    scoreLabel: 'Innovation / Final',
                    scoreValue: '${r.innovationScore.toStringAsFixed(0)} • ${r.finalScore.toStringAsFixed(1)}',
                    trend: r.trend,
                    achievementId: r.achievementId,
                  ),
                )
                .toList(),
          );
      }
    }).toList(growable: false);
  }
}

class _JudgeEvaluationShowcase extends StatelessWidget {
  const _JudgeEvaluationShowcase({required this.vm});

  final LeaderboardShowcaseVm vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Evaluation analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distribution and comparative evaluation insights — showcase-only (no competitive finals).',
              style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.35),
            ),
            const SizedBox(height: 22),
            _HistogramCard(values: vm.judgeEvaluationHistogram),
            const SizedBox(height: 16),
            InnovationMomentumChart(
              series: vm.judgeTimeline,
              lineColor: const Color(0xFF38BDF8),
              height: 160,
            ),
            const SizedBox(height: 16),
            ComparativeAnalyticsSection(
              title: 'Evaluation volume by department code',
              labels: vm.participationByDept.keys.toList(),
              values: vm.participationByDept.values.toList(),
              barColor: const Color(0xFFA855F7),
            ),
            const SizedBox(height: 14),
            ComparativeAnalyticsSection(
              title: 'Mean judge score by department code',
              labels: vm.comparativeAvgScoreByDept.keys.toList(),
              values: vm.comparativeAvgScoreByDept.values.toList(),
              barColor: const Color(0xFF22D3EE),
            ),
            const SizedBox(height: 16),
            _InsightsWrap(insights: vm.insights, dark: true),
          ],
        ),
      ),
    );
  }
}

class _HistogramCard extends StatelessWidget {
  const _HistogramCard({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Score distribution',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(values.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const topReserve = 22.0;
                        const gaps = 8.0;
                        const bottomReserve = 18.0;
                        final maxBarH =
                            (constraints.maxHeight - topReserve - gaps - bottomReserve).clamp(8.0, 120.0);
                        final h = (values[i] / maxV * maxBarH).clamp(4.0, maxBarH);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              '${values[i]}',
                              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  colors: <Color>[Color(0xFF6366F1), Color(0xFFA855F7)],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$i', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentShowcaseTile extends StatelessWidget {
  const _DepartmentShowcaseTile({required this.row});

  final DepartmentShowcaseRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('#${row.rank}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF4F46E5))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.departmentLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              TrendIndicatorWidget(direction: row.trend, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Text('Top team: ${row.topTeamName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _miniBar('Participation', row.participationPct / 100, const Color(0xFF6366F1)),
          _miniBar('Avg score', row.avgScore / 100, const Color(0xFF0EA5E9)),
          _miniBar('Approved ideas', row.approvedIdeasPct / 100, const Color(0xFF22C55E)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text('Innovation index', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const Spacer(),
              Text(
                row.innovationIndex.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 11)),
              const Spacer(),
              Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, backgroundColor: const Color(0xFFE2E8F0), color: color),
          ),
        ],
      ),
    );
  }
}

class _MentorShowcaseTile extends StatelessWidget {
  const _MentorShowcaseTile({required this.row});

  final MentorShowcaseRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: <Color>[Color(0xFFFFF7ED), Color(0xFFEFF6FF)]),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEA580C),
                child: Text('${row.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(row.mentorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(
                      '${row.teamsMentored} teams • Highest: ${row.highestRankedTeamName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              TrendIndicatorWidget(direction: row.trend, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip('Avg team score', row.avgTeamScore.toStringAsFixed(1)),
              _chip('Innovation success', '${row.innovationSuccessPct.toStringAsFixed(0)}%'),
              _chip('Approved', '${row.approvedIdeasPct.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text('$k: $v', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyHeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Text(
        'Leaderboard showcase warms up as evaluated ideas appear.',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
      ),
    );
  }
}

class _InsightsWrap extends StatelessWidget {
  const _InsightsWrap({required this.insights, this.dark = false});

  final List<String> insights;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: insights
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withOpacity(0.08) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dark ? Colors.white24 : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: dark ? Colors.white.withOpacity(0.88) : const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TrendingThemesRow extends StatelessWidget {
  const _TrendingThemesRow({required this.themes});

  final List<String> themes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Trending themes', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themes
              .map(
                (s) => Chip(
                  label: Text(s),
                  backgroundColor: const Color(0xFFEEF2FF),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
