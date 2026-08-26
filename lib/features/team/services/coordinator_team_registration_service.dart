import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../ideathons/models/ideathon_participation.dart';
import '../../ideathons/models/ideathon_type.dart';
import '../../ideathons/services/ideathon_participation_service.dart';
import '../../ideathons/services/ideathon_service.dart';
import '../../ideathons/services/ideathon_team_eligibility.dart';
import '../../user/models/user_model.dart';
import '../models/team_model.dart';
import 'team_service.dart';

enum TeamRegistrationOriginFilter { all, internal, external }

class CoordinatorTeamRegistrationRow {
  const CoordinatorTeamRegistrationRow({
    required this.team,
    required this.origin,
    required this.ideathonName,
    required this.ideathonId,
    required this.importedAt,
  });

  final TeamModel team;
  final IdeathonTeamOrigin origin;
  final String ideathonName;
  final String ideathonId;
  final DateTime importedAt;

  bool get isInternal => origin == IdeathonTeamOrigin.host;

  String get originLabel =>
      isInternal ? IdeathonType.internal.label : IdeathonType.external.label;

  IdeathonType get originType => isInternal ? IdeathonType.internal : IdeathonType.external;
}

class CoordinatorTeamRegistrationSnapshot {
  const CoordinatorTeamRegistrationSnapshot({
    required this.orgName,
    required this.rows,
  });

  final String orgName;
  final List<CoordinatorTeamRegistrationRow> rows;
}

/// Teams this coordinator registered, with origin and Ideathon association.
abstract final class CoordinatorTeamRegistrationService {
  CoordinatorTeamRegistrationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<CoordinatorTeamRegistrationSnapshot> load(UserModel actor) async {
    final String orgId = actor.orgId.trim();
    final String coordinatorId = actor.userId.trim();
    if (orgId.isEmpty || coordinatorId.isEmpty) {
      return const CoordinatorTeamRegistrationSnapshot(orgName: '', rows: <CoordinatorTeamRegistrationRow>[]);
    }

    final orgFuture = FirestoreUtils.fetchOrganization(orgId);
    final teamsFuture = TeamService.getTeamsByOrg(orgId);
    final createdIdsFuture = _userIdsCreatedBy(coordinatorId);
    final ideasFuture = _ideasByOrg(orgId);
    final participationsFuture = IdeathonParticipationService.listByOrg(orgId);

    final org = await orgFuture;
    final String orgName = (org?.name ?? '').trim().isEmpty ? orgId : org!.name.trim();

    final List<TeamModel> orgTeams = await teamsFuture;
    final Set<String> createdUserIds = await createdIdsFuture;
    final List<TeamModel> owned = orgTeams
        .where((TeamModel team) => _registeredBy(team, coordinatorId, createdUserIds))
        .toList(growable: false);
    if (owned.isEmpty) {
      return CoordinatorTeamRegistrationSnapshot(orgName: orgName, rows: const <CoordinatorTeamRegistrationRow>[]);
    }

    final Set<String> memberIds = <String>{
      for (final TeamModel team in owned) ...team.studentIds,
    };
    final Map<String, UserModel> membersById = await _fetchUsers(memberIds);

    final List<IdeaModel> ideas = await ideasFuture;
    final List<IdeathonParticipation> participations = await participationsFuture;
    final Map<String, Set<String>> ideathonIdsByTeam = _ideathonIdsByTeam(
      ideas: ideas,
      participations: participations,
    );
    final Set<String> allEventIds = <String>{
      for (final Set<String> ids in ideathonIdsByTeam.values) ...ids,
    };
    final Map<String, String> ideathonNames = await _ideathonNames(allEventIds);

    final List<CoordinatorTeamRegistrationRow> rows = owned.map((TeamModel team) {
      final List<UserModel> members = team.studentIds
          .map((String id) => membersById[id])
          .whereType<UserModel>()
          .toList(growable: false);
      final IdeathonTeamOrigin origin = IdeathonTeamEligibility.classify(
        hostOrgId: orgId,
        team: team,
        members: members,
        hostOrgName: orgName,
      );
      final List<String> eventIds =
          (ideathonIdsByTeam[team.teamId.trim()] ?? const <String>{}).toList(growable: false)
            ..sort();
      final List<String> names = eventIds
          .map((String id) => (ideathonNames[id] ?? '').trim())
          .where((String name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
      return CoordinatorTeamRegistrationRow(
        team: team,
        origin: origin,
        ideathonName: names.join(' · '),
        ideathonId: eventIds.length == 1 ? eventIds.first : '',
        importedAt: team.createdAt,
      );
    }).toList(growable: false);

    return CoordinatorTeamRegistrationSnapshot(orgName: orgName, rows: rows);
  }

  static List<CoordinatorTeamRegistrationRow> filter({
    required List<CoordinatorTeamRegistrationRow> rows,
    String search = '',
    TeamRegistrationOriginFilter origin = TeamRegistrationOriginFilter.all,
  }) {
    final String query = search.trim().toLowerCase();
    return rows.where((CoordinatorTeamRegistrationRow row) {
      if (origin == TeamRegistrationOriginFilter.internal && !row.isInternal) return false;
      if (origin == TeamRegistrationOriginFilter.external && row.isInternal) return false;
      if (query.isEmpty) return true;
      return row.team.teamName.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  static bool _registeredBy(TeamModel team, String coordinatorId, Set<String> createdUserIds) {
    final String createdBy = team.createdBy.trim();
    if (createdBy == coordinatorId) return true;
    if (createdBy.isNotEmpty) return false;
    return team.studentIds.any(createdUserIds.contains);
  }

  static Future<Set<String>> _userIdsCreatedBy(String coordinatorId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzUsers)
        .where('createdBy', isEqualTo: coordinatorId)
        .get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id.trim()).toSet();
  }

  static Future<List<IdeaModel>> _ideasByOrg(String orgId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: orgId).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  static Map<String, Set<String>> _ideathonIdsByTeam({
    required List<IdeaModel> ideas,
    required List<IdeathonParticipation> participations,
  }) {
    final Map<String, String> teamByIdea = <String, String>{
      for (final IdeaModel idea in ideas)
        if (idea.ideaId.trim().isNotEmpty && idea.teamId.trim().isNotEmpty) idea.ideaId.trim(): idea.teamId.trim(),
    };
    final Map<String, Set<String>> out = <String, Set<String>>{};
    for (final IdeathonParticipation participation in participations) {
      if (!participation.isActive) continue;
      final String teamId = teamByIdea[participation.ideaId.trim()] ?? '';
      final String eventId = participation.ideathonId.trim();
      if (teamId.isEmpty || eventId.isEmpty) continue;
      out.putIfAbsent(teamId, () => <String>{}).add(eventId);
    }
    return out;
  }

  static Future<Map<String, String>> _ideathonNames(Set<String> ids) async {
    final Map<String, String> names = <String, String>{};
    final List<String> list = ids.where((String id) => id.trim().isNotEmpty).toList(growable: false);
    await Future.wait<void>(
      list.map((String id) async {
        final event = await IdeathonService.fetchById(id);
        final String name = (event?.name ?? '').trim();
        if (name.isNotEmpty) names[id] = name;
      }),
    );
    return names;
  }

  static Future<Map<String, UserModel>> _fetchUsers(Set<String> userIds) async {
    final Map<String, UserModel> out = <String, UserModel>{};
    final List<String> ids =
        userIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toList(growable: false);
    const int chunkSize = 24;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final int end = i + chunkSize > ids.length ? ids.length : i + chunkSize;
      await Future.wait<void>(
        ids.sublist(i, end).map((String id) async {
          final UserModel? user = await FirestoreUtils.fetchUser(id);
          if (user != null) out[id] = user;
        }),
      );
    }
    return out;
  }
}
