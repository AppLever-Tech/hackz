import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../organization/models/department_model.dart';
import '../models/enums/team_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../models/payment_model.dart';
import '../../../models/score_model.dart';
import '../models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';

class TeamMemberPreview {
  const TeamMemberPreview({
    required this.userId,
    required this.displayName,
    required this.roleLabel,
    required this.isMentor,
  });

  final String userId;
  final String displayName;
  final String roleLabel;
  final bool isMentor;
}

class TeamIdeaPreview {
  const TeamIdeaPreview({
    required this.idea,
    required this.avgScore,
    required this.paymentStatus,
    required this.createdByName,
    required this.createdByUserId,
  });

  final IdeaModel idea;
  final double? avgScore;
  final PaymentRecordStatus? paymentStatus;
  final String createdByName;
  final String createdByUserId;
}

class TeamActivityItem {
  const TeamActivityItem({
    required this.at,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final DateTime at;
  final IconData icon;
  final String title;
  final String detail;
}

class TeamWorkspaceViewModel {
  const TeamWorkspaceViewModel({
    required this.team,
    required this.departmentLabel,
    required this.mentorName,
    required this.mentorId,
    required this.memberCount,
    required this.members,
    required this.ideas,
    required this.activeIdeas,
    required this.approvedIdeas,
    required this.evaluatedIdeas,
    required this.averageScore,
    required this.recentActivity,
  });

  final TeamModel team;
  final String departmentLabel;
  final String mentorName;
  final String mentorId;
  final int memberCount;
  final List<TeamMemberPreview> members;
  final List<TeamIdeaPreview> ideas;
  final int activeIdeas;
  final int approvedIdeas;
  final int evaluatedIdeas;
  final double? averageScore;
  final List<TeamActivityItem> recentActivity;
}

abstract final class TeamWorkspaceLoader {
  static Future<TeamWorkspaceViewModel> load(String teamId) async {
    final String id = teamId.trim();
    if (id.isEmpty) {
      throw ArgumentError('teamId must be non-empty');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> teamDoc =
        await db.collection(FirestoreUtils.hkzTeams).doc(id).get();
    if (!teamDoc.exists || teamDoc.data() == null) {
      throw StateError('Team not found');
    }

    final TeamModel team = TeamModel.fromMap(teamDoc.id, teamDoc.data()!);
    final String orgId = team.orgId.trim();
    final DepartmentModel? dept = DepartmentModel.byCode(team.departmentCode);
    final String departmentLabel = dept?.name ?? team.departmentCode;

    final Set<String> userIds = <String>{
      if (team.mentorId.trim().isNotEmpty) team.mentorId.trim(),
      ...team.studentIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };

    final List<dynamic> secondary = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchUsers(userIds),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzIdeas).limit(0).get(),
            )
          : db
              .collection(FirestoreUtils.hkzIdeas)
              .where('orgId', isEqualTo: orgId)
              .where('teamId', isEqualTo: team.teamId)
              .limit(200)
              .get(),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzPayments).limit(0).get(),
            )
          : db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).limit(500).get(),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzScores).limit(0).get(),
            )
          : db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).limit(800).get(),
    ]);

    final Map<String, UserModel> usersById = secondary[0] as Map<String, UserModel>;
    final QuerySnapshot<Map<String, dynamic>> ideasSnap = secondary[1] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> paymentsSnap = secondary[2] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> scoresSnap = secondary[3] as QuerySnapshot<Map<String, dynamic>>;

    final List<IdeaModel> ideas = ideasSnap.docs
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .toList(growable: false)
      ..sort((IdeaModel a, IdeaModel b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> ideaIds = ideas.map((IdeaModel i) => i.ideaId).toSet();

    final Map<String, PaymentRecordStatus> paymentByIdea = <String, PaymentRecordStatus>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in paymentsSnap.docs) {
      final PaymentModel p = PaymentModel.fromMap(doc.id, doc.data());
      if (!ideaIds.contains(p.ideaId)) continue;
      final PaymentRecordStatus? existing = paymentByIdea[p.ideaId];
      if (existing == null || _paymentRank(p.status) > _paymentRank(existing)) {
        paymentByIdea[p.ideaId] = p.status;
      }
    }

    final Map<String, List<ScoreModel>> scoresByIdea = <String, List<ScoreModel>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in scoresSnap.docs) {
      final ScoreModel s = ScoreModel.fromMap(doc.id, doc.data());
      if (!ideaIds.contains(s.ideaId)) continue;
      scoresByIdea.putIfAbsent(s.ideaId, () => <ScoreModel>[]).add(s);
    }

    final UserModel? mentor = usersById[team.mentorId.trim()];
    final String mentorName = mentor == null
        ? (team.mentorId.trim().isEmpty ? '—' : team.mentorId.trim())
        : userDisplayName(mentor);

    final List<TeamMemberPreview> members = <TeamMemberPreview>[
      if (team.mentorId.trim().isNotEmpty)
        TeamMemberPreview(
          userId: team.mentorId.trim(),
          displayName: mentorName,
          roleLabel: 'Mentor',
          isMentor: true,
        ),
      ...team.studentIds.map((String studentId) {
        final UserModel? student = usersById[studentId.trim()];
        final String name = student == null
            ? studentId.trim()
            : userDisplayName(student);
        return TeamMemberPreview(
          userId: studentId.trim(),
          displayName: name,
          roleLabel: 'Student',
          isMentor: false,
        );
      }),
    ];

    final List<TeamIdeaPreview> ideaPreviews = ideas.map((IdeaModel idea) {
      final List<ScoreModel> sc = scoresByIdea[idea.ideaId] ?? const <ScoreModel>[];
      final double? avg = sc.isEmpty
          ? null
          : sc.map((ScoreModel e) => e.score).reduce((double a, double b) => a + b) / sc.length;
      final UserModel? creator = usersById[idea.createdBy.trim()];
      return TeamIdeaPreview(
        idea: idea,
        avgScore: avg,
        paymentStatus: paymentByIdea[idea.ideaId],
        createdByName: creator == null ? idea.createdBy : userDisplayName(creator),
        createdByUserId: idea.createdBy,
      );
    }).toList(growable: false);

    final int activeIdeas = ideas
        .where((IdeaModel i) => i.status != IdeaStatus.approved && i.status != IdeaStatus.rejected)
        .length;
    final int approvedIdeas = ideas.where((IdeaModel i) => i.status == IdeaStatus.approved).length;
    final int evaluatedIdeas = ideas.where((IdeaModel i) => (scoresByIdea[i.ideaId]?.isNotEmpty ?? false)).length;

    final List<double> ideaAvgs = ideaPreviews
        .map((TeamIdeaPreview e) => e.avgScore)
        .whereType<double>()
        .toList(growable: false);
    final double? averageScore = ideaAvgs.isEmpty
        ? null
        : ideaAvgs.reduce((double a, double b) => a + b) / ideaAvgs.length;

    final List<TeamActivityItem> activity = _buildActivity(ideas, scoresByIdea, paymentByIdea);

    return TeamWorkspaceViewModel(
      team: team,
      departmentLabel: departmentLabel.trim().isEmpty ? '—' : departmentLabel.trim(),
      mentorName: mentorName,
      mentorId: team.mentorId.trim(),
      memberCount: team.studentIds.length,
      members: members,
      ideas: ideaPreviews,
      activeIdeas: activeIdeas,
      approvedIdeas: approvedIdeas,
      evaluatedIdeas: evaluatedIdeas,
      averageScore: averageScore,
      recentActivity: activity.length <= 8 ? activity : activity.sublist(0, 8),
    );
  }

  static Future<Map<String, UserModel>> _fetchUsers(Set<String> userIds) async {
    final Map<String, UserModel> out = <String, UserModel>{};
    final List<String> ids = userIds.where((e) => e.isNotEmpty).toList(growable: false);
    await Future.wait<void>(
      ids.map((String id) async {
        final UserModel? u = await FirestoreUtils.fetchUser(id);
        if (u != null) {
          out[id] = u;
        }
      }),
    );
    return out;
  }

  static int _paymentRank(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 3,
      PaymentRecordStatus.pending => 2,
      PaymentRecordStatus.rejected => 1,
    };
  }

  static List<TeamActivityItem> _buildActivity(
    List<IdeaModel> ideas,
    Map<String, List<ScoreModel>> scoresByIdea,
    Map<String, PaymentRecordStatus> paymentByIdea,
  ) {
    final List<TeamActivityItem> lines = <TeamActivityItem>[];

    for (final IdeaModel idea in ideas) {
      final String title = idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim();
      if (idea.status != IdeaStatus.pendingSubmission) {
        lines.add(
          TeamActivityItem(
            at: idea.createdAt,
            icon: AppIcons.ideas,
            title: 'Idea submitted',
            detail: title,
          ),
        );
      }
      final List<ScoreModel> scores = scoresByIdea[idea.ideaId] ?? const <ScoreModel>[];
      for (final ScoreModel score in scores) {
        lines.add(
          TeamActivityItem(
            at: score.createdAt,
            icon: AppIcons.scoring,
            title: 'Evaluation recorded',
            detail: '$title · ${score.score.toStringAsFixed(1)}',
          ),
        );
      }
      final PaymentRecordStatus? pay = paymentByIdea[idea.ideaId];
      if (pay != null) {
        lines.add(
          TeamActivityItem(
            at: idea.createdAt,
            icon: AppIcons.payments,
            title: _paymentActivityTitle(pay),
            detail: title,
          ),
        );
      }
    }

    lines.sort((TeamActivityItem a, TeamActivityItem b) => b.at.compareTo(a.at));
    return lines;
  }

  static String _paymentActivityTitle(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 'Payment verified',
      PaymentRecordStatus.rejected => 'Payment rejected',
      PaymentRecordStatus.pending => 'Payment pending',
    };
  }
}

String teamStatusLabel(TeamStatus status) {
  return switch (status) {
    TeamStatus.active => 'Active',
    TeamStatus.inactive => 'Inactive',
    TeamStatus.locked => 'Locked',
  };
}
