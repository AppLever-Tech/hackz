import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../organization/models/organization_model.dart';
import '../../payment/models/payment_model.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_type.dart';

/// How a team relates to the Ideathon host organisation.
enum IdeathonTeamOrigin {
  host,
  otherOrganisation,
  mixed;

  String get pillLabel => switch (this) {
        IdeathonTeamOrigin.host => 'Host',
        IdeathonTeamOrigin.otherOrganisation => 'External',
        IdeathonTeamOrigin.mixed => 'Mixed',
      };
}

/// Paid, submitted idea plus team/organisation context for Ideathon selection.
class IdeathonEligibleIdea {
  const IdeathonEligibleIdea({
    required this.idea,
    required this.origin,
    this.team,
    this.organisationName = '',
  });

  final IdeaModel idea;
  final TeamModel? team;
  final IdeathonTeamOrigin origin;
  final String organisationName;

  String get teamName {
    final String name = team?.teamName.trim() ?? '';
    return name;
  }
}

/// Single eligibility helper for Internal vs External Ideathon team selection.
abstract final class IdeathonTeamEligibility {
  IdeathonTeamEligibility._();

  static bool isOriginEligible(IdeathonType type, IdeathonTeamOrigin origin) {
    return switch (type) {
      IdeathonType.internal => origin == IdeathonTeamOrigin.host,
      IdeathonType.external => true,
    };
  }

  static IdeathonTeamOrigin classify({
    required String hostOrgId,
    required TeamModel team,
    required Iterable<UserModel> members,
  }) {
    final String host = hostOrgId.trim();
    final String teamOrg = team.orgId.trim();
    if (teamOrg.isNotEmpty && host.isNotEmpty && teamOrg != host) {
      return IdeathonTeamOrigin.otherOrganisation;
    }

    for (final UserModel member in members) {
      final String memberOrg = member.orgId.trim();
      if (memberOrg.isEmpty) continue;
      if (teamOrg.isNotEmpty && memberOrg != teamOrg) {
        return IdeathonTeamOrigin.mixed;
      }
      if (host.isNotEmpty && memberOrg != host) {
        return IdeathonTeamOrigin.mixed;
      }
    }
    return IdeathonTeamOrigin.host;
  }

  static List<IdeathonEligibleIdea> filterForType(
    List<IdeathonEligibleIdea> catalog,
    IdeathonType type,
  ) {
    return catalog
        .where((IdeathonEligibleIdea row) => isOriginEligible(type, row.origin))
        .toList(growable: false);
  }

  /// Paid submitted ideas with team origin, for the host organisation's catalog.
  static Future<List<IdeathonEligibleIdea>> loadPaidIdeas({required String hostOrgId}) async {
    final String host = hostOrgId.trim();
    if (host.isEmpty) return const <IdeathonEligibleIdea>[];

    final List<IdeaModel> candidates = await _loadCandidateIdeas(hostOrgId: host);
    if (candidates.isEmpty) return const <IdeathonEligibleIdea>[];

    final Set<String> verifiedIdeaIds = await _verifiedIdeaIdsFor(
      candidates.map((IdeaModel i) => i.orgId.trim()).where((String id) => id.isNotEmpty).toSet()
        ..add(host),
    );

    final List<IdeaModel> paid = candidates
        .where((IdeaModel idea) => verifiedIdeaIds.contains(idea.ideaId.trim()))
        .toList(growable: false);
    if (paid.isEmpty) return const <IdeathonEligibleIdea>[];

    final Map<String, TeamModel> teamsById = await _loadTeams(
      paid.map((IdeaModel i) => i.teamId.trim()).where((String id) => id.isNotEmpty).toSet(),
    );
    final Set<String> memberIds = <String>{};
    for (final TeamModel team in teamsById.values) {
      memberIds.addAll(team.studentIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty));
    }
    final Map<String, UserModel> membersById = await _loadUsers(memberIds);
    final Map<String, String> orgNames = await _orgNames(
      <String>{
        host,
        ...teamsById.values.map((TeamModel t) => t.orgId.trim()),
        ...membersById.values.map((UserModel u) => u.orgId.trim()),
      }.where((String id) => id.isNotEmpty).toSet(),
    );

    final List<IdeathonEligibleIdea> rows = <IdeathonEligibleIdea>[];
    for (final IdeaModel idea in paid) {
      final TeamModel? team = teamsById[idea.teamId.trim()];
      if (team == null) continue;
      final List<UserModel> members = team.studentIds
          .map((String id) => membersById[id.trim()])
          .whereType<UserModel>()
          .toList(growable: false);
      final IdeathonTeamOrigin origin = classify(hostOrgId: host, team: team, members: members);
      final String orgId = team.orgId.trim().isEmpty ? host : team.orgId.trim();
      rows.add(
        IdeathonEligibleIdea(
          idea: idea,
          team: team,
          origin: origin,
          organisationName: orgNames[orgId] ?? orgId,
        ),
      );
    }

    rows.sort(
      (IdeathonEligibleIdea a, IdeathonEligibleIdea b) => a.idea.ideaTitle.compareTo(b.idea.ideaTitle),
    );
    return rows;
  }

  static Future<List<IdeaModel>> _loadCandidateIdeas({required String hostOrgId}) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final QuerySnapshot<Map<String, dynamic>> hostSnap = await db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: hostOrgId)
        .get();
    final Map<String, IdeaModel> byId = <String, IdeaModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in hostSnap.docs) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (IdeaStatusHelpers.isEligibleForIdeathon(idea.status)) {
        byId[idea.ideaId] = idea;
      }
    }

    final QuerySnapshot<Map<String, dynamic>> submittedSnap = await db
        .collection(FirestoreUtils.hkzIdeas)
        .where('status', isEqualTo: 'submitted')
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in submittedSnap.docs) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (idea.orgId.trim() == hostOrgId) continue;
      if (!IdeaStatusHelpers.isEligibleForIdeathon(idea.status)) continue;
      byId.putIfAbsent(idea.ideaId, () => idea);
    }

    return byId.values.toList(growable: false);
  }

  static Future<Set<String>> _verifiedIdeaIdsFor(Set<String> orgIds) async {
    final Set<String> verified = <String>{};
    final List<String> ids = orgIds.toList(growable: false);
    final List<List<PaymentModel>> groups = await Future.wait(
      ids.map(FirestoreUtils.getPaymentsByOrg),
    );
    for (final List<PaymentModel> payments in groups) {
      for (final PaymentModel payment in payments) {
        if (payment.status == PaymentRecordStatus.verified && payment.ideaId.trim().isNotEmpty) {
          verified.add(payment.ideaId.trim());
        }
      }
    }
    return verified;
  }

  static Future<Map<String, TeamModel>> _loadTeams(Set<String> teamIds) async {
    final Map<String, TeamModel> byId = <String, TeamModel>{};
    if (teamIds.isEmpty) return byId;
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
      teamIds.map(
        (String id) => db.collection(FirestoreUtils.hkzTeams).doc(id).get(),
      ),
    );
    for (final DocumentSnapshot<Map<String, dynamic>> doc in docs) {
      if (!doc.exists || doc.data() == null) continue;
      byId[doc.id] = TeamModel.fromMap(doc.id, doc.data()!);
    }
    return byId;
  }

  static Future<Map<String, UserModel>> _loadUsers(Set<String> userIds) async {
    final Map<String, UserModel> byId = <String, UserModel>{};
    if (userIds.isEmpty) return byId;
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
      userIds.map(
        (String id) => db.collection(FirestoreUtils.hkzUsers).doc(id).get(),
      ),
    );
    for (final DocumentSnapshot<Map<String, dynamic>> doc in docs) {
      if (!doc.exists || doc.data() == null) continue;
      UserModel user = UserModel.fromMap(doc.data()!);
      if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
      byId[user.userId] = user;
    }
    return byId;
  }

  static Future<Map<String, String>> _orgNames(Set<String> orgIds) async {
    final Map<String, String> names = <String, String>{};
    if (orgIds.isEmpty) return names;
    final List<OrganizationModel?> orgs = await Future.wait(
      orgIds.map(FirestoreUtils.fetchOrganization),
    );
    for (final OrganizationModel? org in orgs) {
      if (org == null) continue;
      final String name = org.name.trim();
      names[org.id] = name.isEmpty ? org.id : name;
    }
    return names;
  }
}
