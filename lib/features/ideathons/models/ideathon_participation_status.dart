/// Lifecycle of an Idea within a specific Ideathon event.
///
/// Kept separate from [IdeaStatus] — event state lives on participation only.
///
/// Distinguishes:
/// - **Pool** ([inPool]): idea is selected into this Ideathon’s event pool.
///   Not registered; [IdeaStatus] is unchanged.
/// - **Payment pending** ([paymentPending]): faculty has submitted (or is
///   completing) Ideathon participation payment — still not registered.
/// - **Registered** ([readyForExecution]): payment verified; idea is registered
///   for this Ideathon and ready for execution workflows.
enum IdeathonParticipationStatus {
  /// Idea is in the Ideathon event pool only — not registered.
  inPool('inPool'),

  /// Participation payment in progress or awaiting verification.
  paymentPending('paymentPending'),

  /// Payment verified — registered for this Ideathon / ready for execution.
  readyForExecution('readyForExecution');

  const IdeathonParticipationStatus(this.value);
  final String value;

  /// True when the idea is only in the event pool (not registered).
  bool get isPoolOnly => this == IdeathonParticipationStatus.inPool;

  /// True when the idea is registered for this Ideathon after payment.
  bool get isRegistered => this == IdeathonParticipationStatus.readyForExecution;

  static IdeathonParticipationStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (normalized) {
      'readyforexecution' || 'registered' => IdeathonParticipationStatus.readyForExecution,
      'paymentpending' => IdeathonParticipationStatus.paymentPending,
      'inpool' || 'pool' || 'selected' => IdeathonParticipationStatus.inPool,
      _ => IdeathonParticipationStatus.inPool,
    };
  }
}
