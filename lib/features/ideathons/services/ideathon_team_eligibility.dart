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

/// Single eligibility helper for Internal vs External Ideathon team membership.
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
    String hostOrgName = '',
  }) {
    final String host = hostOrgId.trim();
    final String teamOrg = team.orgId.trim();
    if (teamOrg.isNotEmpty && host.isNotEmpty && teamOrg != host) {
      return IdeathonTeamOrigin.otherOrganisation;
    }

    for (final UserModel member in members) {
      if (_isExternalMember(member, hostOrgId: host, hostOrgName: hostOrgName, teamOrgId: teamOrg)) {
        return IdeathonTeamOrigin.mixed;
      }
    }
    return IdeathonTeamOrigin.host;
  }

  static bool _isExternalMember(
    UserModel member, {
    required String hostOrgId,
    required String hostOrgName,
    required String teamOrgId,
  }) {
    final String affiliation = member.organisationName.trim();
    if (affiliation.isNotEmpty) {
      final String hostName = hostOrgName.trim();
      if (hostName.isEmpty) return true;
      return affiliation.toLowerCase() != hostName.toLowerCase();
    }
    final String memberOrg = member.orgId.trim();
    if (memberOrg.isEmpty) return false;
    if (teamOrgId.isNotEmpty && memberOrg != teamOrgId) return true;
    return hostOrgId.isNotEmpty && memberOrg != hostOrgId;
  }
}
