/// Lifecycle of an Idea within a specific Ideathon event.
///
/// Kept separate from [IdeaStatus] — event state lives on participation only.
enum IdeathonParticipationStatus {
  /// Idea added to the Ideathon; payment not yet completed.
  paymentPending('paymentPending'),

  /// Payment verified — idea is ready for Ideathon execution (evaluation, etc.).
  readyForExecution('readyForExecution');

  const IdeathonParticipationStatus(this.value);
  final String value;

  static IdeathonParticipationStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (normalized) {
      'readyforexecution' => IdeathonParticipationStatus.readyForExecution,
      _ => IdeathonParticipationStatus.paymentPending,
    };
  }
}
