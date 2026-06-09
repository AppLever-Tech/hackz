import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../evaluations/models/score_model.dart';
import '../models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';

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
    required this.recentActivity,
  });

  final UserModel user;
  final String? organizationName;
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
        recentActivity: const <UserActivityItem>[],
      );
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;

    final List<Object?> secondary = await Future.wait<Object?>(<Future<Object?>>[
      _organizationName(orgId),
      _ideaActivity(db, orgId, id),
      _scoreActivity(db, orgId, id),
    ]);

    final String? orgName = secondary[0] as String?;
    final List<UserActivityItem> ideaLines = secondary[1]! as List<UserActivityItem>;
    final List<UserActivityItem> scoreLines = secondary[2]! as List<UserActivityItem>;

    final List<UserActivityItem> merged = <UserActivityItem>[
      ...ideaLines,
      ...scoreLines,
    ]..sort((UserActivityItem a, UserActivityItem b) => b.at.compareTo(a.at));

    final List<UserActivityItem> recent = merged.length <= 6
        ? merged
        : merged.sublist(0, 6);

    return UserWorkspaceViewModel(
      user: user,
      organizationName: orgName,
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

Future<List<UserActivityItem>> _ideaActivity(
  FirebaseFirestore db,
  String orgId,
  String userId,
) async {
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

    return inOrg.take(4).map((IdeaModel idea) {
      return UserActivityItem(
        at: idea.createdAt,
        icon: AppIcons.ideas,
        title: idea.ideaTitle.trim().isEmpty ? 'Idea submission' : idea.ideaTitle.trim(),
        detail: '${_ideaStatusLabel(idea.status)} · ${formatDateTime(idea.createdAt)}',
      );
    }).toList(growable: false);
  } catch (_) {
    return const <UserActivityItem>[];
  }
}

Future<List<UserActivityItem>> _scoreActivity(
  FirebaseFirestore db,
  String orgId,
  String userId,
) async {
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

    return inOrg.take(4).map((ScoreModel s) {
      return UserActivityItem(
        at: s.createdAt,
        icon: AppIcons.scoring,
        title: 'Evaluation recorded',
        detail: 'Score ${s.score.toStringAsFixed(1)} · ${formatDateTime(s.createdAt)}',
      );
    }).toList(growable: false);
  } catch (_) {
    return const <UserActivityItem>[];
  }
}

String _ideaStatusLabel(IdeaStatus status) => IdeaStatusHelpers.label(status);
