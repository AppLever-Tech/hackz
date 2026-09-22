import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import 'certificate_selectable_entry.dart';

/// Loads team rosters for individual certificate expansion.
abstract final class CertificateTeamMemberLoader {
  CertificateTeamMemberLoader._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<Map<String, List<CertificateMember>>> membersByTeamId(
    Iterable<String> teamIds,
  ) async {
    final Set<String> ids = teamIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return const <String, List<CertificateMember>>{};

    final List<DocumentSnapshot<Map<String, dynamic>>> teamDocs = await Future.wait(
      ids.map((String id) => _db.collection(FirestoreUtils.hkzTeams).doc(id).get()),
    );

    final Map<String, TeamModel> teams = <String, TeamModel>{};
    final Set<String> userIds = <String>{};
    for (final DocumentSnapshot<Map<String, dynamic>> doc in teamDocs) {
      if (!doc.exists || doc.data() == null) continue;
      final TeamModel team = TeamModel.fromMap(doc.id, doc.data()!);
      teams[team.teamId] = team;
      userIds.addAll(team.studentIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty));
    }

    final Map<String, UserModel> users = await _loadUsers(userIds);
    final Map<String, List<CertificateMember>> byTeam = <String, List<CertificateMember>>{};
    for (final TeamModel team in teams.values) {
      final List<CertificateMember> members = <CertificateMember>[];
      for (final String studentId in team.studentIds) {
        final String id = studentId.trim();
        if (id.isEmpty) continue;
        final UserModel? user = users[id];
        final String name = user == null ? id : userDisplayName(user);
        members.add(CertificateMember(userId: id, displayName: name));
      }
      if (members.isNotEmpty) {
        byTeam[team.teamId] = members;
      }
    }
    return byTeam;
  }

  static Future<Map<String, UserModel>> _loadUsers(Set<String> userIds) async {
    final Map<String, UserModel> byId = <String, UserModel>{};
    final List<String> ids = userIds.toList(growable: false);
    const int chunk = 12;
    for (int i = 0; i < ids.length; i += chunk) {
      final List<String> slice = ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final List<UserModel?> fetched = await Future.wait(slice.map(FirestoreUtils.fetchUser));
      for (int j = 0; j < slice.length; j++) {
        final UserModel? user = fetched[j];
        if (user != null) byId[slice[j]] = user;
      }
    }
    return byId;
  }
}
