/// Catalog of every approval / request flow surfaced through the generic
/// Request Management workspace. Adding a new request type requires:
///
/// 1. New enum entry below with stable `value` (Firestore-safe).
/// 2. Payload class under `lib/features/requests/models/`.
/// 3. Optional handler in [WorkflowRequestService.approve] for side-effects.
/// 4. Optional review-pane renderer.
enum WorkflowRequestType {
  teamChange('team_change', 'Team Change', 'Modify team membership'),
  /// Placeholders for future request types — kept here so request filters and
  /// type pickers stay consistent as new flows come online.
  paymentApproval('payment_approval', 'Payment Approval', 'Approve a payment'),
  extensionRequest('extension_request', 'Extension Request', 'Extend a deadline'),
  ideaModification('idea_modification', 'Idea Modification', 'Modify a submitted idea'),
  exceptionApproval('exception_approval', 'Exception Approval', 'General exception');

  const WorkflowRequestType(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static WorkflowRequestType fromRaw(String? raw) {
    final String key = (raw ?? '').trim().toLowerCase();
    for (final WorkflowRequestType t in WorkflowRequestType.values) {
      if (t.value == key) return t;
    }
    return WorkflowRequestType.teamChange;
  }
}
