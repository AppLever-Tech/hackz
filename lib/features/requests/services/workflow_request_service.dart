import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../models/workflow_request.dart';
import '../models/workflow_request_type.dart';
import '../models/workflow_status.dart';

/// Generic CRUD + listing for [WorkflowRequest]. Type-specific side-effects
/// (e.g. mutating a team on approval) live in dedicated services that call
/// into this one.
class WorkflowRequestException implements Exception {
  WorkflowRequestException(this.message);
  final String message;

  @override
  String toString() => message;
}

class WorkflowRequestService {
  WorkflowRequestService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzRequests);

  static DocumentReference<Map<String, dynamic>> newDocRef() => _col.doc();

  static Future<void> save(WorkflowRequest request) async {
    await _col.doc(request.requestId).set(request.toMap(), SetOptions(merge: true));
  }

  static Future<WorkflowRequest?> fetch(String requestId) async {
    final String id = requestId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> snap = await _col.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return WorkflowRequest.fromMap(snap.id, snap.data()!);
  }

  /// Lists all requests for a department admin scope.
  static Future<List<WorkflowRequest>> listForDepartment({
    required String orgId,
    required String departmentCode,
  }) async {
    final String code = departmentCode.trim().toUpperCase();
    if (orgId.trim().isEmpty) return const <WorkflowRequest>[];
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('orgId', isEqualTo: orgId)
        .where('departmentCode', isEqualTo: code)
        .get();
    final List<WorkflowRequest> items = snap.docs
        .map((d) => WorkflowRequest.fromMap(d.id, d.data()))
        .toList(growable: false);
    items.sort(_compareRequestsForReview);
    return items;
  }

  /// Lists requests submitted by [requestedBy] (faculty self view).
  static Future<List<WorkflowRequest>> listForRequester(String requestedBy) async {
    final String id = requestedBy.trim();
    if (id.isEmpty) return const <WorkflowRequest>[];
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('requestedBy', isEqualTo: id).get();
    final List<WorkflowRequest> items = snap.docs
        .map((d) => WorkflowRequest.fromMap(d.id, d.data()))
        .toList(growable: false);
    items.sort(_compareRequestsForReview);
    return items;
  }

  /// Lists every request whose `targetEntityId` matches (regardless of type)
  /// for the team history timeline.
  static Future<List<WorkflowRequest>> listForTarget({
    required String entityType,
    required String entityId,
  }) async {
    final String typeKey = entityType.trim();
    final String entity = entityId.trim();
    if (typeKey.isEmpty || entity.isEmpty) return const <WorkflowRequest>[];
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('targetEntityType', isEqualTo: typeKey)
        .where('targetEntityId', isEqualTo: entity)
        .get();
    final List<WorkflowRequest> items = snap.docs
        .map((d) => WorkflowRequest.fromMap(d.id, d.data()))
        .toList(growable: false);
    items.sort((WorkflowRequest a, WorkflowRequest b) => b.resolvedAt.compareTo(a.resolvedAt));
    return items;
  }

  /// Reject a pending request with mandatory [comments].
  static Future<WorkflowRequest> reject({
    required WorkflowRequest request,
    required String rejectedByUserId,
    required String comments,
  }) async {
    if (request.status.isTerminal) {
      throw WorkflowRequestException('Request is already ${request.status.label.toLowerCase()}.');
    }
    if (comments.trim().isEmpty) {
      throw WorkflowRequestException('A rejection reason is required.');
    }
    final WorkflowRequest updated = request.copyWith(
      status: WorkflowStatus.rejected,
      rejectedBy: rejectedByUserId,
      rejectedAt: DateTime.now(),
      adminComments: comments.trim(),
    );
    await save(updated);
    return updated;
  }

  /// Marks a request approved after the type-specific side-effects have been
  /// applied successfully. Type services call this near the end of their
  /// transaction so audit + status update are consistent.
  static Future<WorkflowRequest> markApproved({
    required WorkflowRequest request,
    required String approvedByUserId,
    String comments = '',
  }) async {
    if (request.status.isTerminal) {
      throw WorkflowRequestException('Request is already ${request.status.label.toLowerCase()}.');
    }
    final WorkflowRequest updated = request.copyWith(
      status: WorkflowStatus.approved,
      approvedBy: approvedByUserId,
      approvedAt: DateTime.now(),
      adminComments: comments.trim(),
    );
    await save(updated);
    return updated;
  }

  /// Display sort: pending first, then most-recent action.
  static int _compareRequestsForReview(WorkflowRequest a, WorkflowRequest b) {
    final int rankA = _statusRank(a.status);
    final int rankB = _statusRank(b.status);
    if (rankA != rankB) return rankA.compareTo(rankB);
    return b.resolvedAt.compareTo(a.resolvedAt);
  }

  static int _statusRank(WorkflowStatus status) {
    return switch (status) {
      WorkflowStatus.pendingApproval => 0,
      WorkflowStatus.draft => 1,
      WorkflowStatus.approved => 2,
      WorkflowStatus.rejected => 3,
    };
  }
}

/// Filter view-model shared by faculty + dept admin request views.
class WorkflowRequestFilter {
  const WorkflowRequestFilter({
    this.statuses = const <WorkflowStatus>{},
    this.types = const <WorkflowRequestType>{},
    this.search = '',
  });

  final Set<WorkflowStatus> statuses;
  final Set<WorkflowRequestType> types;
  final String search;

  bool matches(WorkflowRequest request) {
    if (statuses.isNotEmpty && !statuses.contains(request.status)) return false;
    if (types.isNotEmpty && !types.contains(request.type)) return false;
    if (search.trim().isNotEmpty) {
      final String q = search.trim().toLowerCase();
      final String haystack =
          '${request.title} ${request.summary} ${request.requestedByName} ${request.reason}'
              .toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    return true;
  }

  WorkflowRequestFilter copyWith({
    Set<WorkflowStatus>? statuses,
    Set<WorkflowRequestType>? types,
    String? search,
  }) {
    return WorkflowRequestFilter(
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      search: search ?? this.search,
    );
  }
}
