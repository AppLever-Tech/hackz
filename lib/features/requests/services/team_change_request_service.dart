import 'package:cloud_firestore/cloud_firestore.dart';

import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../team/services/teams_workspace_service.dart';
import '../../../utils/firestore_utils.dart';
import '../models/team_change_request.dart';
import '../models/workflow_request.dart';
import '../models/workflow_request_type.dart';
import '../models/workflow_status.dart';
import 'workflow_request_service.dart';

/// Submitting + approving a team change request.
///
/// Approval is the only path that mutates an active team — team leader edits are
/// always indirect through this workflow.
class TeamChangeRequestService {
  TeamChangeRequestService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int minMembersPerTeam = TeamsWorkspaceService.minMembersPerTeam;
  static const int maxMembersPerTeam = TeamsWorkspaceService.maxMembersPerTeam;

  /// Builds a [WorkflowRequest] payload from a team + proposed member set.
  /// Names are denormalized using [memberLookup] so the review pane never
  /// has to re-fetch users.
  static WorkflowRequest buildRequest({
    required TeamModel team,
    required UserModel faculty,
    required Set<String> proposedMemberIds,
    required Map<String, UserModel> memberLookup,
    required String reason,
    required bool hasEvaluation,
    WorkflowStatus status = WorkflowStatus.pendingApproval,
  }) {
    final DocumentReference<Map<String, dynamic>> ref = WorkflowRequestService.newDocRef();
    final List<TeamMemberSnapshot> current = team.studentIds
        .map((String id) {
          final UserModel? user = memberLookup[id];
          return TeamMemberSnapshot(
            userId: id,
            displayName: user == null ? id : userDisplayName(user),
          );
        })
        .toList(growable: false);
    final List<TeamMemberSnapshot> proposed = proposedMemberIds
        .map((String id) {
          final UserModel? user = memberLookup[id];
          return TeamMemberSnapshot(
            userId: id,
            displayName: user == null ? id : userDisplayName(user),
          );
        })
        .toList(growable: false);
    final TeamChangePayload payload = TeamChangePayload(
      teamId: team.teamId,
      teamName: team.teamName,
      facultyId: faculty.userId,
      facultyName: userDisplayName(faculty),
      currentMembers: current,
      proposedMembers: proposed,
      hasEvaluation: hasEvaluation,
    );
    final String summary = payload.changeSummary;
    return WorkflowRequest(
      requestId: ref.id,
      type: WorkflowRequestType.teamChange,
      status: status,
      orgId: faculty.orgId,
      departmentCode: faculty.departmentCode.trim().toUpperCase(),
      requestedBy: faculty.userId,
      requestedByName: userDisplayName(faculty),
      requestedAt: DateTime.now(),
      title: 'Team change · ${team.teamName}',
      summary: summary,
      reason: reason.trim(),
      adminComments: '',
      targetEntityType: 'team',
      targetEntityId: team.teamId,
      approvedBy: '',
      approvedAt: null,
      rejectedBy: '',
      rejectedAt: null,
      payload: payload.toMap(),
    );
  }

  static void validateProposed({
    required Set<String> proposedMemberIds,
    required Set<String> currentMemberIds,
    required String reason,
    String teamLeaderId = '',
  }) {
    if (proposedMemberIds.length < minMembersPerTeam) {
      throw WorkflowRequestException(
          'Team must have at least $minMembersPerTeam team members.');
    }
    if (proposedMemberIds.length > maxMembersPerTeam) {
      throw WorkflowRequestException(
          'Team can have at most $maxMembersPerTeam team members.');
    }
    if (proposedMemberIds.length == currentMemberIds.length &&
        proposedMemberIds.containsAll(currentMemberIds)) {
      throw WorkflowRequestException('No member changes to submit.');
    }
    final String leaderId = teamLeaderId.trim();
    if (leaderId.isNotEmpty && !proposedMemberIds.contains(leaderId)) {
      throw WorkflowRequestException('The team leader must remain a team member.');
    }
    if (reason.trim().isEmpty) {
      throw WorkflowRequestException('Please describe why this change is needed.');
    }
  }

  static Future<WorkflowRequest> submit(WorkflowRequest request) async {
    final WorkflowRequest pending = request.status == WorkflowStatus.pendingApproval
        ? request
        : request.copyWith(status: WorkflowStatus.pendingApproval);
    await WorkflowRequestService.save(pending);
    TeamsWorkspaceService.clearCache();
    return pending;
  }

  /// Department admin approve: apply membership change to active team + mark
  /// the request approved in a single batch.
  static Future<WorkflowRequest> approve({
    required WorkflowRequest request,
    required UserModel approver,
    String comments = '',
  }) async {
    if (request.type != WorkflowRequestType.teamChange) {
      throw WorkflowRequestException('Unsupported request type for team change approval.');
    }
    if (request.status.isTerminal) {
      throw WorkflowRequestException(
          'Request is already ${request.status.label.toLowerCase()}.');
    }
    final TeamChangePayload? payload = TeamChangePayload.fromRequest(request);
    if (payload == null || payload.teamId.isEmpty) {
      throw WorkflowRequestException('Request is missing team payload.');
    }

    final Set<String> currentIds =
        payload.currentMembers.map((m) => m.userId).toSet();
    final Set<String> proposedIds =
        payload.proposedMembers.map((m) => m.userId).toSet();
    final Set<String> added = proposedIds.difference(currentIds);
    final Set<String> removed = currentIds.difference(proposedIds);

    final WriteBatch batch = _db.batch();
    final DocumentReference<Map<String, dynamic>> teamRef =
        _db.collection(FirestoreUtils.hkzTeams).doc(payload.teamId);
    batch.set(
      teamRef,
      <String, dynamic>{
        'studentIds': proposedIds.toList(growable: false),
      },
      SetOptions(merge: true),
    );
    for (final String userId in removed) {
      batch.set(
        _db.collection(FirestoreUtils.hkzUsers).doc(userId),
        <String, dynamic>{'teamId': null},
        SetOptions(merge: true),
      );
    }
    for (final String userId in added) {
      batch.set(
        _db.collection(FirestoreUtils.hkzUsers).doc(userId),
        <String, dynamic>{'teamId': payload.teamId},
        SetOptions(merge: true),
      );
    }

    final WorkflowRequest approved = request.copyWith(
      status: WorkflowStatus.approved,
      approvedBy: approver.userId,
      approvedAt: DateTime.now(),
      adminComments: comments.trim(),
    );
    batch.set(
      _db.collection(FirestoreUtils.hkzRequests).doc(approved.requestId),
      approved.toMap(),
      SetOptions(merge: true),
    );

    await batch.commit();
    TeamsWorkspaceService.clearCache();
    return approved;
  }

  static Future<WorkflowRequest> reject({
    required WorkflowRequest request,
    required UserModel approver,
    required String comments,
  }) {
    return WorkflowRequestService.reject(
      request: request,
      rejectedByUserId: approver.userId,
      comments: comments,
    );
  }
}
