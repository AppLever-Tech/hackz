import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/department_model.dart';
import '../models/enums/user_role.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/problem_model.dart';
import '../models/score_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';
import 'leaderboard_ranking_engine.dart';
import 'leaderboard_role_config.dart';

class LeaderboardShowcaseService {
  LeaderboardShowcaseService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final LeaderboardRankingEngine _engine = const LeaderboardRankingEngine();

  Future<LeaderboardShowcaseVm> load(UserModel viewer) async {
    final config = LeaderboardRoleConfig.forUser(viewer);
    final role = UserRole.fromCode(viewer.role);

    final snapshots = await Future.wait<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      <Future<QuerySnapshot<Map<String, dynamic>>>>[
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzIdeas).get()
            : _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: config.scopeOrgId).get(),
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzScores).get()
            : _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: config.scopeOrgId).get(),
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzTeams).get()
            : _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: config.scopeOrgId).get(),
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzProblems).get()
            : _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: config.scopeOrgId).get(),
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzPayments).get()
            : _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: config.scopeOrgId).get(),
        config.platformWide
            ? _db.collection(FirestoreUtils.hkzUsers).get()
            : _db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: config.scopeOrgId).get(),
      ].map((f) => f.then((s) => s.docs)),
    );

    final ideaDocs = snapshots[0];
    final scoreDocs = snapshots[1];
    final teamDocs = snapshots[2];
    final problemDocs = snapshots[3];
    final paymentDocs = snapshots[4];
    final userDocs = snapshots[5];

    var ideas = ideaDocs.map((d) => IdeaModel.fromMap(d.id, d.data())).toList(growable: false);
    final scores = scoreDocs.map((d) => ScoreModel.fromMap(d.id, d.data())).toList(growable: false);
    final teams = teamDocs.map((d) => TeamModel.fromMap(d.id, d.data())).toList(growable: false);
    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
    };
    final payments = paymentDocs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList(growable: false);
    final paymentByIdea = _bestPaymentByIdea(payments);

    final usersById = <String, UserModel>{};
    for (final d in userDocs) {
      final u = UserModel.fromMap(d.data());
      final id = u.userId.trim().isEmpty ? d.id : u.userId.trim();
      usersById[id] = u.userId.trim().isEmpty ? u.copyWith(userId: id) : u;
    }

    ideas = _applyVisibilityFilters(ideas, problemsById, config, role).toList(growable: false);

    final scoresByIdea = _groupScoresByIdea(scores);
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 14));

    final bundles = <_IdeaScoreBundle>[];
    for (final idea in ideas) {
      final list = scoresByIdea[idea.ideaId] ?? const <ScoreModel>[];
      if (list.isEmpty && config.judgeEvaluationAnalyticsOnly == false) {
        continue;
      }
      final avgJudge = list.isEmpty ? 0.0 : list.map((s) => s.score).reduce((a, b) => a + b) / list.length;
      final problem = problemsById[idea.problemId];
      final payment = paymentByIdea[idea.ideaId];
      final composite = list.isEmpty
          ? _engine.innovationFactor(idea, problem) * 100 * 0.85 +
              _engine.submissionPaymentCompleteness(idea, payment) * 100 * 0.15
          : _engine.compositeIdeaScore(
              avgJudgeScore: avgJudge,
              idea: idea,
              problem: problem,
              payment: payment,
            );
      final innov = _engine.innovationFactor(idea, problem) * 100;
      final trend = _trendForScores(list, cutoff);
      bundles.add(
        _IdeaScoreBundle(
          idea: idea,
          avgJudge: avgJudge,
          composite: composite,
          innovationScore: innov,
          trend: trend,
        ),
      );
    }

    if (config.judgeEvaluationAnalyticsOnly) {
      return _buildJudgeVm(scores, ideas, problemsById, config);
    }

    bundles.sort((a, b) => b.composite.compareTo(a.composite));

    var teamScoped = teams;
    if (role == UserRole.faculty && (config.facultyMentorId ?? '').isNotEmpty) {
      final mid = config.facultyMentorId!.trim();
      teamScoped = teams.where((t) => t.mentorId == mid).toList(growable: false);
    }
    if (role == UserRole.student && config.scopeDepartmentCode != null) {
      final code = config.scopeDepartmentCode!.toUpperCase();
      teamScoped = teamScoped.where((t) => t.departmentCode.toUpperCase() == code).toList(growable: false);
    }

    final teamIdeas = <String, List<_IdeaScoreBundle>>{};
    for (final b in bundles) {
      teamIdeas.putIfAbsent(b.idea.teamId, () => <_IdeaScoreBundle>[]).add(b);
    }

    final teamEntries = <_TeamAgg>[];
    for (final t in teamScoped) {
      final list = teamIdeas[t.teamId];
      if (list == null || list.isEmpty) continue;
      list.sort((a, b) => b.composite.compareTo(a.composite));
      final top = list.first;
      final avgComposite = list.map((e) => e.composite).reduce((a, b) => a + b) / list.length;
      final dept = problemsById[top.idea.problemId]?.departmentDisplayName ??
          DepartmentModel.byCode(top.idea.departmentCode)?.name ??
          top.idea.departmentCode;
      teamEntries.add(
        _TeamAgg(
          team: t,
          spotlight: top,
          avgComposite: avgComposite,
          deptLabel: dept,
        ),
      );
    }
    teamEntries.sort((a, b) => b.spotlight.composite.compareTo(a.spotlight.composite));

    final teamRows = <TeamShowcaseRow>[];
    for (var i = 0; i < teamEntries.length; i++) {
      final e = teamEntries[i];
      teamRows.add(
        TeamShowcaseRow(
          rank: i + 1,
          teamId: e.team.teamId,
          teamName: e.team.teamName.trim().isEmpty ? e.team.teamId : e.team.teamName,
          spotlightIdeaTitle: _ideaTitle(e.spotlight.idea),
          departmentLabel: e.deptLabel,
          finalScore: e.spotlight.composite,
          trend: e.spotlight.trend,
          achievementId: _achievementForRank(i + 1, e.spotlight.trend),
        ),
      );
    }

    final deptCodeStats = <String, List<_IdeaScoreBundle>>{};
    for (final b in bundles) {
      final code = (problemsById[b.idea.problemId]?.departmentCode ?? b.idea.departmentCode).toUpperCase();
      deptCodeStats.putIfAbsent(code, () => <_IdeaScoreBundle>[]).add(b);
    }

    final deptRows = <DepartmentShowcaseRow>[];
    final totalIdeasForParticipation = bundles.length.clamp(1, 1 << 30);

    final sortedDeptCodes = deptCodeStats.keys.toList()..sort();
    for (final code in sortedDeptCodes) {
      final list = deptCodeStats[code]!;
      final avg = list.map((e) => e.composite).reduce((a, b) => a + b) / list.length;
      final approved = list.where((e) => e.idea.status == IdeaStatus.approved).length;
      final participation =
          ((list.length / totalIdeasForParticipation * 100).clamp(0, 100)).toDouble();
      final approvedPct = list.isEmpty ? 0.0 : approved / list.length * 100;
      final innovationIndex =
          ((participation * 0.35 + avg * 0.35 + approvedPct * 0.30).clamp(0, 100)).toDouble();

      _TeamAgg? bestDeptTeam;
      for (final te in teamEntries) {
        if (te.team.departmentCode.toUpperCase() != code) continue;
        if (bestDeptTeam == null || te.spotlight.composite > bestDeptTeam.spotlight.composite) {
          bestDeptTeam = te;
        }
      }
      final topTeamName = bestDeptTeam?.team.teamName;

      deptRows.add(
        DepartmentShowcaseRow(
          rank: 0,
          departmentCode: code,
          departmentLabel: DepartmentModel.byCode(code)?.name ?? code,
          participationPct: participation,
          avgScore: avg,
          approvedIdeasPct: approvedPct,
          innovationIndex: innovationIndex,
          topTeamName: (topTeamName ?? '').trim().isEmpty ? '-' : topTeamName!,
          trend: TrendDirection.stable,
        ),
      );
    }
    deptRows.sort((a, b) => b.innovationIndex.compareTo(a.innovationIndex));
    for (var i = 0; i < deptRows.length; i++) {
      deptRows[i] = DepartmentShowcaseRow(
        rank: i + 1,
        departmentCode: deptRows[i].departmentCode,
        departmentLabel: deptRows[i].departmentLabel,
        participationPct: deptRows[i].participationPct,
        avgScore: deptRows[i].avgScore,
        approvedIdeasPct: deptRows[i].approvedIdeasPct,
        innovationIndex: deptRows[i].innovationIndex,
        topTeamName: deptRows[i].topTeamName,
        trend: deptRows[i].trend,
      );
    }

    final mentors = usersById.values.where((u) => UserRole.fromCode(u.role) == UserRole.faculty).toList(growable: false);
    final mentorRows = <MentorShowcaseRow>[];
    for (final m in mentors) {
      final mentoredTeams = teams.where((t) => t.mentorId == m.userId).toList(growable: false);
      if (mentoredTeams.isEmpty) continue;
      final bundlesForMentor = <_IdeaScoreBundle>[];
      for (final t in mentoredTeams) {
        bundlesForMentor.addAll(teamIdeas[t.teamId] ?? const <_IdeaScoreBundle>[]);
      }
      if (bundlesForMentor.isEmpty) continue;
      final avgTeam = bundlesForMentor.map((e) => e.composite).reduce((a, b) => a + b) / bundlesForMentor.length;
      final success = bundlesForMentor
              .where((e) => e.idea.status == IdeaStatus.evaluated || e.idea.status == IdeaStatus.approved)
              .length /
          bundlesForMentor.length *
          100;
      final approvedPct =
          bundlesForMentor.isEmpty ? 0.0 : bundlesForMentor.where((e) => e.idea.status == IdeaStatus.approved).length / bundlesForMentor.length * 100;

      final entryByTeamId = {for (final e in teamEntries) e.team.teamId: e};
      _TeamAgg? topRankedTeam;
      for (final t in mentoredTeams) {
        final e = entryByTeamId[t.teamId];
        if (e == null) continue;
        if (topRankedTeam == null || e.spotlight.composite > topRankedTeam.spotlight.composite) {
          topRankedTeam = e;
        }
      }

      mentorRows.add(
        MentorShowcaseRow(
          rank: 0,
          mentorId: m.userId,
          mentorName: _displayName(m),
          teamsMentored: mentoredTeams.length,
          avgTeamScore: avgTeam,
          innovationSuccessPct: success,
          approvedIdeasPct: approvedPct,
          highestRankedTeamName:
              topRankedTeam == null || topRankedTeam.team.teamName.isEmpty ? '-' : topRankedTeam.team.teamName,
          trend: TrendDirection.stable,
        ),
      );
    }
    mentorRows.sort((a, b) => b.avgTeamScore.compareTo(a.avgTeamScore));
    for (var i = 0; i < mentorRows.length; i++) {
      mentorRows[i] = MentorShowcaseRow(
        rank: i + 1,
        mentorId: mentorRows[i].mentorId,
        mentorName: mentorRows[i].mentorName,
        teamsMentored: mentorRows[i].teamsMentored,
        avgTeamScore: mentorRows[i].avgTeamScore,
        innovationSuccessPct: mentorRows[i].innovationSuccessPct,
        approvedIdeasPct: mentorRows[i].approvedIdeasPct,
        highestRankedTeamName: mentorRows[i].highestRankedTeamName,
        trend: mentorRows[i].trend,
      );
    }

    final ideaRows = <IdeaShowcaseRow>[];
    final ideaLimit = bundles.length > 200 ? 200 : bundles.length;
    for (var i = 0; i < ideaLimit; i++) {
      final b = bundles[i];
      final p = problemsById[b.idea.problemId];
      ideaRows.add(
        IdeaShowcaseRow(
          rank: i + 1,
          ideaId: b.idea.ideaId,
          title: _ideaTitle(b.idea),
          categoryTheme: '${p?.category ?? '-'} • ${p?.theme ?? '-'}',
          innovationScore: b.innovationScore,
          finalScore: b.composite,
          trend: b.trend,
          achievementId: _achievementForRank(i + 1, b.trend),
        ),
      );
    }

    final rising = ideaRows.toList()
      ..sort((a, b) {
        final da = _trendWeight(a.trend);
        final db = _trendWeight(b.trend);
        return db.compareTo(da);
      });

    final momentumSeries = _evaluationCountsByWeek(scores, cutoff.subtract(const Duration(days: 56)));

    final participationByDept = <String, double>{
      for (final r in deptRows) r.departmentLabel: r.participationPct,
    };

    final comparativeAvgScore = <String, double>{
      for (final r in deptRows) r.departmentLabel: r.avgScore,
    };

    final evaluationBins = _histogram(scores.map((s) => s.score).toList(growable: false));

    final themes = <String, int>{};
    for (final b in bundles) {
      final theme = problemsById[b.idea.problemId]?.theme.trim() ?? '';
      if (theme.isEmpty) continue;
      themes[theme] = (themes[theme] ?? 0) + 1;
    }
    final trendingThemes = themes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    LeaderboardHeroVm? hero;
    if (teamRows.isNotEmpty) {
      final first = teamRows.first;
      hero = LeaderboardHeroVm(
        spotlightTitle: first.spotlightIdeaTitle,
        subtitle: first.teamName,
        innovationScore: first.finalScore,
        rank: first.rank,
        trend: first.trend,
        achievementId: first.achievementId,
        departmentLabel: first.departmentLabel,
      );
    }

    final podium = teamRows.take(3).toList(growable: false);

    final insights = <String>[
      if (teamRows.length >= 3)
        'Top team momentum is concentrated in ${teamRows.first.departmentLabel} this cycle.',
      if (deptRows.isNotEmpty)
        '${deptRows.first.departmentLabel} leads the innovation index at ${deptRows.first.innovationIndex.toStringAsFixed(0)} pts.',
      if (trendingThemes.isNotEmpty) 'Trending theme: ${trendingThemes.first.key}',
      if (rising.isNotEmpty) 'Fast risers are clustering around ${_trendLabel(rising.first.trend)} scoring velocity.',
    ];

    return LeaderboardShowcaseVm(
      config: config,
      teamRows: teamRows,
      departmentRows: deptRows,
      mentorRows: mentorRows,
      ideaRows: ideaRows,
      hero: hero,
      podium: podium,
      risingIdeaRows: rising.take(8).toList(growable: false),
      insights: insights,
      momentumSeries: momentumSeries,
      participationByDept: participationByDept,
      comparativeAvgScoreByDept: comparativeAvgScore,
      comparativeApprovalByDept: {for (final r in deptRows) r.departmentLabel: r.approvedIdeasPct},
      evaluationHistogram: evaluationBins,
      trendingThemes: trendingThemes.take(6).map((e) => e.key).toList(growable: false),
      judgeMode: false,
      judgeEvaluationHistogram: const <int>[],
      judgeTimeline: const <String, int>{},
    );
  }

  LeaderboardShowcaseVm _buildJudgeVm(
    List<ScoreModel> scores,
    List<IdeaModel> ideas,
    Map<String, ProblemModel> problemsById,
    LeaderboardRoleConfig config,
  ) {
    final scopedScores = scores;
    final histogram = _histogram(scopedScores.map((s) => s.score).toList(growable: false));
    final timeline = _evaluationCountsByWeek(scopedScores, DateTime.now().subtract(const Duration(days: 84)));

    final byDept = <String, List<double>>{};
    for (final s in scopedScores) {
      IdeaModel? idea;
      for (final i in ideas) {
        if (i.ideaId == s.ideaId) {
          idea = i;
          break;
        }
      }
      final code = idea == null
          ? s.departmentCode
          : (problemsById[idea.problemId]?.departmentCode ?? idea.departmentCode).toUpperCase();
      byDept.putIfAbsent(code, () => <double>[]).add(s.score);
    }
    final avgByDept = <String, double>{};
    for (final e in byDept.entries) {
      avgByDept[e.key] = e.value.reduce((a, b) => a + b) / e.value.length;
    }

    final insights = <String>[
      'Evaluation distribution highlights scoring spread across ${scopedScores.length} records.',
      if (avgByDept.isNotEmpty)
        'Highest mean judge score in department code ${avgByDept.entries.reduce((a, b) => a.value >= b.value ? a : b).key}',
    ];

    return LeaderboardShowcaseVm(
      config: config,
      teamRows: const <TeamShowcaseRow>[],
      departmentRows: const <DepartmentShowcaseRow>[],
      mentorRows: const <MentorShowcaseRow>[],
      ideaRows: const <IdeaShowcaseRow>[],
      hero: null,
      podium: const <TeamShowcaseRow>[],
      risingIdeaRows: const <IdeaShowcaseRow>[],
      insights: insights,
      momentumSeries: timeline,
      participationByDept: {
        for (final e in byDept.entries) e.key: e.value.length.toDouble(),
      },
      comparativeAvgScoreByDept: avgByDept.map((k, v) => MapEntry(k, v)),
      comparativeApprovalByDept: const <String, double>{},
      evaluationHistogram: histogram,
      trendingThemes: const <String>[],
      judgeMode: true,
      judgeEvaluationHistogram: histogram,
      judgeTimeline: timeline,
    );
  }

  static List<IdeaModel> _applyVisibilityFilters(
    List<IdeaModel> ideas,
    Map<String, ProblemModel> problemsById,
    LeaderboardRoleConfig config,
    UserRole role,
  ) {
    Iterable<IdeaModel> out = ideas;
    if (role == UserRole.student && config.scopeDepartmentCode != null) {
      final code = config.scopeDepartmentCode!;
      out = out.where((i) {
        final p = problemsById[i.problemId];
        final dc = (p?.departmentCode ?? i.departmentCode).toUpperCase();
        return dc == code;
      });
    }
    if (role == UserRole.departmentAdmin && config.scopeDepartmentCode != null) {
      final code = config.scopeDepartmentCode!;
      out = out.where((i) {
        final p = problemsById[i.problemId];
        final dc = (p?.departmentCode ?? i.departmentCode).toUpperCase();
        return dc == code;
      });
    }
    return out.toList(growable: false);
  }

  static Map<String, List<ScoreModel>> _groupScoresByIdea(List<ScoreModel> scores) {
    final map = <String, List<ScoreModel>>{};
    for (final s in scores) {
      map.putIfAbsent(s.ideaId, () => <ScoreModel>[]).add(s);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }

  static Map<String, PaymentModel> _bestPaymentByIdea(List<PaymentModel> payments) {
    final map = <String, PaymentModel>{};
    for (final p in payments) {
      final prev = map[p.ideaId];
      if (prev == null) {
        map[p.ideaId] = p;
        continue;
      }
      if (p.status == PaymentRecordStatus.verified && prev.status != PaymentRecordStatus.verified) {
        map[p.ideaId] = p;
      }
    }
    return map;
  }

  static TrendDirection _trendForScores(List<ScoreModel> scores, DateTime cutoff) {
    if (scores.length < 2) return TrendDirection.stable;
    final recent = scores.where((s) => !s.createdAt.isBefore(cutoff)).toList();
    final older = scores.where((s) => s.createdAt.isBefore(cutoff)).toList();
    if (recent.isEmpty || older.isEmpty) return TrendDirection.stable;
    final rAvg = recent.map((s) => s.score).reduce((a, b) => a + b) / recent.length;
    final oAvg = older.map((s) => s.score).reduce((a, b) => a + b) / older.length;
    return trendFromDelta(rAvg - oAvg, epsilon: 0.12);
  }

  static String _achievementForRank(int rank, TrendDirection trend) {
    if (rank == 1) return 'gold';
    if (rank == 2) return 'silver';
    if (rank == 3) return 'bronze';
    if (trend == TrendDirection.up) return 'rising';
    return 'contender';
  }

  static int _trendWeight(TrendDirection t) => switch (t) {
        TrendDirection.up => 2,
        TrendDirection.stable => 1,
        TrendDirection.down => 0,
      };

  static String _trendLabel(TrendDirection t) => switch (t) {
        TrendDirection.up => 'accelerating',
        TrendDirection.down => 'cooling',
        TrendDirection.stable => 'steady',
      };

  static List<int> _histogram(List<double> values, {int bins = 10}) {
    final list = List<int>.filled(bins, 0);
    for (final v in values) {
      final idx = (v.floor()).clamp(0, bins - 1);
      list[idx]++;
    }
    return list;
  }

  static Map<String, int> _evaluationCountsByWeek(List<ScoreModel> scores, DateTime since) {
    final map = <String, int>{};
    for (final s in scores) {
      if (s.createdAt.isBefore(since)) continue;
      final key = _weekKey(s.createdAt);
      map[key] = (map[key] ?? 0) + 1;
    }
    final keys = map.keys.toList()..sort();
    final ordered = <String, int>{};
    for (final k in keys) {
      ordered[k] = map[k]!;
    }
    return ordered;
  }

  static String _weekKey(DateTime d) {
    final sunday = d.subtract(Duration(days: d.weekday % 7));
    return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
  }

  static String _ideaTitle(IdeaModel idea) {
    final t = idea.ideaTitle.trim();
    if (t.isNotEmpty) return t;
    if (idea.problemNumber.trim().isNotEmpty) return idea.problemNumber.trim();
    return idea.ideaId;
  }

  static String _displayName(UserModel u) {
    final n = '${u.firstName} ${u.lastName}'.trim();
    return n.isEmpty ? u.userId : n;
  }

}

class LeaderboardShowcaseVm {
  const LeaderboardShowcaseVm({
    required this.config,
    required this.teamRows,
    required this.departmentRows,
    required this.mentorRows,
    required this.ideaRows,
    required this.hero,
    required this.podium,
    required this.risingIdeaRows,
    required this.insights,
    required this.momentumSeries,
    required this.participationByDept,
    required this.comparativeAvgScoreByDept,
    required this.comparativeApprovalByDept,
    required this.evaluationHistogram,
    required this.trendingThemes,
    required this.judgeMode,
    required this.judgeEvaluationHistogram,
    required this.judgeTimeline,
  });

  final LeaderboardRoleConfig config;
  final List<TeamShowcaseRow> teamRows;
  final List<DepartmentShowcaseRow> departmentRows;
  final List<MentorShowcaseRow> mentorRows;
  final List<IdeaShowcaseRow> ideaRows;
  final LeaderboardHeroVm? hero;
  final List<TeamShowcaseRow> podium;
  final List<IdeaShowcaseRow> risingIdeaRows;
  final List<String> insights;
  final Map<String, int> momentumSeries;
  final Map<String, double> participationByDept;
  final Map<String, double> comparativeAvgScoreByDept;
  final Map<String, double> comparativeApprovalByDept;
  final List<int> evaluationHistogram;
  final List<String> trendingThemes;
  final bool judgeMode;
  final List<int> judgeEvaluationHistogram;
  final Map<String, int> judgeTimeline;
}

class LeaderboardHeroVm {
  const LeaderboardHeroVm({
    required this.spotlightTitle,
    required this.subtitle,
    required this.innovationScore,
    required this.rank,
    required this.trend,
    required this.achievementId,
    required this.departmentLabel,
  });

  final String spotlightTitle;
  final String subtitle;
  final double innovationScore;
  final int rank;
  final TrendDirection trend;
  final String achievementId;
  final String departmentLabel;
}

class TeamShowcaseRow {
  const TeamShowcaseRow({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.spotlightIdeaTitle,
    required this.departmentLabel,
    required this.finalScore,
    required this.trend,
    required this.achievementId,
  });

  final int rank;
  final String teamId;
  final String teamName;
  final String spotlightIdeaTitle;
  final String departmentLabel;
  final double finalScore;
  final TrendDirection trend;
  final String achievementId;
}

class DepartmentShowcaseRow {
  const DepartmentShowcaseRow({
    required this.rank,
    required this.departmentCode,
    required this.departmentLabel,
    required this.participationPct,
    required this.avgScore,
    required this.approvedIdeasPct,
    required this.innovationIndex,
    required this.topTeamName,
    required this.trend,
  });

  final int rank;
  final String departmentCode;
  final String departmentLabel;
  final double participationPct;
  final double avgScore;
  final double approvedIdeasPct;
  final double innovationIndex;
  final String topTeamName;
  final TrendDirection trend;
}

class MentorShowcaseRow {
  const MentorShowcaseRow({
    required this.rank,
    required this.mentorId,
    required this.mentorName,
    required this.teamsMentored,
    required this.avgTeamScore,
    required this.innovationSuccessPct,
    required this.approvedIdeasPct,
    required this.highestRankedTeamName,
    required this.trend,
  });

  final int rank;
  final String mentorId;
  final String mentorName;
  final int teamsMentored;
  final double avgTeamScore;
  final double innovationSuccessPct;
  final double approvedIdeasPct;
  final String highestRankedTeamName;
  final TrendDirection trend;
}

class IdeaShowcaseRow {
  const IdeaShowcaseRow({
    required this.rank,
    required this.ideaId,
    required this.title,
    required this.categoryTheme,
    required this.innovationScore,
    required this.finalScore,
    required this.trend,
    required this.achievementId,
  });

  final int rank;
  final String ideaId;
  final String title;
  final String categoryTheme;
  final double innovationScore;
  final double finalScore;
  final TrendDirection trend;
  final String achievementId;
}

class _IdeaScoreBundle {
  const _IdeaScoreBundle({
    required this.idea,
    required this.avgJudge,
    required this.composite,
    required this.innovationScore,
    required this.trend,
  });

  final IdeaModel idea;
  final double avgJudge;
  final double composite;
  final double innovationScore;
  final TrendDirection trend;
}

class _TeamAgg {
  const _TeamAgg({
    required this.team,
    required this.spotlight,
    required this.avgComposite,
    required this.deptLabel,
  });

  final TeamModel team;
  final _IdeaScoreBundle spotlight;
  final double avgComposite;
  final String deptLabel;
}
