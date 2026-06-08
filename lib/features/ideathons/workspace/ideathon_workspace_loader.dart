import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../services/ideathon_service.dart';

class IdeathonWorkspaceViewModel {
  const IdeathonWorkspaceViewModel({
    required this.ideathon,
    required this.judges,
    required this.coordinators,
    required this.evaluationProgressLabel,
    required this.evaluationProgressPct,
  });

  final IdeathonModel ideathon;
  final List<UserModel> judges;
  final List<UserModel> coordinators;
  final String evaluationProgressLabel;
  final double evaluationProgressPct;
}

abstract final class IdeathonWorkspaceLoader {
  IdeathonWorkspaceLoader._();

  static Future<IdeathonWorkspaceViewModel> load(String ideathonId) async {
    final IdeathonModel? ideathon = await IdeathonService.fetchById(ideathonId);
    if (ideathon == null) throw StateError('Ideathon not found');

    final List<UserModel> judges = await _fetchUsers(ideathon.judgeIds);
    final List<UserModel> coordinators = await _fetchUsers(ideathon.coordinatorIds);

    final int totalExpected = ideathon.ideaCount * ideathon.judgeCount;
    int completed = 0;
    if (totalExpected > 0) {
      final QuerySnapshot<Map<String, dynamic>> scores = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzScores)
          .where('orgId', isEqualTo: ideathon.orgId)
          .where('ideathonId', isEqualTo: ideathon.ideathonId)
          .get();
      completed = scores.docs.length;
    }
    final double pct = totalExpected == 0 ? 0 : (completed / totalExpected).clamp(0.0, 1.0);
    final String label = totalExpected == 0
        ? 'No evaluations expected'
        : '$completed / $totalExpected evaluations';

    return IdeathonWorkspaceViewModel(
      ideathon: ideathon,
      judges: judges,
      coordinators: coordinators,
      evaluationProgressLabel: label,
      evaluationProgressPct: pct,
    );
  }

  static Future<List<UserModel>> _fetchUsers(List<String> ids) async {
    final List<UserModel> users = <UserModel>[];
    for (final String raw in ids) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      final UserModel? user = await FirestoreUtils.fetchUser(id);
      if (user != null) users.add(user);
    }
    users.sort((UserModel a, UserModel b) => userDisplayName(a).compareTo(userDisplayName(b)));
    return users;
  }
}
