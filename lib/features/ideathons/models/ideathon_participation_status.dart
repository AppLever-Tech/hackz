/// Membership of an Idea in a specific Ideathon event.
///
/// Payment is idea-level (pay → coordinator verify) **before** Ideathon create.
/// Participation only records that a paid idea was added to this event.
/// Kept separate from [IdeaStatus] (`draft` | `submitted`).
enum IdeathonParticipationStatus {
  /// Idea is a member of this Ideathon (idea payment was already verified).
  active('active');

  const IdeathonParticipationStatus(this.value);
  final String value;

  static IdeathonParticipationStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    // Historical values collapse to active membership.
    return switch (normalized) {
      'active' ||
      'readyforexecution' ||
      'registered' ||
      'inpool' ||
      'pool' ||
      'selected' ||
      'paymentpending' =>
        IdeathonParticipationStatus.active,
      _ => IdeathonParticipationStatus.active,
    };
  }
}
