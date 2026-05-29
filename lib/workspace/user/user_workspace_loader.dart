import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/idea_model.dart';
import '../../models/score_model.dart';
import '../../features/team/models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';

/// One line in the read-only “recent activity” summary.
class UserActivityItem {
  const UserActivityItem({
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

/// Lightweight summary for the user workspace (no nested entities).
class UserWorkspaceViewModel {
  const UserWorkspaceViewModel({
    required this.user,
    required this.organizationName,
    required this.teamLinksCount,
    required this.submittedIdeasCount,
    required this.evaluationCount,
    required this.recentActivity,
  });

  final UserModel user;
  final String? organizationName;
  final int teamLinksCount;
  final int submittedIdeasCount;
  final int evaluationCount;
  final List<UserActivityItem> recentActivity;
}

abstract final class UserWorkspaceLoader {
  static Future<UserWorkspaceViewModel> load(String userId) async {
    final String id = userId.trim();
    if (id.isEmpty) {
      throw ArgumentError('userId must be non-empty');
    }

    final UserModel? user = await FirestoreUtils.fetchUser(id);
    if (user == null) {
      throw StateError('User not found');
    }

    final String orgId = user.orgId.trim();
    if (orgId.isEmpty) {
      return UserWorkspaceViewModel(
        user: user,
        organizationName: null,
        teamLinksCount: 0,
        submittedIdeasCount: 0,
        evaluationCount: 0,
        recentActivity: const <UserActivityItem>[],
      );
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;

    final List<Object?> secondary = await Future.wait<Object?>(<Future<Object?>>[
      _organizationName(orgId),
      _teamBundle(db, orgId, id),
      _ideaBundle(db, orgId, id),
      _scoreBundle(db, orgId, id),
    ]);

    final String? orgName = secondary[0] as String?;
    final _TeamAgg teams = secondary[1]! as _TeamAgg;
    final _IdeaAgg ideas = secondary[2]! as _IdeaAgg;
    final _ScoreAgg scores = secondary[3]! as _ScoreAgg;

    final List<UserActivityItem> merged = <UserActivityItem>[
      ...ideas.activity,
      ...scores.activity,
    ]..sort((UserActivityItem a, UserActivityItem b) => b.at.compareTo(a.at));

    final List<UserActivityItem> recent = merged.length <= 6
        ? merged
        : merged.sublist(0, 6);

    return UserWorkspaceViewModel(
      user: user,
      organizationName: orgName,
      teamLinksCount: teams.count,
      submittedIdeasCount: ideas.count,
      evaluationCount: scores.count,
      recentActivity: recent,
    );
  }

  static Future<String?> _organizationName(String orgId) async {
    try {
      final org = await FirestoreUtils.fetchOrganization(orgId);
      final String n = org?.name.trim() ?? '';
      return n.isEmpty ? null : n;
    } catch (_) {
      return null;
    }
  }
}

class _TeamAgg {
  const _TeamAgg(this.count, this.activity);
  final int count;
  final List<UserActivityItem> activity;
}

class _IdeaAgg {
  const _IdeaAgg(this.count, this.activity);
  final int count;
  final List<UserActivityItem> activity;
}

class _ScoreAgg {
  const _ScoreAgg(this.count, this.activity);
  final int count;
  final List<UserActivityItem> activity;
}

Future<_TeamAgg> _teamBundle(FirebaseFirestore db, String orgId, String userId) async {
  try {
    final QuerySnapshot<Map<String, dynamic>> asMentor = await db
        .collection(FirestoreUtils.hkzTeams)
        .where('mentorId', isEqualTo: userId)
        .limit(200)
        .get();

    final QuerySnapshot<Map<String, dynamic>> asStudent = await db
        .collection(FirestoreUtils.hkzTeams)
        .where('studentIds', arrayContains: userId)
        .limit(200)
        .get();

    final Set<String> teamIds = <String>{};
    final List<UserActivityItem> lines = <UserActivityItem>[];

    void ingest(QuerySnapshot<Map<String, dynamic>> snap, {required bool asMentorRole}) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final TeamModel t = TeamModel.fromMap(doc.id, doc.data());
        if (t.orgId != orgId) continue;
        teamIds.add(t.teamId);
        if (lines.length < 4) {
          lines.add(
            UserActivityItem(
              at: t.createdAt,
              icon: asMentorRole ? AppIcons.teams : AppIcons.student,
              title: asMentorRole ? 'Mentoring team' : 'Team membership',
              detail: t.teamName.trim().isEmpty ? t.teamId : t.teamName.trim(),
            ),
          );
        }
      }
    }

    ingest(asMentor, asMentorRole: true);
    ingest(asStudent, asMentorRole: false);

    lines.sort((UserActivityItem a, UserActivityItem b) => b.at.compareTo(a.at));
    return _TeamAgg(teamIds.length, lines);
  } catch (_) {
    return const _TeamAgg(0, <UserActivityItem>[]);
  }
}

Future<_IdeaAgg> _ideaBundle(FirebaseFirestore db, String orgId, String userId) async {
  try {
    final QuerySnapshot<Map<String, dynamic>> snap = await db
        .collection(FirestoreUtils.hkzIdeas)
        .where('createdBy', isEqualTo: userId)
        .limit(200)
        .get();

    final List<IdeaModel> inOrg = <IdeaModel>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (idea.orgId != orgId) continue;
      inOrg.add(idea);
    }

    inOrg.sort((IdeaModel a, IdeaModel b) => b.createdAt.compareTo(a.createdAt));

    final List<UserActivityItem> activity = inOrg.take(4).map((IdeaModel idea) {
      return UserActivityItem(
        at: idea.createdAt,
        icon: AppIcons.ideas,
        title: idea.ideaTitle.trim().isEmpty ? 'Idea submission' : idea.ideaTitle.trim(),
        detail: '${_ideaStatusLabel(idea.status)} · ${formatDateTime(idea.createdAt)}',
      );
    }).toList(growable: false);

    return _IdeaAgg(inOrg.length, activity);
  } catch (_) {
    return const _IdeaAgg(0, <UserActivityItem>[]);
  }
}

Future<_ScoreAgg> _scoreBundle(FirebaseFirestore db, String orgId, String userId) async {
  try {
    final QuerySnapshot<Map<String, dynamic>> snap = await db
        .collection(FirestoreUtils.hkzScores)
        .where('judgeId', isEqualTo: userId)
        .limit(200)
        .get();

    final List<ScoreModel> inOrg = <ScoreModel>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final ScoreModel s = ScoreModel.fromMap(doc.id, doc.data());
      if (s.orgId != orgId) continue;
      inOrg.add(s);
    }

    inOrg.sort((ScoreModel a, ScoreModel b) => b.createdAt.compareTo(a.createdAt));

    final List<UserActivityItem> activity = inOrg.take(4).map((ScoreModel s) {
      return UserActivityItem(
        at: s.createdAt,
        icon: AppIcons.scoring,
        title: 'Evaluation recorded',
        detail: 'Score ${s.score.toStringAsFixed(1)} · ${formatDateTime(s.createdAt)}',
      );
    }).toList(growable: false);

    return _ScoreAgg(inOrg.length, activity);
  } catch (_) {
    return const _ScoreAgg(0, <UserActivityItem>[]);
  }
}

String _ideaStatusLabel(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.pendingSubmission => 'Pending submission',
    IdeaStatus.submitted => 'Submitted',
    IdeaStatus.underReview => 'Under review',
    IdeaStatus.evaluated => 'Evaluated',
    IdeaStatus.approved => 'Approved',
    IdeaStatus.rejected => 'Rejected',
  };
}
