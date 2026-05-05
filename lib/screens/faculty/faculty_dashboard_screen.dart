import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/idea_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../common/dashboard_components.dart';
import 'teams_screen.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({
    super.key,
    required this.user,
    required this.refreshToken,
    required this.section,
  });

  final UserModel user;
  final int refreshToken;
  final FacultyDashboardSection section;

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  late Future<_FacultyDashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant FacultyDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _dataFuture = _loadData();
    }
  }

  Future<_FacultyDashboardData> _loadData() async {
    final db = FirebaseFirestore.instance;
    final teams = await FirestoreUtils.getFacultyTeams(widget.user.userId);
    final ideasSnap = await db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: widget.user.orgId).get();

    final departmentCode = widget.user.departmentCode.trim().toUpperCase();
    final facultyIdeas = ideasSnap.docs.where((doc) {
      final data = doc.data();
      final ideaDepartmentCode = ((data['departmentCode'] as String?) ?? '').trim().toUpperCase();
      final creator = ((data['createdBy'] as String?) ?? '').trim();
      return ideaDepartmentCode == departmentCode && creator == widget.user.userId;
    }).toList(growable: false);

    int pendingPayment = 0;
    int submittedAfterPayment = 0;
    int underReview = 0;
    int evaluated = 0;
    for (final doc in facultyIdeas) {
      final st = IdeaStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      if (st == IdeaStatus.pendingSubmission) {
        pendingPayment++;
      } else {
        submittedAfterPayment++;
      }
      if (st == IdeaStatus.evaluated) {
        evaluated++;
      } else if (st == IdeaStatus.underReview) {
        underReview++;
      }
    }

    final ideaViews = facultyIdeas.map((doc) {
      final data = doc.data();
      return _IdeaView(
        problemNumber: ((data['problemNumber'] as String?) ?? '').trim(),
        title: ((data['title'] as String?) ?? 'Untitled Idea').trim(),
        status: IdeaStatus.fromRaw((data['status'] as String?) ?? '').value,
        score: (data['score'] as num?)?.toDouble(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList(growable: false)
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));

    final activities = <_ActivityView>[
      ...ideaViews.take(8).map(
        (idea) => _ActivityView(
          title: idea.status == IdeaStatus.pendingSubmission.value ? 'Idea awaiting payment' : 'Idea submitted',
          subtitle: idea.title,
          time: idea.createdAt,
        ),
      ),
      ...teams.take(6).map(
        (team) => _ActivityView(
          title: 'Team created',
          subtitle: team.name,
          time: team.createdAt,
        ),
      ),
      ...ideaViews
          .where((i) => i.status.toLowerCase().contains('review') || i.status.toLowerCase() == 'evaluated')
          .take(8)
          .map(
            (idea) => _ActivityView(
              title: 'Evaluation update',
              subtitle: '${idea.title} (${idea.status})',
              time: idea.createdAt,
            ),
          ),
    ];

    return _FacultyDashboardData(
      myTeams: teams.length,
      ideasSubmitted: submittedAfterPayment,
      pendingPayment: pendingPayment,
      underReview: underReview,
      evaluated: evaluated,
      teams: teams,
      ideas: ideaViews,
      activities: activities.take(12).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FacultyDashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load faculty dashboard: ${snapshot.error}');
        }
        final data = snapshot.data ?? const _FacultyDashboardData.empty();
        if (widget.section == FacultyDashboardSection.teams) {
          return TeamsScreen(user: widget.user);
        }
        if (widget.section == FacultyDashboardSection.ideas) {
          return _buildIdeasSection(data.ideas);
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(data),
              const SizedBox(height: 16),
              _buildRecentActivity(data.activities),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(_FacultyDashboardData data) {
    const double spacing = 16;
    final double maxW = MediaQuery.sizeOf(context).width;
    final double cardW = ((maxW - 32 - spacing * 4) / 5).clamp(130.0, 320.0);
    Widget card(SummaryCard c) => SizedBox(width: cardW, child: c);
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: <Widget>[
        card(
          SummaryCard(
            value: '${data.myTeams}',
            label: 'My Teams',
            icon: Icons.groups_outlined,
            iconBgColor: const Color(0xFFEAF2FF),
          ),
        ),
        card(
          SummaryCard(
            value: '${data.ideasSubmitted}',
            label: 'Submitted',
            icon: Icons.lightbulb_outline,
            iconBgColor: const Color(0xFFF2EDFF),
          ),
        ),
        card(
          SummaryCard(
            value: '${data.pendingPayment}',
            label: 'Awaiting payment',
            icon: Icons.payment_outlined,
            iconBgColor: const Color(0xFFFFF8E6),
          ),
        ),
        card(
          SummaryCard(
            value: '${data.underReview}',
            label: 'Under Review',
            icon: Icons.rate_review_outlined,
            iconBgColor: const Color(0xFFFFF4E8),
          ),
        ),
        card(
          SummaryCard(
            value: '${data.evaluated}',
            label: 'Evaluated',
            icon: Icons.verified_outlined,
            iconBgColor: const Color(0xFFE8FAF1),
          ),
        ),
      ],
    );
  }

  Widget _buildIdeasSection(List<_IdeaView> ideas) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ideas Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildIdeas(ideas),
        ],
      ),
    );
  }

  Widget _buildIdeas(List<_IdeaView> ideas) {
    if (ideas.isEmpty) return const Text('No ideas submitted by this faculty yet.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ideas.length,
      itemBuilder: (context, index) {
        final idea = ideas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${idea.problemNumber.isEmpty ? 'N/A' : idea.problemNumber} • ${idea.title}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Status: ${idea.status}'),
                    Text('Score: ${idea.score?.toStringAsFixed(1) ?? '-'}'),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('View Details'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(List<_ActivityView> activities) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            const Text('No recent activity.')
          else
            ...activities.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF6A38FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${a.title}: ${a.subtitle}'),
                    ),
                    if (a.time != null)
                      Text(
                        _formatDate(a.time!),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }
}

enum FacultyDashboardSection {
  dashboard,
  teams,
  ideas,
  problems,
}

class _FacultyDashboardData {
  const _FacultyDashboardData({
    required this.myTeams,
    required this.ideasSubmitted,
    required this.pendingPayment,
    required this.underReview,
    required this.evaluated,
    required this.teams,
    required this.ideas,
    required this.activities,
  });

  const _FacultyDashboardData.empty()
      : myTeams = 0,
        ideasSubmitted = 0,
        pendingPayment = 0,
        underReview = 0,
        evaluated = 0,
        teams = const <TeamModel>[],
        ideas = const <_IdeaView>[],
        activities = const <_ActivityView>[];

  final int myTeams;
  final int ideasSubmitted;
  final int pendingPayment;
  final int underReview;
  final int evaluated;
  final List<TeamModel> teams;
  final List<_IdeaView> ideas;
  final List<_ActivityView> activities;
}

class _IdeaView {
  const _IdeaView({
    required this.problemNumber,
    required this.title,
    required this.status,
    required this.score,
    required this.createdAt,
  });

  final String problemNumber;
  final String title;
  final String status;
  final double? score;
  final DateTime? createdAt;
}

class _ActivityView {
  const _ActivityView({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String title;
  final String subtitle;
  final DateTime? time;
}
