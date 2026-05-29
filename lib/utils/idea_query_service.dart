import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attachment_model.dart';
import '../models/department_model.dart';
import '../models/enums/user_role.dart';
import '../models/idea_list_config.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/score_model.dart';
import '../features/evaluations/assignments/services/evaluation_assignment_service.dart';
import '../features/team/models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';
import 'role_visibility_helpers.dart';

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
    required this.approved,
    required this.evaluated,
    required this.pendingSubmission,
    this.averageScore,
  });

  static const IdeaDepartmentMetrics empty = IdeaDepartmentMetrics(
    total: 0,
    submitted: 0,
    approved: 0,
    evaluated: 0,
    pendingSubmission: 0,
  );

  final int total;
  final int submitted;
  final int approved;
  final int evaluated;
  final int pendingSubmission;
  final double? averageScore;
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
    required this.canUploadPayment,
    required this.attachmentCount,
    this.firstAttachmentId,
    this.team,
    this.payment,
    this.score,
    this.judgeName,
  });

  final IdeaModel idea;
  final String teamName;
  final TeamModel? team;
  final PaymentModel? payment;
  final ScoreModel? score;
  final String? judgeName;
  final bool canUploadPayment;
  final int attachmentCount;
  final String? firstAttachmentId;
}

class IdeaQueryService {
  IdeaQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    final paymentByIdeaId = await _fetchPaymentByIdea(
      orgId: params.config.orgId,
      ideaIds: ideas.map((e) => e.ideaId),
    );
    final scoreByIdeaId = await _fetchLatestScoreByIdea(
      orgId: params.config.orgId,
      ideaIds: deptScoped.map((e) => e.ideaId),
    );
    final attachmentMetaByIdea = await _fetchAttachmentMetaByIdea(
      orgId: params.config.orgId,
      ideas: ideas,
      paymentByIdeaId: paymentByIdeaId,
    );
    final usersById = await _fetchUsersById(
      orgId: params.config.orgId,
      userIds: scoreByIdeaId.values.map((score) => score.judgeId),
    );
    final viewer = params.viewer;
    var items = ideas
        .map(
          (idea) {
            final team = teamsById[idea.teamId];
            final teamName = team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : idea.teamId;
            final payment = paymentByIdeaId[idea.ideaId];
            final canPay = _viewerCanUploadPayment(
              viewer: viewer,
              idea: idea,
              team: team,
              payment: payment,
            );
            final _AttachmentListMeta attach = attachmentMetaByIdea[idea.ideaId] ?? const _AttachmentListMeta();
            return IdeaListItem(
              idea: idea,
              teamName: teamName,
              team: team,
              payment: payment,
              score: scoreByIdeaId[idea.ideaId],
              judgeName: _displayName(usersById[scoreByIdeaId[idea.ideaId]?.judgeId ?? '']),
              canUploadPayment: canPay,
              attachmentCount: attach.count,
              firstAttachmentId: attach.firstId,
            );
          },
        )
        .toList(growable: false);
    items = _applyViewerScope(items, viewer);
    items = _applySort(items, params.sortType);
    final IdeaDepartmentMetrics metrics = _computeMetrics(deptScoped, scoreByIdeaId);
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

  static IdeaDepartmentMetrics _computeMetrics(
    List<IdeaModel> ideas,
    Map<String, ScoreModel> scoreByIdeaId,
  ) {
    if (ideas.isEmpty) return IdeaDepartmentMetrics.empty;
    final int submitted = ideas.where((IdeaModel i) => i.status == IdeaStatus.submitted).length;
    final int approved = ideas.where((IdeaModel i) => i.status == IdeaStatus.approved).length;
    final int evaluated = ideas
        .where(
          (IdeaModel i) =>
              i.status == IdeaStatus.evaluated ||
              i.status == IdeaStatus.approved ||
              scoreByIdeaId.containsKey(i.ideaId),
        )
        .length;
    final int pending = ideas.where((IdeaModel i) => i.status == IdeaStatus.pendingSubmission).length;
    final Iterable<double> scores = scoreByIdeaId.values.map((ScoreModel s) => s.score);
    final double? avg = scores.isEmpty ? null : scores.reduce((double a, double b) => a + b) / scores.length;
    return IdeaDepartmentMetrics(
      total: ideas.length,
      submitted: submitted,
      approved: approved,
      evaluated: evaluated,
      pendingSubmission: pending,
      averageScore: avg,
    );
  }

  static Future<Map<String, _AttachmentListMeta>> _fetchAttachmentMetaByIdea({
    required String orgId,
    required List<IdeaModel> ideas,
    required Map<String, PaymentModel> paymentByIdeaId,
  }) async {
    final Set<String> ideaIds = ideas.map((IdeaModel e) => e.ideaId).toSet();
    if (ideaIds.isEmpty || orgId.trim().isEmpty) return <String, _AttachmentListMeta>{};

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzAttachments)
        .where('orgId', isEqualTo: orgId)
        .where('isActive', isEqualTo: true)
        .get();

    final Map<String, List<AttachmentModel>> byIdea = <String, List<AttachmentModel>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final AttachmentModel a = AttachmentModel.fromMap(doc.id, doc.data());
      if (a.entityType == AttachmentEntityType.idea && ideaIds.contains(a.entityId)) {
        byIdea.putIfAbsent(a.entityId, () => <AttachmentModel>[]).add(a);
        continue;
      }
      if (a.entityType == AttachmentEntityType.payment) {
        for (final IdeaModel idea in ideas) {
          final PaymentModel? p = paymentByIdeaId[idea.ideaId];
          if (p != null && p.paymentId == a.entityId) {
            byIdea.putIfAbsent(idea.ideaId, () => <AttachmentModel>[]).add(a);
          }
        }
      }
    }

    final Map<String, _AttachmentListMeta> out = <String, _AttachmentListMeta>{};
    for (final MapEntry<String, List<AttachmentModel>> e in byIdea.entries) {
      final List<AttachmentModel> sorted = List<AttachmentModel>.from(e.value)
        ..sort((AttachmentModel a, AttachmentModel b) => b.createdAt.compareTo(a.createdAt));
      out[e.key] = _AttachmentListMeta(count: sorted.length, firstId: sorted.first.attachmentId);
    }
    return out;
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

  static Future<Map<String, ScoreModel>> _fetchLatestScoreByIdea({
    required String orgId,
    required Iterable<String> ideaIds,
  }) async {
    final idSet = ideaIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return <String, ScoreModel>{};
    final scoreSnap = await _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).get();
    final mapped = <String, ScoreModel>{};
    for (final doc in scoreSnap.docs) {
      final score = ScoreModel.fromMap(doc.id, doc.data());
      if (!idSet.contains(score.ideaId)) continue;
      final existing = mapped[score.ideaId];
      if (existing == null || score.createdAt.isAfter(existing.createdAt)) {
        mapped[score.ideaId] = score;
      }
    }
    return mapped;
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

  static Future<Map<String, UserModel>> _fetchUsersById({
    required String orgId,
    required Iterable<String> userIds,
  }) async {
    final idSet = userIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return <String, UserModel>{};
    final snap = await _db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: orgId).get();
    final mapped = <String, UserModel>{};
    for (final doc in snap.docs) {
      final user = UserModel.fromMap(doc.data());
      final normalizedUser = user.userId.trim().isNotEmpty ? user : user.copyWith(userId: doc.id);
      final userId = normalizedUser.userId.trim();
      if (idSet.contains(userId)) {
        mapped[userId] = normalizedUser;
      }
      if (doc.id.trim().isNotEmpty && idSet.contains(doc.id.trim())) {
        mapped[doc.id.trim()] = normalizedUser;
      }
    }
    return mapped;
  }

  static Future<Map<String, PaymentModel>> _fetchPaymentByIdea({
    required String orgId,
    required Iterable<String> ideaIds,
  }) async {
    final idSet = ideaIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return <String, PaymentModel>{};
    final snap = await _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).get();
    final mapped = <String, PaymentModel>{};
    for (final doc in snap.docs) {
      final p = PaymentModel.fromMap(doc.id, doc.data());
      if (!idSet.contains(p.ideaId)) continue;
      mapped[p.ideaId] = p;
    }
    return mapped;
  }

  static bool _viewerCanUploadPayment({
    required UserModel? viewer,
    required IdeaModel idea,
    required TeamModel? team,
    required PaymentModel? payment,
  }) {
    if (viewer == null) return false;
    if (idea.status != IdeaStatus.pendingSubmission) return false;
    if (payment != null && payment.status != PaymentRecordStatus.rejected) return false;
    if (team == null) return false;
    final role = UserRole.fromCode(viewer.role);
    if (role == UserRole.student) {
      return team.studentIds.contains(viewer.userId);
    }
    if (role == UserRole.faculty) {
      return team.mentorId == viewer.userId;
    }
    return false;
  }

  static String? _displayName(UserModel? user) {
    if (user == null) return null;
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? user.userId : name;
  }

  static List<IdeaListItem> _applyViewerScope(List<IdeaListItem> items, UserModel? viewer) {
    if (viewer == null) return items;
    final role = UserRole.fromCode(viewer.role);
    if (role == UserRole.faculty) {
      final facultyId = viewer.userId.trim();
      if (facultyId.isEmpty) return items;
      return items.where((item) {
        if (item.idea.createdBy.trim() == facultyId) return true;
        final team = item.team;
        if (team == null) return false;
        return team.mentorId.trim() == facultyId;
      }).toList(growable: false);
    }
    if (role == UserRole.student) {
      final studentId = viewer.userId.trim();
      final studentTeamId = (viewer.teamId ?? '').trim();
      if (studentId.isEmpty && studentTeamId.isEmpty) return items;
      return items.where((item) {
        if (item.idea.createdBy.trim() == studentId) return true;
        final team = item.team;
        if (team != null && team.studentIds.contains(studentId)) return true;
        if (studentTeamId.isNotEmpty && item.idea.teamId.trim() == studentTeamId) return true;
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
      case IdeaSortType.score:
        sorted.sort((a, b) => (b.score?.score ?? -1).compareTo(a.score?.score ?? -1));
    }
    return sorted;
  }
}

class _AttachmentListMeta {
  const _AttachmentListMeta({this.count = 0, this.firstId});

  final int count;
  final String? firstId;
}
