/// Generic approval-based workflow status used by every request type.
///
/// Add new statuses as new workflow types arrive (e.g. `cancelled`).
/// `inReview` is reserved for future multi-step approvals; today every active
/// request lives in [pendingApproval] until an admin acts on it.
enum WorkflowStatus {
  draft('draft', 'Draft'),
  pendingApproval('pending_approval', 'Pending Approval'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const WorkflowStatus(this.value, this.label);

  final String value;
  final String label;

  bool get isTerminal => this == WorkflowStatus.approved || this == WorkflowStatus.rejected;
  bool get isPending => this == WorkflowStatus.pendingApproval;

  static WorkflowStatus fromRaw(String? raw) {
    final String key = (raw ?? '').trim().toLowerCase();
    for (final WorkflowStatus s in WorkflowStatus.values) {
      if (s.value == key) return s;
    }
    return WorkflowStatus.draft;
  }
}
