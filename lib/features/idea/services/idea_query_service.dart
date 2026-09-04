import 'package:cloud_firestore/cloud_firestore.dart';

import '../../organization/models/department_model.dart';
import '../../user/models/enums/user_role.dart';
import '../models/idea_event_participation_summary.dart';
import '../models/idea_list_config.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../payment/models/payment_model.dart';
import '../../team/models/team_model.dart';
import '../../team/services/team_service.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../user/services/role_visibility_helpers.dart';
import 'idea_event_participation_loader.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class IdeaQueryParams {
  const IdeaQueryParams({
    required this.config,
    required this.search,
    required this.sortType,
    required this.statusFilters,
    required this.problemFilters,
    required this.departmentFilters,
    this.viewer,
    this.limit = 400,
  });

  final IdeaListConfig config;
  final String search;
  final IdeaSortType sortType;
  final Set<IdeaStatus> statusFilters;
  final Set<String> problemFilters;
  final Set<String> departmentFilters;
  final UserModel? viewer;
  final int limit;
}

/// Department-scoped idea counts for dashboard metrics (before search/status filters).
class IdeaDepartmentMetrics {
  const IdeaDepartmentMetrics({
    required this.total,
    required this.submitted,
    required this.pendingSubmission,
  });

  static const IdeaDepartmentMetrics empty = IdeaDepartmentMetrics(
    total: 0,
    submitted: 0,
    pendingSubmission: 0,
  );

  final int total;
  final int submitted;
  final int pendingSubmission;
}

class IdeaListQueryResult {
  const IdeaListQueryResult({
    required this.items,
    required this.metrics,
  });

  final List<IdeaListItem> items;
  final IdeaDepartmentMetrics metrics;
}

class IdeaListItem {
  const IdeaListItem({
    required this.idea,
    required this.teamName,
    required this.events,
    this.team,
    this.payment,
    this.canUploadPayment = false,
  });

  final IdeaModel idea;
  final String teamName;
  final TeamModel? team;
  final List<IdeaEventParticipationSummary> events;
  final PaymentModel? payment;
  final bool canUploadPayment;
}

class IdeaQueryService {
  IdeaQueryService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<IdeaListQueryResult> fetchIdeas(IdeaQueryParams params) async {
    final ideasSnap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: params.config.orgId)
        .limit(params.limit)
        .get();
    final allIdeas = ideasSnap.docs
        .map((doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final List<IdeaModel> deptScoped = _applyDepartmentScope(allIdeas, params);
    Set<String>? judgeAssignedIdeaIds;
    if (params.viewer != null && UserRole.fromCode(params.viewer!.role) == UserRole.judge) {
      judgeAssignedIdeaIds = await EvaluationAssignmentService.assignedIdeaIdsForJudge(
        orgId: params.config.orgId,
        judgeId: params.viewer!.userId,
      );
    }

    var ideas = _applyIdeaFilters(allIdeas, params);
    if (judgeAssignedIdeaIds != null) {
      ideas = ideas.where((IdeaModel idea) => judgeAssignedIdeaIds!.contains(idea.ideaId)).toList(growable: false);
    }
    final teamsById = await _fetchTeamsById(
      orgId: params.config.orgId,
      teamIds: ideas.map((e) => e.teamId),
    );
    final eventsByIdea = await IdeaEventParticipationLoader.loadByOrg(
      orgId: params.config.orgId,
      ideaIds: ideas.map((IdeaModel e) => e.ideaId).toSet(),
    );
    final Map<String, PaymentModel> paymentByIdeaId = params.config.canUploadPayment
        ? await _fetchPaymentByIdea(
            orgId: params.config.orgId,
            ideaIds: ideas.map((IdeaModel e) => e.ideaId),
          )
        : const <String, PaymentModel>{};
    final viewer = params.viewer;
    var items = ideas
        .map(
          (idea) {
            final team = teamsById[idea.teamId];
            final teamName = team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : idea.teamId;
            final PaymentModel? payment = paymentByIdeaId[idea.ideaId];
            return IdeaListItem(
              idea: idea,
              teamName: teamName,
              team: team,
              events: eventsByIdea[idea.ideaId] ?? const <IdeaEventParticipationSummary>[],
              payment: payment,
              canUploadPayment: _viewerCanUploadPayment(
                viewer: viewer,
                team: team,
                payment: payment,
              ),
            );
          },
        )
        .toList(growable: false);
    items = _applyViewerScope(items, viewer);
    items = _applySort(items, params.sortType);
    final IdeaDepartmentMetrics metrics = _computeMetrics(deptScoped);
    return IdeaListQueryResult(items: items, metrics: metrics);
  }

  static List<IdeaModel> _applyDepartmentScope(List<IdeaModel> ideas, IdeaQueryParams params) {
    final restrictedDepartment = DepartmentModel.resolveCode(params.config.departmentCode);
    if (params.config.ideaDepartmentScope == IdeaDepartmentScope.none || restrictedDepartment.isEmpty) {
      return ideas;
    }
    return ideas
        .where(
          (IdeaModel idea) => RoleVisibilityHelpers.ideaMatchesDepartmentScope(
            idea,
            params.config.ideaDepartmentScope,
            restrictedDepartment,
          ),
        )
        .toList(growable: false);
  }

  static IdeaDepartmentMetrics _computeMetrics(List<IdeaModel> ideas) {
    if (ideas.isEmpty) return IdeaDepartmentMetrics.empty;
    final int submitted = ideas.where((IdeaModel i) => i.status == IdeaStatus.submitted).length;
    final int pending = ideas.where((IdeaModel i) => i.status == IdeaStatus.draft).length;
    return IdeaDepartmentMetrics(
      total: ideas.length,
      submitted: submitted,
      pendingSubmission: pending,
    );
  }

  static List<IdeaModel> _applyIdeaFilters(List<IdeaModel> ideas, IdeaQueryParams params) {
    final search = params.search.trim().toLowerCase();
    final restrictedDepartment = DepartmentModel.resolveCode(params.config.departmentCode);
    final selectedProblems = params.problemFilters
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final selectedDepartments = params.departmentFilters
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return ideas.where((idea) {
      if (params.config.ideaDepartmentScope != IdeaDepartmentScope.none && restrictedDepartment.isNotEmpty) {
        if (!RoleVisibilityHelpers.ideaMatchesDepartmentScope(
          idea,
          params.config.ideaDepartmentScope,
          restrictedDepartment,
        )) {
          return false;
        }
      }
      if (params.statusFilters.isNotEmpty && !params.statusFilters.contains(idea.status)) {
        return false;
      }
      if (selectedProblems.isNotEmpty && !selectedProblems.contains(idea.problemId)) {
        return false;
      }
      if (selectedDepartments.isNotEmpty) {
        final ideaDept = RoleVisibilityHelpers.ideaDepartmentCodeForScope(
          idea,
          params.config.ideaDepartmentScope,
        ).trim().toUpperCase();
        if (!selectedDepartments.contains(ideaDept)) return false;
      }
      if (search.isEmpty) return true;
      final inProblemNumber = idea.problemNumber.toLowerCase().contains(search);
      final inProblemTitle = idea.problemTitle.toLowerCase().contains(search);
      final inIdeaTitle = idea.ideaTitle.toLowerCase().contains(search);
      final inDescription = idea.description.toLowerCase().contains(search);
      return inProblemNumber || inProblemTitle || inIdeaTitle || inDescription;
    }).toList(growable: false);
  }

  static Future<Map<String, PaymentModel>> _fetchPaymentByIdea({
    required String orgId,
    required Iterable<String> ideaIds,
  }) async {
    final Set<String> idSet = ideaIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return const <String, PaymentModel>{};
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).get();
    final Map<String, PaymentModel> mapped = <String, PaymentModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final PaymentModel payment = PaymentModel.fromMap(doc.id, doc.data());
      if (!idSet.contains(payment.ideaId)) continue;
      mapped[payment.ideaId] = payment;
    }
    return mapped;
  }

  static bool _viewerCanUploadPayment({
    required UserModel? viewer,
    required TeamModel? team,
    required PaymentModel? payment,
  }) {
    if (viewer == null || team == null) return false;
    if (payment != null && payment.status != PaymentRecordStatus.rejected) return false;
    return TeamService.isActingTeamLeader(viewer, team);
  }

  static Future<Map<String, TeamModel>> _fetchTeamsById({
    required String orgId,
    required Iterable<String> teamIds,
  }) async {
    final idSet = teamIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return <String, TeamModel>{};
    final teamSnap = await _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: orgId).get();
    final mapped = <String, TeamModel>{};
    for (final doc in teamSnap.docs) {
      final data = doc.data();
      final id = ((data['teamId'] as String?) ?? '').trim().isNotEmpty
          ? ((data['teamId'] as String?) ?? '').trim()
          : doc.id;
      if (!idSet.contains(id)) continue;
      mapped[id] = TeamModel.fromMap(doc.id, data);
    }
    return mapped;
  }

  static List<IdeaListItem> _applyViewerScope(List<IdeaListItem> items, UserModel? viewer) {
    if (viewer == null) return items;
    final role = UserRole.fromCode(viewer.role);
    if (role == UserRole.teamMember) {
      final teamMemberId = viewer.userId.trim();
      final teamMemberTeamId = (viewer.teamId ?? '').trim();
      if (teamMemberId.isEmpty && teamMemberTeamId.isEmpty) return items;
      return items.where((item) {
        if (item.idea.createdBy.trim() == teamMemberId) return true;
        final team = item.team;
        if (team != null && team.studentIds.contains(teamMemberId)) return true;
        if (teamMemberTeamId.isNotEmpty && item.idea.teamId.trim() == teamMemberTeamId) return true;
        return false;
      }).toList(growable: false);
    }
    return items;
  }

  static List<IdeaListItem> _applySort(List<IdeaListItem> items, IdeaSortType sortType) {
    final sorted = List<IdeaListItem>.from(items);
    switch (sortType) {
      case IdeaSortType.newest:
        sorted.sort((a, b) => b.idea.createdAt.compareTo(a.idea.createdAt));
      case IdeaSortType.oldest:
        sorted.sort((a, b) => a.idea.createdAt.compareTo(b.idea.createdAt));
      case IdeaSortType.status:
        sorted.sort((a, b) => a.idea.status.value.compareTo(b.idea.status.value));
    }
    return sorted;
  }
}
